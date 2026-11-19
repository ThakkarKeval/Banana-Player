package com.cavernlabs.banana.player.banana_player

import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals

internal class MediaUriResolverTest {

    @Test
    fun resolvesHttpAndHttpsUrlsDirectly() {
        val resolver = DefaultMediaUriResolver()
        val httpUrl = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        val httpsUrl = "https://example.com/live/stream.m3u8"

        assertEquals(httpUrl, resolver.resolve(httpUrl).toString())
        assertEquals(httpsUrl, resolver.resolve(httpsUrl).toString())
    }

    @Test
    fun resolvesLocalFilePathsAsFileUri() {
        val resolver = DefaultMediaUriResolver()
        val localPath = "/storage/emulated/0/Movies/sample.mp4"
        val resolved = resolver.resolve(localPath)

        assertEquals("file", resolved.scheme)
        assertEquals(localPath, resolved.path)
    }

    @Test
    fun resolvesAssetUrlsUsingFlutterAssets() {
        val flutterAssets = mock(FlutterAssets::class.java)
        `when`(flutterAssets.getAssetFilePathByName("assets/videos/intro.mp4"))
            .thenReturn("flutter_assets/assets/videos/intro.mp4")

        val resolver = DefaultMediaUriResolver(flutterAssets)
        val resolved = resolver.resolve("asset://assets/videos/intro.mp4")

        assertEquals("asset", resolved.scheme)
        assertEquals("/flutter_assets/assets/videos/intro.mp4", resolved.path)
    }

    @Test
    fun resolvesAssetUrlsWithMultipleLeadingSlashes() {
        val flutterAssets = mock(FlutterAssets::class.java)
        `when`(flutterAssets.getAssetFilePathByName("sample.mp4"))
            .thenReturn("flutter_assets/sample.mp4")

        val resolver = DefaultMediaUriResolver(flutterAssets)
        val resolved = resolver.resolve("asset:////sample.mp4")

        assertEquals("asset", resolved.scheme)
        assertEquals("/flutter_assets/sample.mp4", resolved.path)
    }
}
