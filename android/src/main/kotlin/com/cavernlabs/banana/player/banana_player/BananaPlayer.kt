package com.cavernlabs.banana.player.banana_player

import android.content.Context
import android.net.Uri
import android.view.Surface
import java.io.File
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.text.CueGroup
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
    config: PlayerConfig,
    private val flutterAssets: io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets? = null
) {
    val textureId: Long = textureEntry.id()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val surface: Surface = Surface(textureEntry.surfaceTexture())
    private var progressJob: Job? = null
    private var isDisposed = false

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
            stopProgressUpdates()
            notifyPlaybackState(PlaybackState.IDLE)
            scope.launch {
                try {
                    flutterApi.onError(textureId, error.errorCodeName, error.message ?: "Playback error")
                } catch (_: Exception) {
                }
            }
        }

        override fun onCues(cueGroup: CueGroup) {
            val text = if (cueGroup.cues.isNotEmpty()) {
                val sb = StringBuilder()
                for (cue in cueGroup.cues) {
                    val cueText = cue.text?.toString()?.trim()
                    if (!cueText.isNullOrEmpty()) {
                        if (sb.isNotEmpty()) sb.append("\n")
                        sb.append(cueText)
                    }
                }
                if (sb.isNotEmpty()) sb.toString() else null
            } else {
                null
            }
            notifySubtitleText(text)
        }

        override fun onTracksChanged(tracks: Tracks) {
            notifyVideoQualities()
            notifySubtitleTracks()
        }

        override fun onRenderedFirstFrame() {
            notifyVideoQualities()
            notifySubtitleTracks()
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

    private fun resolveUri(url: String): Uri {
        return when {
            url.startsWith("asset://") -> {
                var assetPath = url.removePrefix("asset://")
                while (assetPath.startsWith("/")) {
                    assetPath = assetPath.substring(1)
                }
                val lookupKey = flutterAssets?.getAssetFilePathByName(assetPath) ?: assetPath
                Uri.parse("asset:///$lookupKey")
            }
            url.startsWith("/") -> {
                Uri.fromFile(java.io.File(url))
            }
            else -> {
                Uri.parse(url)
            }
        }
    }

    init {
        exoPlayer.setSeekParameters(SeekParameters.CLOSEST_SYNC)
        exoPlayer.setVideoSurface(surface)
        exoPlayer.volume = config.volume.toFloat()
        exoPlayer.addListener(playerListener)

        val mediaItem = MediaItem.fromUri(resolveUri(config.url))
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
        notifySubtitleText(null)
        exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
            .build()
        val mediaItem = MediaItem.fromUri(resolveUri(url))
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

    private fun notifySubtitleText(text: String?) {
        scope.launch {
            try {
                flutterApi.onSubtitleTextChanged(textureId, text)
            } catch (_: Exception) {
            }
        }
    }

    private fun notifySubtitleTracks() {
        val tracks = getSubtitleTracks()
        scope.launch {
            try {
                flutterApi.onSubtitleTracksChanged(textureId, tracks)
            } catch (_: Exception) {
            }
        }
    }

    fun getSubtitleTracks(): List<SubtitleTrack> {
        val tracks = exoPlayer.currentTracks
        val result = mutableListOf<SubtitleTrack>()

        val isTextDisabled = exoPlayer.trackSelectionParameters.disabledTrackTypes.contains(C.TRACK_TYPE_TEXT)

        var groupIndex = 0
        var hasSelectedTrack = false

        for (group in tracks.groups) {
            if (group.type == C.TRACK_TYPE_TEXT) {
                val mediaTrackGroup = group.mediaTrackGroup
                for (trackIndex in 0 until mediaTrackGroup.length) {
                    if (group.isTrackSupported(trackIndex)) {
                        val format = mediaTrackGroup.getFormat(trackIndex)
                        val id = "${groupIndex}_${trackIndex}"
                        val lang = format.language
                        val label = format.label ?: lang?.uppercase() ?: "Subtitle ${result.size + 1}"
                        val isSelected = !isTextDisabled && group.isTrackSelected(trackIndex)
                        if (isSelected) {
                            hasSelectedTrack = true
                        }

                        result.add(
                            SubtitleTrack(
                                id = id,
                                label = label,
                                isSelected = isSelected,
                                language = lang
                            )
                        )
                    }
                }
            }
            groupIndex++
        }

        if (result.isNotEmpty()) {
            val offOption = SubtitleTrack(
                id = "off",
                label = "Off",
                isSelected = isTextDisabled || !hasSelectedTrack,
                language = null
            )
            result.add(0, offOption)
        }

        return result
    }

    fun setSubtitleTrack(trackId: String) {
        if (trackId.equals("off", ignoreCase = true) || trackId.isEmpty()) {
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
            notifySubtitleText(null)
        } else {
            val tracks = exoPlayer.currentTracks
            var targetOverride: TrackSelectionOverride? = null
            var groupIndex = 0
            for (group in tracks.groups) {
                if (group.type == C.TRACK_TYPE_TEXT) {
                    val mediaTrackGroup = group.mediaTrackGroup
                    for (trackIndex in 0 until mediaTrackGroup.length) {
                        val id = "${groupIndex}_${trackIndex}"
                        val format = mediaTrackGroup.getFormat(trackIndex)
                        val lang = format.language
                        if (trackId == id || trackId == format.id || (lang != null && trackId.equals(lang, ignoreCase = true))) {
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
                    .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                    .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                    .setOverrideForType(targetOverride)
                    .build()
            }
        }
        notifySubtitleTracks()
    }

    fun seekTo(positionMs: Long) {
        val targetMs = if (positionMs < 0L) 0L else positionMs
        exoPlayer.seekTo(targetMs)
        notifyPosition()
    }

    fun setVolume(volume: Float) {
        exoPlayer.volume = volume.coerceIn(0f, 1f)
    }

    fun setPlaybackSpeed(speed: Float) {
        val clampedSpeed = speed.coerceIn(0.25f, 4.0f)
        exoPlayer.setPlaybackSpeed(clampedSpeed)
    }

    fun dispose() {
        if (isDisposed) return
        isDisposed = true
        stopProgressUpdates()
        scope.cancel()
        exoPlayer.removeListener(playerListener)
        exoPlayer.release()
        surface.release()
        textureEntry.release()
    }
}
