package com.cavernlabs.banana.player.banana_player

import androidx.media3.common.C
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.exoplayer.ExoPlayer

/**
 * Manages video and subtitle track querying and selection for an ExoPlayer instance.
 */
interface PlayerTrackManager {
    fun getVideoQualities(): List<VideoQuality>
    fun setVideoQuality(qualityId: String)
    fun getSubtitleTracks(): List<SubtitleTrack>
    fun setSubtitleTrack(trackId: String)
    fun resetOverrides()
}

/**
 * Default implementation of [PlayerTrackManager] configuring ExoPlayer's track selection parameters.
 */
class DefaultPlayerTrackManager(
    private val exoPlayer: ExoPlayer
) : PlayerTrackManager {

    override fun getVideoQualities(): List<VideoQuality> {
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

    override fun setVideoQuality(qualityId: String) {
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
                        val altId = format.id ?: "${format.height}p"
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
    }

    override fun getSubtitleTracks(): List<SubtitleTrack> {
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

    override fun setSubtitleTrack(trackId: String) {
        if (trackId.equals("off", ignoreCase = true) || trackId.isEmpty()) {
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
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
    }

    override fun resetOverrides() {
        exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
            .build()
    }
}
