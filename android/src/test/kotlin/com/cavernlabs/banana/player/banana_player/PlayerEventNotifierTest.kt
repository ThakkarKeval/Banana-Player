package com.cavernlabs.banana.player.banana_player

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import org.mockito.Mockito.mock
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import kotlin.test.Test

@OptIn(ExperimentalCoroutinesApi::class)
internal class PlayerEventNotifierTest {

    private val testDispatcher = StandardTestDispatcher()
    private val testScope = TestScope(testDispatcher)

    @Test
    fun notifyPlaybackStateSendsEventToFlutterApi() {
        val flutterApi = mock(BananaPlayerFlutterApi::class.java)
        val notifier = DefaultPlayerEventNotifier(
            textureId = 42L,
            flutterApi = flutterApi,
            scope = testScope
        )

        notifier.notifyPlaybackState(PlaybackState.READY)
        testScope.advanceUntilIdle()

        verify(flutterApi, times(1)).onPlaybackStateChanged(42L, PlaybackState.READY)
    }

    @Test
    fun notifyPositionThrottlesRedundantUpdatesWhenNotForced() {
        val flutterApi = mock(BananaPlayerFlutterApi::class.java)
        val notifier = DefaultPlayerEventNotifier(
            textureId = 42L,
            flutterApi = flutterApi,
            scope = testScope,
            minPositionDeltaMs = 100L
        )

        // First call sends
        notifier.notifyPosition(positionMs = 1000L, durationMs = 10_000L, bufferedPositionMs = 2000L, force = false)
        testScope.advanceUntilIdle()
        verify(flutterApi, times(1)).onPositionChanged(42L, 1000L, 10_000L, 2000L)

        // Second call with delta < 100ms should be throttled
        notifier.notifyPosition(positionMs = 1050L, durationMs = 10_000L, bufferedPositionMs = 2000L, force = false)
        testScope.advanceUntilIdle()
        verify(flutterApi, times(1)).onPositionChanged(42L, 1000L, 10_000L, 2000L)

        // Third call with delta >= 100ms should send
        notifier.notifyPosition(positionMs = 1150L, durationMs = 10_000L, bufferedPositionMs = 2000L, force = false)
        testScope.advanceUntilIdle()
        verify(flutterApi, times(1)).onPositionChanged(42L, 1150L, 10_000L, 2000L)
    }

    @Test
    fun notifyPositionAlwaysSendsWhenForced() {
        val flutterApi = mock(BananaPlayerFlutterApi::class.java)
        val notifier = DefaultPlayerEventNotifier(
            textureId = 42L,
            flutterApi = flutterApi,
            scope = testScope,
            minPositionDeltaMs = 500L
        )

        notifier.notifyPosition(positionMs = 1000L, durationMs = 10_000L, bufferedPositionMs = 2000L, force = true)
        notifier.notifyPosition(positionMs = 1010L, durationMs = 10_000L, bufferedPositionMs = 2000L, force = true)
        testScope.advanceUntilIdle()

        verify(flutterApi, times(1)).onPositionChanged(42L, 1000L, 10_000L, 2000L)
        verify(flutterApi, times(1)).onPositionChanged(42L, 1010L, 10_000L, 2000L)
    }

    @Test
    fun notifyErrorSendsFormattedErrorToFlutterApi() {
        val flutterApi = mock(BananaPlayerFlutterApi::class.java)
        val notifier = DefaultPlayerEventNotifier(
            textureId = 42L,
            flutterApi = flutterApi,
            scope = testScope
        )

        notifier.notifyError("ERROR_CODE_IO_NETWORK_CONNECTION_FAILED", "Connection timeout")
        testScope.advanceUntilIdle()

        verify(flutterApi, times(1)).onError(42L, "ERROR_CODE_IO_NETWORK_CONNECTION_FAILED", "Connection timeout")
    }

    @Test
    fun notifySubtitleTextSendsTextToFlutterApi() {
        val flutterApi = mock(BananaPlayerFlutterApi::class.java)
        val notifier = DefaultPlayerEventNotifier(
            textureId = 42L,
            flutterApi = flutterApi,
            scope = testScope
        )

        notifier.notifySubtitleText("Hello World")
        testScope.advanceUntilIdle()

        verify(flutterApi, times(1)).onSubtitleTextChanged(42L, "Hello World")
    }
}
