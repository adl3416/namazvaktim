package com.vakit.app.namaz_vakitleri

import android.app.PendingIntent
import android.os.Bundle
import android.view.View
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> updateAllWidgets(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        private const val PREFS_NAME = "prayer_widget"
        private const val KEY_CITY = "city"
        private const val KEY_DATE_LABEL = "date_label"
        private const val KEY_ACTIVE_PRAYER_NAME = "active_prayer_name"
        private const val KEY_PRAYERS_JSON = "prayers_json"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PrayerTimesWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            widgetIds.forEach { widgetId ->
                updateAppWidget(context, manager, widgetId)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val city = prefs.getString(KEY_CITY, "Namaz Vaktim") ?: "Namaz Vaktim"
            val dateLabel = prefs.getString(KEY_DATE_LABEL, formatToday()) ?: formatToday()
            val storedActivePrayerName = prefs.getString(KEY_ACTIVE_PRAYER_NAME, null)
            val prayersJson = prefs.getString(KEY_PRAYERS_JSON, "[]") ?: "[]"
            val prayers = parsePrayers(prayersJson)
            val nextPrayerName = findNextPrayerName(prayers)
            val activePrayerName = storedActivePrayerName ?: findActivePrayerName(prayers)
            val nextPrayer = prayers.firstOrNull { it.name == nextPrayerName } ?: prayers.firstOrNull()
            val isCompact = isCompactWidget(appWidgetManager.getAppWidgetOptions(appWidgetId))

            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
            views.setTextViewText(R.id.widget_header, city)
            views.setInt(
                R.id.widget_header_container,
                "setBackgroundColor",
                resolvePrayerHeaderColor(activePrayerName ?: nextPrayerName)
            )

            bindNextPrayerCard(views, nextPrayer, isCompact)
            bindPrayerRows(views, prayers, nextPrayerName, isCompact)
            bindLaunchIntent(context, views)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun bindLaunchIntent(context: Context, views: RemoteViews) {
            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        private fun bindNextPrayerCard(
            views: RemoteViews,
            nextPrayer: WidgetPrayer?,
            isCompact: Boolean
        ) {
            views.setTextViewText(
                R.id.widget_next_name,
                nextPrayer?.let { "${it.displayName} Vaktine" } ?: "Vakit yok"
            )
            views.setTextViewText(
                R.id.widget_next_time,
                nextPrayer?.let { formatRemaining(it.remainingMillis) } ?: "--"
            )
            views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_countdown,
                nextPrayer?.let { "Saat ${it.timeLabel}" } ?: "Saat --:--"
            )
        }

        private fun bindPrayerRows(
            views: RemoteViews,
            prayers: List<WidgetPrayer>,
            nextPrayerName: String?,
            isCompact: Boolean
        ) {
            views.setViewVisibility(
                R.id.widget_prayer_list,
                if (isCompact) View.GONE else View.VISIBLE
            )
            val rowIds = listOf(
                Pair(R.id.row_name_1, R.id.row_time_1),
                Pair(R.id.row_name_2, R.id.row_time_2),
                Pair(R.id.row_name_3, R.id.row_time_3),
                Pair(R.id.row_name_4, R.id.row_time_4),
                Pair(R.id.row_name_5, R.id.row_time_5),
                Pair(R.id.row_name_6, R.id.row_time_6),
            )

            val accentColor = Color.parseColor("#15803D")
            val textColor = Color.parseColor("#2B241D")

            rowIds.forEachIndexed { index, ids ->
                val prayer = prayers.getOrNull(index)
                if (prayer == null) {
                    views.setTextViewText(ids.first, "")
                    views.setTextViewText(ids.second, "")
                } else {
                    views.setTextViewText(ids.first, prayer.displayName)
                    views.setTextViewText(ids.second, prayer.timeLabel)

                    val color = if (prayer.name == nextPrayerName) accentColor else textColor
                    views.setTextColor(ids.first, color)
                    views.setTextColor(ids.second, color)
                }
            }
        }

        private fun parsePrayers(json: String): List<WidgetPrayer> {
            val prayers = mutableListOf<WidgetPrayer>()
            val array = JSONArray(json)

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                prayers.add(
                    WidgetPrayer(
                        name = item.optString("name"),
                        isoTime = item.optString("time"),
                    )
                )
            }

            return prayers
        }

        private fun findNextPrayerName(prayers: List<WidgetPrayer>): String? {
            if (prayers.isEmpty()) return null

            val now = System.currentTimeMillis()
            val future = prayers.firstOrNull { it.timestamp >= now }
            return future?.name ?: prayers.first().name
        }

        private fun findActivePrayerName(prayers: List<WidgetPrayer>): String? {
            if (prayers.isEmpty()) return null

            val now = System.currentTimeMillis()
            val currentIndex = prayers.indexOfLast { it.timestamp <= now }
            if (currentIndex == -1) {
                return prayers.first().name
            }

            return prayers[currentIndex].name
        }

        private fun formatToday(): String {
            val formatter = SimpleDateFormat("d MMMM yyyy", Locale("tr", "TR"))
            return formatter.format(Date())
        }

        private fun isCompactWidget(options: Bundle): Boolean {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            return minWidth in 1..229
        }

        private fun formatRemaining(remainingMillis: Long): String {
            if (remainingMillis <= 0L) return "Şimdi"

            val totalMinutes = remainingMillis / 60000
            val days = totalMinutes / (24 * 60)
            val hours = (totalMinutes % (24 * 60)) / 60
            val minutes = totalMinutes % 60

            return when {
                days > 0 -> "${days}g ${hours}s ${minutes}dk"
                hours > 0 -> "${hours}s ${minutes}dk"
                else -> "${minutes}dk"
            }
        }

        private fun resolvePrayerHeaderColor(prayerName: String?): Int {
            val normalized = prayerName?.lowercase(Locale.ROOT) ?: return Color.parseColor("#C89B53")
            return when {
                normalized.contains("fajr") || normalized.contains("imsak") ->
                    Color.parseColor("#7DB7D9")
                normalized.contains("sunrise") || normalized.contains("gunes") ->
                    Color.parseColor("#E3B55F")
                normalized.contains("dhuhr") || normalized.contains("ogle") ->
                    Color.parseColor("#D7A93D")
                normalized.contains("asr") || normalized.contains("ikindi") ->
                    Color.parseColor("#D89245")
                normalized.contains("maghrib") || normalized.contains("aksam") ->
                    Color.parseColor("#C96C4B")
                normalized.contains("isha") || normalized.contains("yatsi") ->
                    Color.parseColor("#5E77C8")
                else -> Color.parseColor("#C89B53")
            }
        }
    }
}

data class WidgetPrayer(
    val name: String,
    val isoTime: String,
) {
    val timestamp: Long
        get() = try {
            OffsetDateTime.parse(isoTime)
                .toInstant()
                .toEpochMilli()
        } catch (_: Exception) {
            try {
                LocalDateTime.parse(isoTime)
                    .atZone(ZoneId.systemDefault())
                    .toInstant()
                    .toEpochMilli()
            } catch (_: Exception) {
                0L
            }
        }

    val remainingMillis: Long
        get() = (timestamp - System.currentTimeMillis()).coerceAtLeast(0L)

    val timeLabel: String
        get() = if (isoTime.length >= 16) isoTime.substring(11, 16) else "--:--"

    val displayName: String
        get() = when (name.lowercase(Locale.ROOT)) {
            "fajr" -> "İmsak"
            "sunrise" -> "Güneş"
            "dhuhr" -> "Öğle"
            "asr" -> "İkindi"
            "maghrib" -> "Akşam"
            "isha" -> "Yatsı"
            else -> name
        }
}
