package com.example.suc_khoe_ca_nhan

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class CareAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val prefs = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            for ((key, value) in prefs.all) {
                val id = key.toIntOrNull() ?: continue
                val at = value as? Long ?: continue
                if (at > System.currentTimeMillis()) schedule(context, id, at)
                else prefs.edit().remove(key).apply()
            }
            return
        }
        val id = intent.getIntExtra("occurrence_id", -1)
        if (id <= 0) return
        context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, "Lịch chăm sóc", NotificationManager.IMPORTANCE_DEFAULT))
        val open = Intent(context, MainActivity::class.java).putExtra("occurrence_id", id).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
        manager.notify(id, builder.setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Đến lịch chăm sóc sức khỏe")
            .setContentText("Mở ứng dụng để xem lịch và xác nhận.")
            .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true).setContentIntent(pending).build())
    }
    companion object {
        private const val STORE = "care_alarm_times"
        private const val CHANNEL = "personal_health_care"
        private fun alarm(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(context, id,
            Intent(context, CareAlarmReceiver::class.java).putExtra("occurrence_id", id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun schedule(context: Context, id: Int, at: Long) {
            require(id > 0 && at > System.currentTimeMillis())
            val manager = context.getSystemService(AlarmManager::class.java)
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, alarm(context, id))
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().putLong(id.toString(), at).apply()
        }
        fun cancel(context: Context, id: Int) {
            context.getSystemService(AlarmManager::class.java).cancel(alarm(context, id))
            context.getSystemService(NotificationManager::class.java).cancel(id)
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
        }
        fun pendingIds(context: Context): List<Int> = context.getSharedPreferences(STORE, Context.MODE_PRIVATE).all
            .filter { (_, value) -> (value as? Long ?: 0L) > System.currentTimeMillis() }.keys.mapNotNull { it.toIntOrNull() }
    }
}
