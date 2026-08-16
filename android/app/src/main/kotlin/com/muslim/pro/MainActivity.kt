package com.muslim.pro

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.muslim.pro/app_icon"

    private val aliases = mapOf(
        "default" to ".IconDefault",
        "1" to ".IconAlt1",
        "2" to ".IconAlt2",
        "3" to ".IconAlt3",
        "4" to ".IconAlt4",
        "5" to ".IconAlt5",
        "6" to ".IconAlt6",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val id = call.argument<String>("id") ?: "default"
                    try {
                        setLauncherIcon(id)
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error("APP_ICON_ERROR", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setLauncherIcon(id: String) {
        val selectedAlias = aliases[id] ?: aliases.getValue("default")
        val pm = packageManager
        val pkg = packageName

        pm.setComponentEnabledSetting(
            ComponentName(pkg, pkg + selectedAlias),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )

        aliases.values
            .filter { it != selectedAlias }
            .forEach { alias ->
                pm.setComponentEnabledSetting(
                    ComponentName(pkg, pkg + alias),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
    }
}
