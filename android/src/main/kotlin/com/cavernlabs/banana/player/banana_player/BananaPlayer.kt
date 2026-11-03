package com.cavernlabs.banana.player.banana_player

import android.content.Context
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class BananaPlayer(
    context: Context,
    private val textureEntry: TextureRegistry.SurfaceTextureEntry,
    private val flutterApi: BananaPlayerFlutterApi,
    config: PlayerConfig
) {
    val textureId: Long = textureEntry.id()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val surface: Surface = Surface(textureEntry.surfaceTexture())
    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build()

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            val state = when (playbackState) {
                Player.STATE_IDLE -> PlaybackState.IDLE
                Player.STATE_BUFFERING -> PlaybackState.BUFFERING
                Player.STATE_READY -> PlaybackState.READY
                Player.STATE_ENDED -> PlaybackState.ENDED
                else -> PlaybackState.IDLE
            }
            scope.launch {
                try {
                    flutterApi.onPlaybackStateChanged(textureId, state)
                } catch (_: Exception) {
                }
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            scope.launch {
                try {
                    flutterApi.onError(textureId, error.errorCodeName, error.message ?: "Playback error")
                } catch (_: Exception) {
                }
            }
        }
    }

    init {
        exoPlayer.setVideoSurface(surface)
        exoPlayer.volume = config.volume.toFloat()
        exoPlayer.addListener(playerListener)

        val mediaItem = MediaItem.fromUri(config.url)
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = config.autoPlay
    }

    fun play() {
        exoPlayer.play()
    }

    fun pause() {
        exoPlayer.pause()
    }

    fun seekTo(positionMs: Long) {
        exoPlayer.seekTo(positionMs)
    }

    fun setVolume(volume: Float) {
        exoPlayer.volume = volume
    }

    fun dispose() {
        scope.cancel()
        exoPlayer.removeListener(playerListener)
        exoPlayer.release()
        surface.release()
        textureEntry.release()
    }
}
