package com.cavernlabs.banana.player.banana_player

import android.content.Context
import android.view.Surface
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
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

    private val loadControl = DefaultLoadControl.Builder()
        .setBackBuffer(/* backBufferDurationMs = */ 30_000, /* retainBackBufferFromKeyframe = */ true)
        .setBufferDurationsMs(
            /* minBufferMs = */ 50_000,
            /* maxBufferMs = */ 50_000,
            /* bufferForPlaybackMs = */ 1_000,
            /* bufferForPlaybackAfterRebufferMs = */ 1_500
        )
        .build()

    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context)
        .setMediaSourceFactory(mediaSourceFactory)
        .setLoadControl(loadControl)
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

        override fun onTracksChanged(tracks: Tracks) {
            notifyVideoQualities()
        }

        override fun onRenderedFirstFrame() {
            notifyVideoQualities()
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
        exoPlayer.setSeekParameters(SeekParameters.CLOSEST_SYNC)
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
        exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .build()
        val mediaItem = MediaItem.fromUri(url)
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.play()
    }

    fun getVideoQualities(): List<VideoQuality> {
        val tracks = exoPlayer.currentTracks
        val result = mutableListOf<VideoQuality>()

        val hasVideoOverride = exoPlayer.trackSelectionParameters.overrides.values.any {
            it.mediaTrackGroup.type == C.TRACK_TYPE_VIDEO
        }
        val isAuto = !hasVideoOverride

        var groupIndex = 0
        for (group in tracks.groups) {
            if (group.type == C.TRACK_TYPE_VIDEO) {
                val mediaTrackGroup = group.mediaTrackGroup
                for (trackIndex in 0 until mediaTrackGroup.length) {
                    if (group.isTrackSupported(trackIndex)) {
                        val format = mediaTrackGroup.getFormat(trackIndex)
                        val width = format.width.toLong().coerceAtLeast(0L)
                        val height = format.height.toLong().coerceAtLeast(0L)
                        val bitrate = format.bitrate.toLong().coerceAtLeast(0L)
                        val frameRate = if (format.frameRate > 0) format.frameRate.toDouble() else null
                        val id = "${groupIndex}_${trackIndex}"
                        val label = if (height > 0) {
                            "${height}p"
                        } else if (width > 0) {
                            "${width}x${height}"
                        } else {
                            format.label ?: "Quality $trackIndex"
                        }

                        val isSelected = if (hasVideoOverride) {
                            group.isTrackSelected(trackIndex)
                        } else {
                            false
                        }

                        result.add(
                            VideoQuality(
                                id = id,
                                width = width,
                                height = height,
                                bitrate = bitrate,
                                isSelected = isSelected,
                                label = label,
                                frameRate = frameRate
                            )
                        )
                    }
                }
            }
            groupIndex++
        }

        if (result.isNotEmpty()) {
            val autoOption = VideoQuality(
                id = "auto",
                width = 0L,
                height = 0L,
                bitrate = 0L,
                isSelected = isAuto,
                label = "Auto",
                frameRate = null
            )
            result.add(0, autoOption)
        }

        return result
    }

    fun setVideoQuality(qualityId: String) {
        if (qualityId.equals("auto", ignoreCase = true)) {
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .build()
        } else {
            val tracks = exoPlayer.currentTracks
            var targetOverride: TrackSelectionOverride? = null
            var groupIndex = 0
            for (group in tracks.groups) {
                if (group.type == C.TRACK_TYPE_VIDEO) {
                    val mediaTrackGroup = group.mediaTrackGroup
                    for (trackIndex in 0 until mediaTrackGroup.length) {
                        val id = "${groupIndex}_${trackIndex}"
                        val format = mediaTrackGroup.getFormat(trackIndex)
                        val altId = if (format.id != null) format.id else "${format.height}p"
                        if (qualityId == id || qualityId == altId || qualityId == "${format.height}p" || qualityId == "${format.width}x${format.height}") {
                            targetOverride = TrackSelectionOverride(mediaTrackGroup, trackIndex)
                            break
                        }
                    }
                    if (targetOverride != null) break
                }
                groupIndex++
            }

            if (targetOverride != null) {
                exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                    .buildUpon()
                    .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                    .setOverrideForType(targetOverride)
                    .build()
            }
        }
        notifyVideoQualities()
    }

    private fun notifyVideoQualities() {
        val qualities = getVideoQualities()
        scope.launch {
            try {
                flutterApi.onVideoQualitiesChanged(textureId, qualities)
            } catch (_: Exception) {
            }
        }
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
