package com.cavernlabs.banana.player.banana_player

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.view.TextureRegistry
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.locks.ReentrantLock

/**
 * Factory for creating [BananaPlayerInstance]s, allowing dependency injection and testability.
 */
fun interface BananaPlayerFactory {
    fun create(
        context: Context,
        textureEntry: TextureRegistry.SurfaceTextureEntry,
        flutterApi: BananaPlayerFlutterApi,
        config: PlayerConfig,
        flutterAssets: FlutterPlugin.FlutterAssets?
    ): BananaPlayerInstance
}

/**
 * Owns player instances and serializes channel operations with engine teardown.
 *
 * Pigeon host handlers run on Android's platform thread, where ExoPlayer instances are created.
 * The lock serializes those calls with engine teardown. Direct host API calls from worker threads
 * are unsupported because the lock does not move ExoPlayer work to its application looper.
 */
class BananaPlayerPlugin(
    private var playerFactory: BananaPlayerFactory = BananaPlayerFactory { context, textureEntry, flutterApi, config, flutterAssets ->
        BananaPlayer(
            context = context,
            textureEntry = textureEntry,
            flutterApi = flutterApi,
            config = config,
            flutterAssets = flutterAssets
        )
    }
) : FlutterPlugin, BananaPlayerHostApi {

    private val lifecycleLock = ReentrantLock()
    private fun <T> withLifecycleLock(block: () -> T): T {
        lifecycleLock.lock()
        return try {
            block()
        } finally {
            lifecycleLock.unlock()
        }
    }

    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: BananaPlayerFlutterApi? = null
    private val players = ConcurrentHashMap<Long, BananaPlayerInstance>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        withLifecycleLock {
            binding = flutterPluginBinding
            flutterApi = BananaPlayerFlutterApi(flutterPluginBinding.binaryMessenger)
            BananaPlayerHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        withLifecycleLock {
            BananaPlayerHostApi.setUp(binding.binaryMessenger, null)
            val activePlayers = players.values.toList()
            players.clear()
            this.binding = null
            this.flutterApi = null
            activePlayers.forEach { player ->
                runCatching { player.dispose() }
            }
        }
    }

    private fun requirePlayer(textureId: Long): BananaPlayerInstance {
        return players[textureId] ?: throw FlutterError(
            code = "player_not_found",
            message = "No active player found with textureId $textureId",
            details = null
        )
    }

    private fun <T> withPlayer(textureId: Long, operation: (BananaPlayerInstance) -> T): T =
        withLifecycleLock {
            operation(requirePlayer(textureId))
        }

    override fun create(config: PlayerConfig): Long = withLifecycleLock {
        val currentBinding = binding ?: throw FlutterError(
            code = "plugin_not_attached",
            message = "Plugin not attached to Flutter engine",
            details = null
        )
        val currentFlutterApi = flutterApi ?: throw FlutterError(
            code = "flutter_api_null",
            message = "FlutterApi not initialized",
            details = null
        )

        if (config.url.isBlank()) {
            throw FlutterError("invalid_argument", "Media URL cannot be blank", null)
        }
        if (!java.lang.Double.isFinite(config.volume) || config.volume < 0.0 || config.volume > 1.0) {
            throw FlutterError("invalid_argument", "Volume must be finite and between 0 and 1", null)
        }

        val textureEntry = currentBinding.textureRegistry.createSurfaceTexture()
        try {
            val player = playerFactory.create(
                context = currentBinding.applicationContext,
                textureEntry = textureEntry,
                flutterApi = currentFlutterApi,
                config = config,
                flutterAssets = currentBinding.flutterAssets
            )
            players[textureEntry.id()] = player
            textureEntry.id()
        } catch (error: Throwable) {
            runCatching { textureEntry.release() }
            throw error
        }
    }

    override fun play(textureId: Long) = withPlayer(textureId) { it.play() }

    override fun pause(textureId: Long) = withPlayer(textureId) { it.pause() }

    override fun setSource(textureId: Long, url: String) {
        if (url.isBlank()) {
            throw FlutterError("invalid_argument", "Media URL cannot be blank", null)
        }
        withPlayer(textureId) { it.setSource(url) }
    }

    override fun seekTo(textureId: Long, positionMs: Long) =
        withPlayer(textureId) { it.seekTo(positionMs) }

    override fun setVolume(textureId: Long, volume: Double) {
        if (!java.lang.Double.isFinite(volume)) {
            throw FlutterError("invalid_argument", "Volume must be finite", null)
        }
        withPlayer(textureId) { it.setVolume(volume.toFloat()) }
    }

    override fun getDuration(textureId: Long): Long = withPlayer(textureId) { it.getDuration() }

    override fun getPosition(textureId: Long): Long = withPlayer(textureId) { it.getPosition() }

    override fun getVideoQualities(textureId: Long): List<VideoQuality> =
        withPlayer(textureId) { it.getVideoQualities() }

    override fun setVideoQuality(textureId: Long, qualityId: String) =
        withPlayer(textureId) { player ->
            if (qualityId != "auto" && player.getVideoQualities().none { it.id == qualityId }) {
                throw FlutterError(
                    "invalid_argument",
                    "Unknown video quality ID: $qualityId",
                    null
                )
            }
            player.setVideoQuality(qualityId)
        }

    override fun setPlaybackSpeed(textureId: Long, speed: Double) {
        if (!java.lang.Double.isFinite(speed) || speed <= 0.0) {
            throw FlutterError(
                "invalid_argument",
                "Playback speed must be finite and greater than 0",
                null
            )
        }
        withPlayer(textureId) { it.setPlaybackSpeed(speed.toFloat()) }
    }

    override fun getSubtitleTracks(textureId: Long): List<SubtitleTrack> =
        withPlayer(textureId) { it.getSubtitleTracks() }

    override fun setSubtitleTrack(textureId: Long, trackId: String) =
        withPlayer(textureId) { it.setSubtitleTrack(trackId) }

    override fun dispose(textureId: Long) {
        withLifecycleLock {
            val player = players.remove(textureId) ?: throw FlutterError(
                code = "player_not_found",
                message = "No active player found with textureId $textureId to dispose",
                details = null
            )
            player.dispose()
        }
    }
}
