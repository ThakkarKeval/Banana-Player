package com.cavernlabs.banana.player.banana_player

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlin.math.abs

/**
 * Handles communication of playback events, position updates, track info, and errors to Flutter.
 */
interface PlayerEventNotifier {
    fun notifyPlaybackState(state: PlaybackState)
    fun notifyPosition(positionMs: Long, durationMs: Long, bufferedPositionMs: Long, force: Boolean = false)
    fun notifyVideoQualities(qualities: List<VideoQuality>)
    fun notifySubtitleTracks(tracks: List<SubtitleTrack>)
    fun notifySubtitleText(text: String?)
    fun notifyError(errorCode: String, errorMessage: String)
}

/**
 * Default implementation of [PlayerEventNotifier] with event throttling and structured logging.
 */
class DefaultPlayerEventNotifier(
    private val textureId: Long,
    private val flutterApi: BananaPlayerFlutterApi,
    private val scope: CoroutineScope,
    private val minPositionDeltaMs: Long = 100L
) : PlayerEventNotifier {

    companion object {
        private const val TAG = "BananaPlayerEvents"
    }

    private var lastReportedPositionMs: Long = -1L
    private var lastReportedDurationMs: Long = -1L
    private var lastReportedBufferedMs: Long = -1L

    private fun safeLaunch(eventName: String, block: suspend () -> Unit) {
        scope.launch {
            try {
                block()
            } catch (e: Exception) {
                Log.w(TAG, "[$textureId] Failed to deliver $eventName event to Flutter: ${e.message}", e)
            }
        }
    }

    override fun notifyPlaybackState(state: PlaybackState) {
        safeLaunch("PlaybackState") {
            flutterApi.onPlaybackStateChanged(textureId, state)
        }
    }

    override fun notifyPosition(
        positionMs: Long,
        durationMs: Long,
        bufferedPositionMs: Long,
        force: Boolean
    ) {
        if (!force) {
            val positionDiff = abs(positionMs - lastReportedPositionMs)
            val durationDiff = abs(durationMs - lastReportedDurationMs)
            val bufferedDiff = abs(bufferedPositionMs - lastReportedBufferedMs)
            if (positionDiff < minPositionDeltaMs && durationDiff == 0L && bufferedDiff < 250L) {
                return
            }
        }

        lastReportedPositionMs = positionMs
        lastReportedDurationMs = durationMs
        lastReportedBufferedMs = bufferedPositionMs

        safeLaunch("Position") {
            flutterApi.onPositionChanged(textureId, positionMs, durationMs, bufferedPositionMs)
        }
    }

    override fun notifyVideoQualities(qualities: List<VideoQuality>) {
        safeLaunch("VideoQualities") {
            flutterApi.onVideoQualitiesChanged(textureId, qualities)
        }
    }

    override fun notifySubtitleTracks(tracks: List<SubtitleTrack>) {
        safeLaunch("SubtitleTracks") {
            flutterApi.onSubtitleTracksChanged(textureId, tracks)
        }
    }

    override fun notifySubtitleText(text: String?) {
        safeLaunch("SubtitleText") {
            flutterApi.onSubtitleTextChanged(textureId, text)
        }
    }

    override fun notifyError(errorCode: String, errorMessage: String) {
        safeLaunch("Error") {
            flutterApi.onError(textureId, errorCode, errorMessage)
        }
    }
}
