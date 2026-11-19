package com.cavernlabs.banana.player.banana_player

import androidx.media3.common.C
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import androidx.media3.exoplayer.ExoPlayer
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class PlayerTrackManagerTest {

    @Test
    fun getVideoQualitiesReturnsEmptyWhenNoTracks() {
        val exoPlayer = mock(ExoPlayer::class.java)
        `when`(exoPlayer.currentTracks).thenReturn(Tracks.EMPTY)
        `when`(exoPlayer.trackSelectionParameters).thenReturn(TrackSelectionParameters.DEFAULT)

        val trackManager = DefaultPlayerTrackManager(exoPlayer)
        val qualities = trackManager.getVideoQualities()

        assertTrue(qualities.isEmpty())
    }

    @Test
    fun getSubtitleTracksReturnsEmptyWhenNoTracks() {
        val exoPlayer = mock(ExoPlayer::class.java)
        `when`(exoPlayer.currentTracks).thenReturn(Tracks.EMPTY)
        `when`(exoPlayer.trackSelectionParameters).thenReturn(TrackSelectionParameters.DEFAULT)

        val trackManager = DefaultPlayerTrackManager(exoPlayer)
        val subtitles = trackManager.getSubtitleTracks()

        assertTrue(subtitles.isEmpty())
    }

    @Test
    fun setVideoQualityAutoClearsVideoOverrides() {
        val exoPlayer = mock(ExoPlayer::class.java)
        val initialParameters = TrackSelectionParameters.DEFAULT
        `when`(exoPlayer.trackSelectionParameters).thenReturn(initialParameters)

        val trackManager = DefaultPlayerTrackManager(exoPlayer)
        trackManager.setVideoQuality("auto")

        // Verifies that trackSelectionParameters was updated
        verify(exoPlayer).trackSelectionParameters = initialParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .build()
    }

    @Test
    fun setSubtitleTrackOffDisablesTextTrackType() {
        val exoPlayer = mock(ExoPlayer::class.java)
        val initialParameters = TrackSelectionParameters.DEFAULT
        `when`(exoPlayer.trackSelectionParameters).thenReturn(initialParameters)

        val trackManager = DefaultPlayerTrackManager(exoPlayer)
        trackManager.setSubtitleTrack("off")

        verify(exoPlayer).trackSelectionParameters = initialParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            .build()
    }

    @Test
    fun resetOverridesClearsVideoAndTextOverrides() {
        val exoPlayer = mock(ExoPlayer::class.java)
        val initialParameters = TrackSelectionParameters.DEFAULT
        `when`(exoPlayer.trackSelectionParameters).thenReturn(initialParameters)

        val trackManager = DefaultPlayerTrackManager(exoPlayer)
        trackManager.resetOverrides()

        verify(exoPlayer).trackSelectionParameters = initialParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
            .build()
    }
}
