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
        // Finish immediately so the user sees nothing.
        // The permission association is still registered by the system.
        finish()
    }
}
