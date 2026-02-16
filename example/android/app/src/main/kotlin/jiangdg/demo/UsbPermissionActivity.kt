package com.jiangdg.demo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

/**
 * Transparent activity to handle USB_DEVICE_ATTACHED intent.
 * This allows Android to persist USB permissions ("Always use this app")
 * without actually launching any UI.
 */
class UsbPermissionActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 🚀 CRITICAL FIX: Adding a slight delay before finishing.
        // If the activity finishes too fast, the system might not persist the "Always use" choice.
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            finish()
        }, 500)
    }
}
