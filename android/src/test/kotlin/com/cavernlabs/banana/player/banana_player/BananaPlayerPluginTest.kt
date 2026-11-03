package com.cavernlabs.banana.player.banana_player

import kotlin.test.Test
import kotlin.test.assertNotNull

internal class BananaPlayerPluginTest {
    @Test
    fun pluginCanBeInstantiated() {
        val plugin = BananaPlayerPlugin()
        assertNotNull(plugin)
    }
}
