package com.kovravpn.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Small helpers for the UI: open Android VPN settings, open a link.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kovra/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openVpnSettings" -> result.success(launch(Intent(Settings.ACTION_VPN_SETTINGS)))
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url == null) result.success(false)
                        else result.success(launch(Intent(Intent.ACTION_VIEW, Uri.parse(url))))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launch(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: ActivityNotFoundException) {
        // Some devices hide the VPN page; fall back to the main settings screen.
        if (intent.action == Settings.ACTION_VPN_SETTINGS) {
            try {
                startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                true
            } catch (_: ActivityNotFoundException) {
                false
            }
        } else false
    }
}
