package com.example.self_app_update_poc2

import android.app.Service
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.UserManager
import android.view.WindowManager

class KioskService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, DeviceAdminReceiver::class.java)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
            enableKioskMode()
        }
        return START_STICKY
    }

    private fun enableKioskMode() {
        try {
            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                // Set kiosk policies
                devicePolicyManager.setLockTaskPackages(componentName, arrayOf(packageName))
                
                // Disable keyguard and status bar
                devicePolicyManager.setKeyguardDisabled(componentName, true)
                devicePolicyManager.setStatusBarDisabled(componentName, true)

                // Other kiosk policies
                devicePolicyManager.apply {
                    addUserRestriction(componentName, UserManager.DISALLOW_SAFE_BOOT)
                    addUserRestriction(componentName, UserManager.DISALLOW_FACTORY_RESET)
                    addUserRestriction(componentName, UserManager.DISALLOW_ADD_USER)
                    addUserRestriction(componentName, UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA)
                    setStatusBarDisabled(componentName, true)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
} 