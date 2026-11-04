package com.cavernlabs.banana.player.banana_player

import android.content.Context
import android.view.Surface
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Handles individual video playback sessions using Media3 ExoPlayer and renders to a Flutter [SurfaceTexture].
 */
class BananaPlayer(
    context: Context,
    private val textureEntry: TextureRegistry.SurfaceTextureEntry,
    private val flutterApi: BananaPlayerFlutterApi,
    config: PlayerConfig
) {
    val textureId: Long = textureEntry.id()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val surface: Surface = Surface(textureEntry.surfaceTexture())
    private var progressJob: Job? = null

    private val httpDataSourceFactory = DefaultHttpDataSource.Factory()
        .setUserAgent("Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 BananaPlayer/1.0")
        .setAllowCrossProtocolRedirects(true)
        .setConnectTimeoutMs(15_000)
        .setReadTimeoutMs(15_000)

    private val dataSourceFactory = DefaultDataSource.Factory(context, httpDataSourceFactory)
    private val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory)

    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(C.USAGE_MEDIA)
        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
        .build()

    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context)
        .setMediaSourceFactory(mediaSourceFactory)
        .setAudioAttributes(audioAttributes, /* handleAudioFocus = */ true)
        .build()

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            val state = when (playbackState) {
                Player.STATE_IDLE -> {
                    stopProgressUpdates()
                    PlaybackState.IDLE
                }
                Player.STATE_BUFFERING -> PlaybackState.BUFFERING
                Player.STATE_READY -> {
                    if (exoPlayer.isPlaying) {
                        startProgressUpdates()
                    }
                    PlaybackState.READY
                }
                Player.STATE_ENDED -> {
                    stopProgressUpdates()
                    PlaybackState.ENDED
                }
                else -> PlaybackState.IDLE
            }
            notifyPlaybackState(state)
            notifyPosition()
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (isPlaying) {
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
            if (exoPlayer.playbackState == Player.STATE_READY) {
                notifyPlaybackState(if (isPlaying) PlaybackState.READY else PlaybackState.PAUSED)
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

    private fun notifyPlaybackState(state: PlaybackState) {
        scope.launch {
            try {
                flutterApi.onPlaybackStateChanged(textureId, state)
            } catch (_: Exception) {
            }
        }
    }

    private fun startProgressUpdates() {
        if (progressJob?.isActive == true) return
        progressJob = scope.launch {
            while (isActive) {
                notifyPosition()
                delay(200)
            }
        }
    }

    private fun stopProgressUpdates() {
        progressJob?.cancel()
        progressJob = null
        notifyPosition()
    }

    fun getDuration(): Long {
        val dur = exoPlayer.duration
        return if (dur == C.TIME_UNSET || dur < 0) 0L else dur
    }

    fun getPosition(): Long {
        return exoPlayer.currentPosition.coerceAtLeast(0L)
    }

    fun getBufferedPosition(): Long {
        return exoPlayer.bufferedPosition.coerceAtLeast(0L)
    }

    private fun notifyPosition() {
        val curPos = getPosition()
        val dur = getDuration()
        val buffered = getBufferedPosition()
        scope.launch {
            try {
                flutterApi.onPositionChanged(textureId, curPos, dur, buffered)
            } catch (_: Exception) {
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
        notifyPosition()
    }

    fun play() {
        if (exoPlayer.playbackState == Player.STATE_ENDED) {
            exoPlayer.seekTo(0)
        }
        exoPlayer.play()
        startProgressUpdates()
    }

    fun pause() {
        exoPlayer.pause()
        stopProgressUpdates()
    }

    fun setSource(url: String) {
        stopProgressUpdates()
        val mediaItem = MediaItem.fromUri(url)
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.play()
    }

    fun seekTo(positionMs: Long) {
        exoPlayer.seekTo(positionMs)
        notifyPosition()
    }

    fun setVolume(volume: Float) {
        exoPlayer.volume = volume.coerceIn(0f, 1f)
    }

    fun dispose() {
        stopProgressUpdates()
        scope.cancel()
        exoPlayer.removeListener(playerListener)
        exoPlayer.release()
        surface.release()
        textureEntry.release()
    }
}
