package com.cavernlabs.banana.player.banana_player

/**
 * Common contract for a BananaPlayer playback session instance.
 */
interface BananaPlayerInstance {
    val textureId: Long
    fun play()
    fun pause()
    fun setSource(url: String)
    fun seekTo(positionMs: Long)
    fun setVolume(volume: Float)
    fun getDuration(): Long
    fun getPosition(): Long
    fun getVideoQualities(): List<VideoQuality>
    fun setVideoQuality(qualityId: String)
    fun setPlaybackSpeed(speed: Float)
    fun getSubtitleTracks(): List<SubtitleTrack>
    fun setSubtitleTrack(trackId: String)
    fun dispose()
}
