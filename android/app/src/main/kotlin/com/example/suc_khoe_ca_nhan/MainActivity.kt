package com.example.suc_khoe_ca_nhan

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var permissionResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.kienphi.personal_health/notifications")
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(permissionStatus())
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (permissionResult != null) result.error("busy", "Permission request pending", null)
                            else { permissionResult = result; requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2041) }
                        } else result.success(permissionStatus())
                    }
                    "schedule" -> {
                        if (permissionStatus() != "granted") throw IllegalStateException("permission_denied")
                        CareAlarmReceiver.schedule(this, (call.argument<Number>("id")!!).toInt(), (call.argument<Number>("at")!!).toLong())
                        result.success(null)
                    }
                    "cancel" -> { CareAlarmReceiver.cancel(this, call.argument<Number>("id")!!.toInt()); result.success(null) }
                    "pendingIds" -> result.success(CareAlarmReceiver.pendingIds(this))
                    "getLaunchOccurrenceId" -> {
                        val id = intent?.getIntExtra("occurrence_id", -1) ?: -1
                        intent?.removeExtra("occurrence_id")
                        result.success(if (id > 0) id else null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) { result.error("notification_native", "Notification operation failed", null) }
        }
    }
    private fun permissionStatus(): String =
        if (getSystemService(NotificationManager::class.java).areNotificationsEnabled()) "granted" else "denied"
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 2041) { permissionResult?.success(permissionStatus()); permissionResult = null }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val id = intent.getIntExtra("occurrence_id", -1)
        if (id > 0 && ::channel.isInitialized) { channel.invokeMethod("selected", id); intent.removeExtra("occurrence_id") }
    }
}
