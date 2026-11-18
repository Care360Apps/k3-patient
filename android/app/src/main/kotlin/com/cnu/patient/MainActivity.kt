package com.cnu.patient

import android.content.pm.ApplicationInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "care360/maps_configuration")
            .setMethodCallHandler { call, result ->
                if (call.method == "isConfigured") {
                    val metadata = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA).metaData
                    val key = metadata?.getString("com.google.android.geo.API_KEY")?.trim().orEmpty()
                    result.success(key.isNotEmpty() && !key.contains("YOUR_") && !key.contains("PLACEHOLDER"))
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // BlueStacks' GPU bridge can fault in Flutter's raster thread.
        // Keep this compatibility mode limited to debuggable emulator builds.
        val debugBuild = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (debugBuild && File("/dev/bstpgaipc").exists()) {
            intent.putExtra("enable-software-rendering", true)
            intent.putExtra("enable-impeller", false)
        }
        super.onCreate(savedInstanceState)
    }
}
