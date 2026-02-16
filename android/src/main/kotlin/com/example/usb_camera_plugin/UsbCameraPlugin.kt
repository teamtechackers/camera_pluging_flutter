package com.example.usb_camera_plugin

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class UsbCameraPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "usb_camera_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    android.util.Log.d("UsbCameraPlugin", "📞 Method called: ${call.method}")
    
    when (call.method) {
      "openCamera" -> {
        activity?.let {
          try {
            // 🎥 Direct camera launch - skip CameraActivity
            val intent = Intent()
            intent.setClassName(
              it.packageName,
              "com.jiangdg.demo.MainActivity"  // Full camera UI
            )
            it.startActivity(intent)
            result.success("Camera opened directly")
          } catch (e: Exception) {
            result.error("ERROR", "Failed to open camera: ${e.message}", null)
          }
        } ?: result.error("ERROR", "Activity not available", null)
      }
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getLastCapturedImage" -> {
        android.util.Log.d("UsbCameraPlugin", "🖼️ Getting last captured image...")
        activity?.let {
          val prefs = it.getSharedPreferences("camera_prefs", android.content.Context.MODE_PRIVATE)
          val imagePath = prefs.getString("last_captured_image", null)
          android.util.Log.d("UsbCameraPlugin", "📸 Image path from prefs: $imagePath")
          // Clear after reading
          prefs.edit().remove("last_captured_image").apply()
          android.util.Log.d("UsbCameraPlugin", "✅ Returning path to Flutter: $imagePath")
          result.success(imagePath)
        } ?: run {
          android.util.Log.d("UsbCameraPlugin", "❌ Activity is null")
          result.success(null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
