package com.cavernlabs.banana.player.banana_player

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.view.TextureRegistry
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

internal class BananaPlayerPluginTest {

    private class FakePlayer(
        override val textureId: Long
    ) : BananaPlayerInstance {
        var isPlaying = false
        var isPaused = false
        var currentSource: String? = null
        var seekPositionMs: Long? = null
        var volume: Float? = null
        var playbackSpeed: Float? = null
        var isDisposed = false
        var selectedVideoQuality: String? = null
        var selectedSubtitleTrack: String? = null

        override fun play() {
            isPlaying = true
            isPaused = false
        }

        override fun pause() {
            isPaused = true
            isPlaying = false
        }

        override fun setSource(url: String) {
            currentSource = url
        }

        override fun seekTo(positionMs: Long) {
            seekPositionMs = positionMs
        }

        override fun setVolume(volume: Float) {
            this.volume = volume
        }

        override fun getDuration(): Long = 60_000L

        override fun getPosition(): Long = 12_345L

        override fun getVideoQualities(): List<VideoQuality> = listOf(
            VideoQuality(id = "auto", width = 0L, height = 0L, bitrate = 0L, isSelected = true, label = "Auto", frameRate = null),
            VideoQuality(id = "0_0", width = 1920L, height = 1080L, bitrate = 5_000_000L, isSelected = false, label = "1080p", frameRate = 30.0)
        )

        override fun setVideoQuality(qualityId: String) {
            selectedVideoQuality = qualityId
        }

        override fun setPlaybackSpeed(speed: Float) {
            playbackSpeed = speed
        }

        override fun getSubtitleTracks(): List<SubtitleTrack> = listOf(
            SubtitleTrack(id = "off", label = "Off", isSelected = true, language = null),
            SubtitleTrack(id = "0_0", label = "English", isSelected = false, language = "en")
        )

        override fun setSubtitleTrack(trackId: String) {
            selectedSubtitleTrack = trackId
        }

        override fun dispose() {
            isDisposed = true
        }
    }

    private fun setupPluginWithBinding(): Pair<BananaPlayerPlugin, FakePlayer> {
        val fakePlayer = FakePlayer(101L)
        val plugin = BananaPlayerPlugin(
            playerFactory = { _, _, _, _, _ -> fakePlayer }
        )

        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        val messenger = mock(BinaryMessenger::class.java)
        val registry = mock(TextureRegistry::class.java)
        val textureEntry = mock(TextureRegistry.SurfaceTextureEntry::class.java)
        val context = mock(Context::class.java)

        `when`(binding.binaryMessenger).thenReturn(messenger)
        `when`(binding.textureRegistry).thenReturn(registry)
        `when`(binding.applicationContext).thenReturn(context)
        `when`(registry.createSurfaceTexture()).thenReturn(textureEntry)
        `when`(textureEntry.id()).thenReturn(101L)

        plugin.onAttachedToEngine(binding)
        return Pair(plugin, fakePlayer)
    }

    @Test
    fun pluginCanBeInstantiated() {
        val plugin = BananaPlayerPlugin()
        assertNotNull(plugin)
    }

