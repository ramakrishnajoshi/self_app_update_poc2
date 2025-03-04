package com.example.self_app_update_poc2

import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.self_app_update_poc2/app_update"
    private val REQUEST_HOME_APP = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    installApk(filePath, result)
                } else {
                    result.error("INVALID_ARGUMENT", "File path is required", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
    
    private fun installApk(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "The APK file was not found", null)
                return
            }
            
            // For Android 8+ (API 26+), we need to request the permission to install unknown apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (!packageManager.canRequestPackageInstalls()) {
                    // Open settings to enable "Install Unknown Apps" permission
                    val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                    intent.data = Uri.parse("package:${context.packageName}")
                    startActivity(intent)
                    result.error("PERMISSION_REQUIRED", "Permission to install apps is required", null)
                    return
                }
            }
            
            val intent = Intent(Intent.ACTION_VIEW)
            val uri: Uri
            
            // For Android 7+ (API 24+), we need to use FileProvider
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                uri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file
                )
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                uri = Uri.fromFile(file)
            }
            
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // For Android 9+ (API 28+), we need to use the package installer
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                if (intent.resolveActivity(packageManager) != null) {
                    context.startActivity(intent)
                    result.success(true)
                } else {
                    result.error("NO_ACTIVITY", "No activity found to handle the intent", null)
                }
            } else {
                context.startActivity(intent)
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    override fun onResume() {
        super.onResume()
        setDefaultLauncher()
    }

    private fun setDefaultLauncher() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager?.isRoleAvailable(RoleManager.ROLE_HOME) == true) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME)
                    startActivityForResult(intent, REQUEST_HOME_APP)
                }
            }
        } else {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            val packageManager: PackageManager = packageManager
            val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            
            if (resolveInfo?.activityInfo?.packageName != packageName) {
                val selector = Intent(Intent.ACTION_MAIN)
                selector.addCategory(Intent.CATEGORY_HOME)
                selector.addCategory(Intent.CATEGORY_DEFAULT)
                startActivity(selector)
            }
        }
    }
}
