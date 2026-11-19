package com.cavernlabs.banana.player.banana_player

import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets
import java.io.File

/**
 * Resolves media URLs (network, local filesystem, or Flutter asset) to Android [Uri]s.
 */
interface MediaUriResolver {
    fun resolve(url: String): Uri
}

/**
 * Default implementation of [MediaUriResolver] handling network URIs, local files,
 * and Flutter assets referenced with "asset://".
 */
class DefaultMediaUriResolver(
    private val flutterAssets: FlutterAssets? = null
) : MediaUriResolver {
    override fun resolve(url: String): Uri {
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
                Uri.fromFile(File(url))
            }
            else -> {
                Uri.parse(url)
            }
        }
    }
}
