package com.cavernlabs.banana.player.banana_player

import android.content.Context
import android.view.Surface
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.text.CueGroup
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets
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
class BananaPlayer internal constructor(
    context: Context,
    private val textureEntry: TextureRegistry.SurfaceTextureEntry,
    config: PlayerConfig,
    private val uriResolver: MediaUriResolver,
    private val eventNotifier: PlayerEventNotifier,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main),
    exoPlayerProvider: ((Context) -> ExoPlayer)? = null,
    trackManagerProvider: ((ExoPlayer) -> PlayerTrackManager)? = null
) : BananaPlayerInstance {

    constructor(
        context: Context,
        textureEntry: TextureRegistry.SurfaceTextureEntry,
        flutterApi: BananaPlayerFlutterApi,
        config: PlayerConfig,
        flutterAssets: FlutterAssets? = null
    ) : this(
        context = context,
        textureEntry = textureEntry,
        config = config,
        uriResolver = DefaultMediaUriResolver(flutterAssets),
        eventNotifier = DefaultPlayerEventNotifier(
            textureId = textureEntry.id(),
            flutterApi = flutterApi,
            scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        )
    )

    override val textureId: Long = textureEntry.id()
    private val surface: Surface? = try {
        val st = textureEntry.surfaceTexture()
        if (st != null) Surface(st) else null
    } catch (_: Exception) {
        null
    }
    private var progressJob: Job? = null
    private var isDisposed = false

    private val exoPlayer: ExoPlayer = exoPlayerProvider?.invoke(context) ?: run {
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 BananaPlayer/1.0")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(15_000)
            .setReadTimeoutMs(15_000)

        val dataSourceFactory = DefaultDataSource.Factory(context, httpDataSourceFactory)
        val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()

        val loadControl = DefaultLoadControl.Builder()
            .setBackBuffer(/* backBufferDurationMs = */ 30_000, /* retainBackBufferFromKeyframe = */ true)
            .setBufferDurationsMs(
                /* minBufferMs = */ 50_000,
                /* maxBufferMs = */ 50_000,
                /* bufferForPlaybackMs = */ 1_000,
                /* bufferForPlaybackAfterRebufferMs = */ 1_500
            )
            .build()

        ExoPlayer.Builder(context)
            .setMediaSourceFactory(mediaSourceFactory)
            .setLoadControl(loadControl)
            .setAudioAttributes(audioAttributes, /* handleAudioFocus = */ true)
            .build()
    }

    private val trackManager: PlayerTrackManager = trackManagerProvider?.invoke(exoPlayer)
        ?: DefaultPlayerTrackManager(exoPlayer)

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
            eventNotifier.notifyPlaybackState(state)
            eventNotifier.notifyPosition(getPosition(), getDuration(), getBufferedPosition(), force = true)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (isPlaying) {
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
            if (exoPlayer.playbackState == Player.STATE_READY) {
                eventNotifier.notifyPlaybackState(if (isPlaying) PlaybackState.READY else PlaybackState.PAUSED)
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            stopProgressUpdates()
            eventNotifier.notifyPlaybackState(PlaybackState.IDLE)
            eventNotifier.notifyError(error.errorCodeName, error.message ?: "Playback error")
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
            eventNotifier.notifySubtitleText(text)
        }

        override fun onTracksChanged(tracks: Tracks) {
            eventNotifier.notifyVideoQualities(trackManager.getVideoQualities())
            eventNotifier.notifySubtitleTracks(trackManager.getSubtitleTracks())
        }

        override fun onRenderedFirstFrame() {
            eventNotifier.notifyVideoQualities(trackManager.getVideoQualities())
            eventNotifier.notifySubtitleTracks(trackManager.getSubtitleTracks())
        }
    }

    private fun startProgressUpdates() {
        if (progressJob?.isActive == true) return
        progressJob = scope.launch {
            while (isActive) {
                eventNotifier.notifyPosition(getPosition(), getDuration(), getBufferedPosition(), force = false)
                delay(200)
            }
        }
    }

    private fun stopProgressUpdates() {
        progressJob?.cancel()
        progressJob = null
        eventNotifier.notifyPosition(getPosition(), getDuration(), getBufferedPosition(), force = true)
    }

    override fun getDuration(): Long {
        val dur = exoPlayer.duration
        return if (dur == C.TIME_UNSET || dur < 0) 0L else dur
    }

    override fun getPosition(): Long {
        return exoPlayer.currentPosition.coerceAtLeast(0L)
    }

    fun getBufferedPosition(): Long {
        return exoPlayer.bufferedPosition.coerceAtLeast(0L)
    }

    init {
        exoPlayer.setSeekParameters(SeekParameters.CLOSEST_SYNC)
        surface?.let { exoPlayer.setVideoSurface(it) }
        exoPlayer.volume = config.volume.toFloat()
        exoPlayer.addListener(playerListener)

        val mediaItem = MediaItem.fromUri(uriResolver.resolve(config.url))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = config.autoPlay
        eventNotifier.notifyPosition(getPosition(), getDuration(), getBufferedPosition(), force = true)
    }

    override fun play() {
        if (exoPlayer.playbackState == Player.STATE_ENDED) {
            exoPlayer.seekTo(0)
        }
        exoPlayer.play()
        startProgressUpdates()
    }

    override fun pause() {
        exoPlayer.pause()
        stopProgressUpdates()
    }

    override fun setSource(url: String) {
        stopProgressUpdates()
        eventNotifier.notifySubtitleText(null)
        trackManager.resetOverrides()
        val mediaItem = MediaItem.fromUri(uriResolver.resolve(url))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.play()
    }

    override fun getVideoQualities(): List<VideoQuality> = trackManager.getVideoQualities()

    override fun setVideoQuality(qualityId: String) {
        trackManager.setVideoQuality(qualityId)
        eventNotifier.notifyVideoQualities(trackManager.getVideoQualities())
    }

    override fun getSubtitleTracks(): List<SubtitleTrack> = trackManager.getSubtitleTracks()

    override fun setSubtitleTrack(trackId: String) {
        trackManager.setSubtitleTrack(trackId)
        if (trackId.equals("off", ignoreCase = true) || trackId.isEmpty()) {
            eventNotifier.notifySubtitleText(null)
        }
        eventNotifier.notifySubtitleTracks(trackManager.getSubtitleTracks())
    }

    override fun seekTo(positionMs: Long) {
        val targetMs = if (positionMs < 0L) 0L else positionMs
        exoPlayer.seekTo(targetMs)
        eventNotifier.notifyPosition(getPosition(), getDuration(), getBufferedPosition(), force = true)
    }

    override fun setVolume(volume: Float) {
        exoPlayer.volume = volume.coerceIn(0f, 1f)
    }

    override fun setPlaybackSpeed(speed: Float) {
        val clampedSpeed = speed.coerceIn(0.25f, 4.0f)
        exoPlayer.setPlaybackSpeed(clampedSpeed)
    }

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        stopProgressUpdates()
        scope.cancel()
        exoPlayer.removeListener(playerListener)
        exoPlayer.release()
        surface?.release()
        textureEntry.release()
    }
}
