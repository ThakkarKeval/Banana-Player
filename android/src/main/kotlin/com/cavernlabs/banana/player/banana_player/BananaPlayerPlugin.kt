package com.cavernlabs.banana.player.banana_player

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.view.TextureRegistry
import java.util.concurrent.ConcurrentHashMap

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
 * BananaPlayerPlugin
 *
 * Threading Model:
 * Flutter Platform Channel calls are typically dispatched on the main UI looper. To protect against
 * potential multi-threaded access and ensure race-free disposal, active players are kept in a
 * [ConcurrentHashMap]. Player map mutations are isolated and thread-safe.
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

    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: BananaPlayerFlutterApi? = null
    private val players = ConcurrentHashMap<Long, BananaPlayerInstance>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binding = flutterPluginBinding
        flutterApi = BananaPlayerFlutterApi(flutterPluginBinding.binaryMessenger)
        BananaPlayerHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BananaPlayerHostApi.setUp(binding.binaryMessenger, null)
        val activePlayers = ArrayList(players.values)
        players.clear()
        activePlayers.forEach { it.dispose() }
        this.binding = null
        this.flutterApi = null
    }

    private fun requirePlayer(textureId: Long): BananaPlayerInstance {
        return players[textureId] ?: throw FlutterError(
            code = "player_not_found",
            message = "No active player found with textureId $textureId",
            details = null
        )
    }

    override fun create(config: PlayerConfig): Long {
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
            throw FlutterError(
                code = "invalid_argument",
                message = "Media URL cannot be blank",
                details = null
            )
        }

        val textureEntry = currentBinding.textureRegistry.createSurfaceTexture()
        val textureId = textureEntry.id()

        val player = playerFactory.create(
            context = currentBinding.applicationContext,
            textureEntry = textureEntry,
            flutterApi = currentFlutterApi,
            config = config,
            flutterAssets = currentBinding.flutterAssets
        )
        players[textureId] = player
        return textureId
    }

    override fun play(textureId: Long) {
        requirePlayer(textureId).play()
    }

    override fun pause(textureId: Long) {
        requirePlayer(textureId).pause()
    }

    override fun setSource(textureId: Long, url: String) {
        if (url.isBlank()) {
            throw FlutterError(
                code = "invalid_argument",
                message = "Media URL cannot be blank",
                details = null
            )
        }
        requirePlayer(textureId).setSource(url)
    }

    override fun seekTo(textureId: Long, positionMs: Long) {
        requirePlayer(textureId).seekTo(positionMs)
    }

    override fun setVolume(textureId: Long, volume: Double) {
        if (volume.isNaN()) {
            throw FlutterError(
                code = "invalid_argument",
                message = "Volume cannot be NaN",
                details = null
            )
        }
        requirePlayer(textureId).setVolume(volume.toFloat())
    }

    override fun getDuration(textureId: Long): Long {
        return requirePlayer(textureId).getDuration()
    }

    override fun getPosition(textureId: Long): Long {
        return requirePlayer(textureId).getPosition()
    }

    override fun getVideoQualities(textureId: Long): List<VideoQuality> {
        return requirePlayer(textureId).getVideoQualities()
    }

    override fun setVideoQuality(textureId: Long, qualityId: String) {
        requirePlayer(textureId).setVideoQuality(qualityId)
    }

    override fun setPlaybackSpeed(textureId: Long, speed: Double) {
        if (speed.isNaN() || speed <= 0.0) {
            throw FlutterError(
                code = "invalid_argument",
                message = "Playback speed must be a positive number greater than 0",
                details = null
            )
        }
        requirePlayer(textureId).setPlaybackSpeed(speed.toFloat())
    }

    override fun getSubtitleTracks(textureId: Long): List<SubtitleTrack> {
        return requirePlayer(textureId).getSubtitleTracks()
    }

    override fun setSubtitleTrack(textureId: Long, trackId: String) {
        requirePlayer(textureId).setSubtitleTrack(trackId)
    }

    override fun dispose(textureId: Long) {
        val player = players.remove(textureId) ?: throw FlutterError(
            code = "player_not_found",
            message = "No active player found with textureId $textureId to dispose",
            details = null
        )
        player.dispose()
    }
}
