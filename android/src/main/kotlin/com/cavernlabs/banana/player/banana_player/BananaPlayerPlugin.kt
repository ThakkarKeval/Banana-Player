package com.cavernlabs.banana.player.banana_player

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** BananaPlayerPlugin */
class BananaPlayerPlugin : FlutterPlugin, BananaPlayerHostApi {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: BananaPlayerFlutterApi? = null
    private val players = mutableMapOf<Long, BananaPlayer>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binding = flutterPluginBinding
        flutterApi = BananaPlayerFlutterApi(flutterPluginBinding.binaryMessenger)
        BananaPlayerHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BananaPlayerHostApi.setUp(binding.binaryMessenger, null)
        players.values.forEach { it.dispose() }
        players.clear()
        this.binding = null
        flutterApi = null
    }

    override fun create(config: PlayerConfig): Long {
        val currentBinding = binding ?: throw IllegalStateException("Plugin not attached to engine")
        val currentFlutterApi = flutterApi ?: throw IllegalStateException("FlutterApi not initialized")

        val textureEntry = currentBinding.textureRegistry.createSurfaceTexture()
        val textureId = textureEntry.id()

        val player = BananaPlayer(
            context = currentBinding.applicationContext,
            textureEntry = textureEntry,
            flutterApi = currentFlutterApi,
            config = config
        )
        players[textureId] = player
        return textureId
    }

    override fun play(textureId: Long) {
        players[textureId]?.play()
    }

    override fun pause(textureId: Long) {
        players[textureId]?.pause()
    }

    override fun setSource(textureId: Long, url: String) {
        players[textureId]?.setSource(url)
    }

    override fun seekTo(textureId: Long, positionMs: Long) {
        players[textureId]?.seekTo(positionMs)
    }

    override fun setVolume(textureId: Long, volume: Double) {
        players[textureId]?.setVolume(volume.toFloat())
    }

    override fun getDuration(textureId: Long): Long {
        return players[textureId]?.getDuration() ?: 0L
    }

    override fun getPosition(textureId: Long): Long {
        return players[textureId]?.getPosition() ?: 0L
    }

    override fun dispose(textureId: Long) {
        players.remove(textureId)?.dispose()
    }
}
