package com.example.self_app_update_poc2

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.app.admin.DevicePolicyManager

class EnterpriseDeviceOwnerReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        setupEnterprisePolicy(context)
    }

    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        super.onProfileProvisioningComplete(context, intent)
        setupEnterprisePolicy(context)
    }

    private fun setupEnterprisePolicy(context: Context) {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = getComponentName(context)

        if (dpm.isDeviceOwnerApp(context.packageName)) {
            // Set kiosk mode policies
            dpm.setLockTaskPackages(componentName, arrayOf(context.packageName))
            
            // Set enterprise policies
            dpm.apply {
                setGlobalSetting(componentName, 
                    Settings.Global.STAY_ON_WHILE_PLUGGED_IN, 
                    (BatteryManager.BATTERY_PLUGGED_AC
                            or BatteryManager.BATTERY_PLUGGED_USB
                            or BatteryManager.BATTERY_PLUGGED_WIRELESS).toString())
                
                setKeyguardDisabled(componentName, true)
                setStatusBarDisabled(componentName, true)
                
                // Prevent factory reset
                addUserRestriction(componentName, UserManager.DISALLOW_FACTORY_RESET)
                
                // Prevent safe boot
                addUserRestriction(componentName, UserManager.DISALLOW_SAFE_BOOT)
                
                // Lock task mode settings
                setLockTaskFeatures(componentName, 
                    DevicePolicyManager.LOCK_TASK_FEATURE_GLOBAL_ACTIONS
                    or DevicePolicyManager.LOCK_TASK_FEATURE_KEYGUARD
                    or DevicePolicyManager.LOCK_TASK_FEATURE_SYSTEM_INFO)
            }
        }
    }
} 