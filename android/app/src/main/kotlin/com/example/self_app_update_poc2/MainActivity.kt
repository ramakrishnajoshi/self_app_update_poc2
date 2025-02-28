package com.example.self_app_update_poc2

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var mDevicePolicyManager: DevicePolicyManager? = null
    private var mAdminComponentName: ComponentName? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize device policy manager
        mDevicePolicyManager =
            getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?
        mAdminComponentName = ComponentName(this, AppDeviceAdminReceiver::class.java)

        // Set up kiosk method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeviceOwner" -> {
                        val isDeviceOwner: Boolean = mDevicePolicyManager?.isDeviceOwnerApp(packageName) ?: false
                        Log.i(TAG, "isDeviceOwner: $isDeviceOwner")
                        result.success(isDeviceOwner)
                    }

                    "startLockTask" -> {
                        if (mDevicePolicyManager?.isLockTaskPermitted(packageName) == true) {
                            Log.i(TAG, "Starting lock task mode")
                            startLockTask()
                            result.success(true)
                        } else {
                            Log.w(TAG, "Lock task not permitted for this app")
                            result.success(false)
                        }
                    }

                    "stopLockTask" -> {
                        try {
                            Log.i(TAG, "Stopping lock task mode")
                            stopLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error stopping lock task: ${e.message}")
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // Setup app update channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                // For now, this is empty
                // Implement app install functionality here if needed
                result.notImplemented()
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if we're in device owner mode and start lock task automatically
        if (mDevicePolicyManager != null &&
            mDevicePolicyManager?.isDeviceOwnerApp(packageName) == true &&
            mDevicePolicyManager?.isLockTaskPermitted(packageName) == true
        ) {
            Log.i(TAG, "Device owner detected, starting lock task mode")
            startLockTask()
        }
    }

    override fun onResume() {
        super.onResume()

        // Re-enter lock task mode if needed
        if (mDevicePolicyManager != null &&
            mDevicePolicyManager?.isDeviceOwnerApp(packageName) == true &&
            mDevicePolicyManager?.isLockTaskPermitted(packageName) == true
        ) {
            startLockTask()
        }
    }

    companion object {
        private const val TAG = "MainActivity"
        private const val KIOSK_CHANNEL = "com.example.self_app_update_poc2/kiosk"
        private const val APP_UPDATE_CHANNEL = "com.example.self_app_update_poc2/app_update"
    }
}