package com.example.self_app_update_poc2

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.UserManager
import android.util.Log

class AppDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Device admin disabled")
    }

    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        super.onProfileProvisioningComplete(context, intent)
        Log.i(TAG, "Provisioning complete")

        // Get device policy manager
        val dpm: DevicePolicyManager =
            context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent: ComponentName =
            ComponentName(context, AppDeviceAdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(context.packageName)) {
            Log.i(TAG, "This app is the device owner")

            // Configure kiosk mode
            setupKioskMode(context, dpm, adminComponent)

            // Set as default launcher
            Log.i(TAG, "Setting app as default launcher")
            val launcherIntentFilter = IntentFilter(Intent.ACTION_MAIN)
            launcherIntentFilter.addCategory(Intent.CATEGORY_HOME)
            launcherIntentFilter.addCategory(Intent.CATEGORY_DEFAULT)

            dpm.addPersistentPreferredActivity(
                adminComponent,
                launcherIntentFilter,
                ComponentName(
                    context.packageName,
                    MainActivity::class.java.name
                )
            )

            // Start main activity
            val launchIntent = Intent(context, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launchIntent)
        } else {
            Log.w(TAG, "This app is NOT the device owner")
        }
    }

    private fun setupKioskMode(
        context: Context,
        dpm: DevicePolicyManager,
        adminComponent: ComponentName
    ) {
        Log.i(TAG, "Setting up kiosk mode")

        try {
            // Set as lock task package
            dpm.setLockTaskPackages(adminComponent, arrayOf(context.packageName))

            // Try to disable keyguard and status bar (may require different permissions on different Android versions)
            try {
                dpm.setKeyguardDisabled(adminComponent, true)
                Log.i(TAG, "Keyguard disabled")
            } catch (e: SecurityException) {
                Log.e(TAG, "Cannot disable keyguard: ${e.message}")
            }

            try {
                dpm.setStatusBarDisabled(adminComponent, true)
                Log.i(TAG, "Status bar disabled")
            } catch (e: SecurityException) {
                Log.e(TAG, "Cannot disable status bar: ${e.message}")
            }

            // Disable system features
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_SAFE_BOOT)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_FACTORY_RESET)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_ADD_USER)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA)
            dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_ADJUST_VOLUME)

            // Prevent app uninstallation
            dpm.setUninstallBlocked(adminComponent, context.packageName, true)

            Log.i(TAG, "Kiosk mode setup complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up kiosk mode: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "AppDeviceAdminReceiver"
    }
}