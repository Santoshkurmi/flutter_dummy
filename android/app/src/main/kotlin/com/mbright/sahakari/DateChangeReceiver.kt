package com.mbright.sahakari

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.Calendar

class DateChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_DATE_CHANGED || 
            action == Intent.ACTION_TIMEZONE_CHANGED || 
            action == Intent.ACTION_TIME_CHANGED) {
            
            updateDateNotification(context)
        }
    }

    private fun updateDateNotification(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.showDateNotification", false)
        if (!enabled) {
            return
        }

        try {
            val notiLang = prefs.getString("flutter.notificationLanguage", "ne") ?: "ne"
            val isNepali = notiLang == "ne"

            val cal = Calendar.getInstance()
            val yearAd = cal.get(Calendar.YEAR)
            val monthAd = cal.get(Calendar.MONTH) + 1
            val dayAd = cal.get(Calendar.DAY_OF_MONTH)
            val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
            val weekdayIndex = dayOfWeek - 1

            val bsDate = NepaliDateConverter.adToBs(yearAd, monthAd, dayAd)
            val yearBs = bsDate[0]
            val monthBs = bsDate[1]
            val dayBs = bsDate[2]

            val title = NepaliDateConverter.getNepaliDateString(yearBs, monthBs, dayBs, weekdayIndex, isNepali)

            var event = ""
            val cacheKey = "flutter.api_cache_/holidays_month_bs=${monthBs}&year_bs=${yearBs}"
            val cacheJsonStr = prefs.getString(cacheKey, null)

            if (cacheJsonStr != null) {
                try {
                    val cachedEntry = org.json.JSONObject(cacheJsonStr)
                    val data = cachedEntry.optJSONObject("data")
                    val calendar = data?.optJSONArray("calendar")
                    if (calendar != null) {
                        for (i in 0 until calendar.length()) {
                            val dayData = calendar.getJSONObject(i)
                            if (dayData.optInt("day") == dayBs) {
                                val holName = dayData.optString("holiday_name", "")
                                val isHoliday = dayData.optBoolean("is_holiday", false)
                                if (holName.isNotEmpty() && !holName.equals("saturday", ignoreCase = true)) {
                                    event = holName
                                } else if (isHoliday && holName.equals("saturday", ignoreCase = true)) {
                                    event = "Weekly Holiday"
                                }
                                break
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }

            if (event.isEmpty() && dayOfWeek == Calendar.SATURDAY) {
                event = "Weekly Holiday"
            }

            val nepaliTranslations = mapOf(
                "Weekly Holiday" to "साप्ताहिक बिदा"
            )

            val body = if (isNepali) {
                if (event.isNotEmpty()) {
                    val translatedEvent = nepaliTranslations[event] ?: event
                    "आजको पर्व/बिदा: $translatedEvent"
                } else {
                    "आज कुनै विशेष पर्व/बिदा छैन"
                }
            } else {
                if (event.isNotEmpty()) {
                    "Today's Event: $event"
                } else {
                    "No events scheduled today"
                }
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "date_notification_channel"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    if (isNepali) "नेपाली पात्रो मिति" else "Nepali Date Notification",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = if (isNepali) "नेपाली पात्रोको मिति र पर्वहरू देखाउँछ" else "Displays persistent current Nepali date and events"
                }
                notificationManager.createNotificationChannel(channel)
            }

            val iconId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                putExtra("payload", "calendar")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                999,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notificationBuilder = NotificationCompat.Builder(context, channelId)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(if (iconId != 0) iconId else android.R.drawable.ic_menu_today)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setShowWhen(false)

            notificationManager.notify(999, notificationBuilder.build())

        } catch (e: Exception) {
            // Ignore
        }
    }
}