    @Test
    fun createWithoutAttachmentThrowsPluginNotAttachedError() {
        val plugin = BananaPlayerPlugin()
        val error = assertFailsWith<FlutterError> {
            plugin.create(PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0))
        }
        assertEquals("plugin_not_attached", error.code)
    }

    @Test
    fun createWithBlankUrlThrowsInvalidArgumentError() {
        val (plugin, _) = setupPluginWithBinding()
        val error = assertFailsWith<FlutterError> {
            plugin.create(PlayerConfig(url = "   ", autoPlay = false, volume = 1.0))
        }
        assertEquals("invalid_argument", error.code)
    }

    @Test
    fun createRegistersAndReturnsTextureId() {
        val (plugin, _) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = true, volume = 0.8)
        )
        assertEquals(101L, textureId)
    }

    @Test
    fun callingMethodsWithUnknownTextureIdThrowsPlayerNotFoundError() {
        val (plugin, _) = setupPluginWithBinding()
        val unknownId = 999L

        val playError = assertFailsWith<FlutterError> { plugin.play(unknownId) }
        assertEquals("player_not_found", playError.code)

        val pauseError = assertFailsWith<FlutterError> { plugin.pause(unknownId) }
        assertEquals("player_not_found", pauseError.code)

        val seekError = assertFailsWith<FlutterError> { plugin.seekTo(unknownId, 5000L) }
        assertEquals("player_not_found", seekError.code)

        val volumeError = assertFailsWith<FlutterError> { plugin.setVolume(unknownId, 0.5) }
        assertEquals("player_not_found", volumeError.code)

        val speedError = assertFailsWith<FlutterError> { plugin.setPlaybackSpeed(unknownId, 1.5) }
        assertEquals("player_not_found", speedError.code)

        val durationError = assertFailsWith<FlutterError> { plugin.getDuration(unknownId) }
        assertEquals("player_not_found", durationError.code)

        val positionError = assertFailsWith<FlutterError> { plugin.getPosition(unknownId) }
        assertEquals("player_not_found", positionError.code)

        val qualitiesError = assertFailsWith<FlutterError> { plugin.getVideoQualities(unknownId) }
        assertEquals("player_not_found", qualitiesError.code)

        val subtitlesError = assertFailsWith<FlutterError> { plugin.getSubtitleTracks(unknownId) }
        assertEquals("player_not_found", subtitlesError.code)

        val disposeError = assertFailsWith<FlutterError> { plugin.dispose(unknownId) }
        assertEquals("player_not_found", disposeError.code)
    }

    @Test
    fun playbackControlsForwardToPlayerInstance() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        plugin.play(textureId)
        assertTrue(fakePlayer.isPlaying)

        plugin.pause(textureId)
        assertTrue(fakePlayer.isPaused)

        plugin.seekTo(textureId, 45_000L)
        assertEquals(45_000L, fakePlayer.seekPositionMs)

        plugin.setVolume(textureId, 0.5)
        assertEquals(0.5f, fakePlayer.volume)

        plugin.setPlaybackSpeed(textureId, 1.25)
        assertEquals(1.25f, fakePlayer.playbackSpeed)

        assertEquals(60_000L, plugin.getDuration(textureId))
        assertEquals(12_345L, plugin.getPosition(textureId))
    }

    @Test
    fun setVideoQualityRejectsUnknownQualityIds() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        val error = assertFailsWith<FlutterError> {
            plugin.setVideoQuality(textureId, "missing-quality")
        }

        assertEquals("invalid_argument", error.code)
        assertEquals(null, fakePlayer.selectedVideoQuality)
    }

    @Test
    fun setSourceValidatesUrlAndForwardsToPlayer() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        val blankError = assertFailsWith<FlutterError> {
            plugin.setSource(textureId, "  ")
        }
        assertEquals("invalid_argument", blankError.code)

        plugin.setSource(textureId, "https://example.com/new_video.mp4")
        assertEquals("https://example.com/new_video.mp4", fakePlayer.currentSource)
    }

    @Test
    fun trackSelectionForwardsToPlayerInstance() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        val qualities = plugin.getVideoQualities(textureId)
        assertEquals(2, qualities.size)
        assertEquals("auto", qualities[0].id)

        plugin.setVideoQuality(textureId, "0_0")
        assertEquals("0_0", fakePlayer.selectedVideoQuality)

        val subtitles = plugin.getSubtitleTracks(textureId)
        assertEquals(2, subtitles.size)
        assertEquals("off", subtitles[0].id)

        plugin.setSubtitleTrack(textureId, "0_0")
        assertEquals("0_0", fakePlayer.selectedSubtitleTrack)
    }

    @Test
    fun disposeDisposesPlayerAndRemovesFromMap() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        plugin.dispose(textureId)
        assertTrue(fakePlayer.isDisposed)

        val error = assertFailsWith<FlutterError> {
            plugin.play(textureId)
        }
        assertEquals("player_not_found", error.code)
    }

    @Test
    fun createReleasesTextureWhenPlayerFactoryFails() {
        val plugin = BananaPlayerPlugin(
            playerFactory = { _, _, _, _, _ -> error("factory failure") }
        )
        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        val messenger = mock(BinaryMessenger::class.java)
        val registry = mock(TextureRegistry::class.java)
        val textureEntry = mock(TextureRegistry.SurfaceTextureEntry::class.java)
        `when`(binding.binaryMessenger).thenReturn(messenger)
        `when`(binding.textureRegistry).thenReturn(registry)
        `when`(registry.createSurfaceTexture()).thenReturn(textureEntry)
        `when`(textureEntry.id()).thenReturn(101L)
        plugin.onAttachedToEngine(binding)

        assertFailsWith<IllegalStateException> {
            plugin.create(PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0))
        }
        org.mockito.Mockito.verify(textureEntry).release()
    }

    @Test
    fun createRejectsNonFiniteOrOutOfRangeInitialVolume() {
        val (plugin, _) = setupPluginWithBinding()
        val error = assertFailsWith<FlutterError> {
            plugin.create(PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = Double.POSITIVE_INFINITY))
        }
        assertEquals("invalid_argument", error.code)

        val outOfRangeError = assertFailsWith<FlutterError> {
            plugin.create(PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.1))
        }
        assertEquals("invalid_argument", outOfRangeError.code)
    }

    @Test
    fun setVolumeAndPlaybackSpeedRejectNonFiniteValues() {
        val (plugin, _) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        assertEquals("invalid_argument", assertFailsWith<FlutterError> {
            plugin.setVolume(textureId, Double.POSITIVE_INFINITY)
        }.code)
        assertEquals("invalid_argument", assertFailsWith<FlutterError> {
            plugin.setPlaybackSpeed(textureId, Double.POSITIVE_INFINITY)
        }.code)
    }

    @Test
    fun onDetachedFromEngineDisposesAllActivePlayers() {
        val (plugin, fakePlayer) = setupPluginWithBinding()
        val textureId = plugin.create(
            PlayerConfig(url = "https://example.com/video.mp4", autoPlay = false, volume = 1.0)
        )

        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        val messenger = mock(BinaryMessenger::class.java)
        `when`(binding.binaryMessenger).thenReturn(messenger)

        plugin.onDetachedFromEngine(binding)
        assertTrue(fakePlayer.isDisposed)

        val error = assertFailsWith<FlutterError> {
            plugin.play(textureId)
        }
        assertEquals("player_not_found", error.code)
    }
}
