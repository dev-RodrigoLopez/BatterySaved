package com.example.battery_saved

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  private val CHANNEL = "battery_compliance"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "status" -> result.success(getStatus())
          "openAppDetails" -> { openAppDetails(); result.success(null) }
          "requestIgnoreOptimizations" -> { requestIgnoreOptimizations(); result.success(null) }
          "openOptimizationSettings" -> { openOptimizationSettings(); result.success(null) }
          else -> result.notImplemented()
        }
      }
  }

  private fun getStatus(): HashMap<String, Any> {
    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager

    return hashMapOf(
      "sdkInt" to Build.VERSION.SDK_INT,
      "backgroundRestricted" to am.isBackgroundRestricted, // API 28+
      "ignoringOptimizations" to pm.isIgnoringBatteryOptimizations(packageName), // API 23+
      "powerSaveMode" to pm.isPowerSaveMode,
      "manufacturer" to Build.MANUFACTURER.lowercase(),
      "brand" to Build.BRAND.lowercase(),
      "model" to Build.MODEL
    )
  }

  private fun openAppDetails() {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
      data = Uri.parse("package:$packageName")
    }
    startActivity(intent)
  }

  private fun requestIgnoreOptimizations() {
    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
      data = Uri.parse("package:$packageName")
    }
    startActivity(intent)
  }

  private fun openOptimizationSettings() {
    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
    startActivity(intent)
  }
}
