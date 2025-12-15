package com.example.usb_camera_plugin_example

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_camera_plugin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "📞 Method called: ${call.method}")
            
            when (call.method) {
                "openPdf" -> {
                    try {
                        val path = call.arguments as? String
                        if (path.isNullOrEmpty()) {
                            result.error("INVALID_PATH", "PDF path is null or empty", null)
                            return@setMethodCallHandler
                        }

                        val file = File(path)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "PDF file does not exist at path: $path", null)
                            return@setMethodCallHandler
                        }

                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/pdf")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                        }

                        // Verify that there is an app to handle this intent
                        val pm = packageManager
                        if (intent.resolveActivity(pm) != null) {
                            startActivity(intent)
                            result.success(null)
                        } else {
                            result.error("NO_PDF_APP", "No application available to open PDF", null)
                        }
                    } catch (e: Exception) {
                        result.error("OPEN_PDF_ERROR", e.message, null)
                    }
                }
                "openCamera" -> {
                    try {
                        val intent = Intent(this, com.jiangdg.demo.MainActivity::class.java)
                        startActivity(intent)
                        result.success("Camera opened")
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getLastCapturedImage" -> {
                    // ✅ Get from ImageHolder
                    val imagePath = ImageHolder.getImagePath()
                    android.util.Log.d("MainActivity", "📸 Returning image: $imagePath")
                    result.success(imagePath)
                }
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                else -> result.notImplemented()
            }
        }
    }
}
