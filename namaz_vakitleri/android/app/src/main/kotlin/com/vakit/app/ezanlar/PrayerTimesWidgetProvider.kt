package com.vakit.app.ezanlar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId
import java.util.Date
import java.util.Locale

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_WIDGET_MINUTE_UPDATE,
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> updateAllWidgets(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextWidgetUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelWidgetUpdate(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        scheduleNextWidgetUpdate(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
        scheduleNextWidgetUpdate(context)
    }

    companion object {
        private const val PREFS_NAME = "prayer_widget"
        private const val KEY_CITY = "city"
        private const val KEY_DATE_LABEL = "date_label"
        private const val KEY_ACTIVE_PRAYER_NAME = "active_prayer_name"
        private const val KEY_PRAYERS_JSON = "prayers_json"
        private const val ACTION_WIDGET_MINUTE_UPDATE =
            "com.vakit.app.ezanlar.ACTION_WIDGET_MINUTE_UPDATE"
        private const val ONE_HOUR_MILLIS = 60 * 60 * 1000L
        private const val FINAL_STATIC_SECONDS_MILLIS = 10 * 1000L

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PrayerTimesWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            widgetIds.forEach { widgetId ->
                updateAppWidget(context, manager, widgetId)
            }
            scheduleNextWidgetUpdate(context)
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val city = prefs.getString(KEY_CITY, "Ezanlar") ?: "Ezanlar"
            val dateLabel = prefs.getString(KEY_DATE_LABEL, formatToday()) ?: formatToday()
            val storedActivePrayerName = prefs.getString(KEY_ACTIVE_PRAYER_NAME, null)
            val prayersJson = prefs.getString(KEY_PRAYERS_JSON, "[]") ?: "[]"
            val prayers = parsePrayers(prayersJson)
            val nextPrayerName = findNextPrayerName(prayers)
            val activePrayerName = findActivePrayerName(prayers) ?: storedActivePrayerName
            val nextPrayer = prayers.firstOrNull { it.name == nextPrayerName } ?: prayers.firstOrNull()
            val widgetOptions = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val isCompact = isCompactWidget(widgetOptions)
            val isSingleRowHeight = isSingleRowHeightWidget(widgetOptions)
            val isSingleColumnWidth = isSingleColumnWidthWidget(widgetOptions)
            val isTiny = isTinyWidget(widgetOptions)

            val layoutId = if (isTiny) {
                R.layout.prayer_times_widget_compact
            } else {
                R.layout.prayer_times_widget
            }
            val views = RemoteViews(context.packageName, layoutId)
            views.setTextViewText(R.id.widget_header_city, formatCityLabel(city))
            views.setTextViewText(R.id.widget_header_date, dateLabel)
            views.setViewVisibility(
                R.id.widget_header_city,
                if (isSingleRowHeight || isSingleColumnWidth || isTiny) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.widget_header_container,
                if (isSingleRowHeight || isSingleColumnWidth || isTiny) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.widget_header_date,
                if (isSingleRowHeight || isSingleColumnWidth || isTiny) View.GONE else View.VISIBLE
            )
            if (!isTiny) {
                views.setImageViewResource(
                    R.id.widget_header_background,
                    resolvePrayerHeaderBackground(activePrayerName ?: nextPrayerName)
                )
            }

            bindNextPrayerCard(views, nextPrayer, isCompact, isTiny)
            bindPrayerRows(views, prayers, nextPrayerName, isCompact || isTiny)
            applyTextSizing(views, isSingleRowHeight, isTiny)
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
            isCompact: Boolean,
            isTiny: Boolean
        ) {
            val remainingMillis = nextPrayer?.remainingMillis ?: 0L
            val showLiveSeconds = remainingMillis > FINAL_STATIC_SECONDS_MILLIS &&
                remainingMillis < ONE_HOUR_MILLIS

            views.setTextViewText(
                R.id.widget_next_name,
                if (isTiny) {
                    nextPrayer?.let { formatRemainingLabel(it.displayName) } ?: "Vakit yok"
                } else {
                    nextPrayer?.let { "${it.displayName} vaktine" } ?: "Vakit yok"
                }
            )
            if (showLiveSeconds) {
                views.setChronometer(
                    R.id.widget_next_time,
                    SystemClock.elapsedRealtime() + remainingMillis,
                    null,
                    true
                )
                views.setChronometerCountDown(R.id.widget_next_time, true)
            } else {
                views.setChronometerCountDown(R.id.widget_next_time, false)
                views.setChronometer(
                    R.id.widget_next_time,
                    SystemClock.elapsedRealtime(),
                    null,
                    false
                )
                views.setTextViewText(
                    R.id.widget_next_time,
                    nextPrayer?.let { formatRemainingStyled(it.remainingMillis) } ?: "--"
                )
            }
            views.setViewVisibility(R.id.widget_next_name, View.VISIBLE)
            views.setViewVisibility(
                R.id.widget_countdown,
                if (isTiny) View.GONE else View.VISIBLE
            )
            views.setTextViewText(
                R.id.widget_countdown,
                nextPrayer?.let { "Saat ${it.timeLabel} ${it.displayName} vakti" } ?: "Saat --:--"
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

        private fun applyTextSizing(
            views: RemoteViews,
            isSingleRowHeight: Boolean,
            isTiny: Boolean
        ) {
            when {
                isTiny -> {
                    views.setTextViewTextSize(R.id.widget_next_name, TypedValue.COMPLEX_UNIT_SP, 11f)
                    views.setTextViewTextSize(R.id.widget_next_time, TypedValue.COMPLEX_UNIT_SP, 22f)
                }
                isSingleRowHeight -> {
                    views.setTextViewTextSize(R.id.widget_next_name, TypedValue.COMPLEX_UNIT_SP, 17f)
                    views.setTextViewTextSize(R.id.widget_next_time, TypedValue.COMPLEX_UNIT_SP, 24f)
                    views.setTextViewTextSize(R.id.widget_countdown, TypedValue.COMPLEX_UNIT_SP, 11f)
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

        private fun formatCityLabel(city: String): String {
            val locale = Locale("tr", "TR")
            val normalized = city.trim().lowercase(locale)
            if (normalized.isEmpty()) return city
            return normalized.replaceFirstChar { char ->
                if (char.isLowerCase()) char.titlecase(locale) else char.toString()
            }
        }

        private fun isCompactWidget(options: Bundle): Boolean {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return minHeight in 1..140 || minWidth in 1..260
        }

        private fun isSingleRowHeightWidget(options: Bundle): Boolean {
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return minHeight in 1..110
        }

        private fun isSingleColumnWidthWidget(options: Bundle): Boolean {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            return minWidth in 1..180
        }

        private fun isTinyWidget(options: Bundle): Boolean {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return minWidth in 1..180 && minHeight in 1..180
        }

        private fun formatRemaining(remainingMillis: Long): String {
            if (remainingMillis <= 0L) return "Şimdi"

            val totalSeconds = remainingMillis / 1000
            val totalMinutes = remainingMillis / 60000
            val days = totalMinutes / (24 * 60)
            val hours = (totalMinutes % (24 * 60)) / 60
            val minutes = totalMinutes % 60
            val seconds = totalSeconds % 60

            return when {
                days > 0 -> "${days}g ${hours}s ${minutes}dk"
                hours > 0 -> "${hours}s ${minutes}dk"
                totalMinutes > 0 -> "${minutes}dk ${seconds}sn"
                else -> "${seconds}sn"
            }
        }

        private fun formatRemainingStyled(remainingMillis: Long): CharSequence {
            val text = if (remainingMillis <= FINAL_STATIC_SECONDS_MILLIS) {
                formatFinalSeconds(remainingMillis)
            } else {
                formatRemaining(remainingMillis)
            }
            val styled = SpannableString(text)
            val unitRegex = Regex("(?<=\\d)(g|s|dk|sn)")

            unitRegex.findAll(text).forEach { match ->
                styled.setSpan(
                    RelativeSizeSpan(0.62f),
                    match.range.first,
                    match.range.last + 1,
                    Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
            }

            return styled
        }

        private fun formatFinalSeconds(remainingMillis: Long): String {
            if (remainingMillis <= 0L) return "0sn"
            val seconds = ((remainingMillis - 1) / 1000L) + 1L
            return "${seconds}sn"
        }

        private fun formatRemainingLabel(displayName: String): String {
            return when (displayName) {
                "İmsak" -> "İmsaka kalan"
                "Güneş" -> "Güneşe kalan"
                "Öğle" -> "Öğleye kalan"
                "İkindi" -> "İkindiye kalan"
                "Akşam" -> "Akşama kalan"
                "Yatsı" -> "Yatsıya kalan"
                else -> "$displayName kalan"
            }
        }

        private fun resolvePrayerHeaderBackground(prayerName: String?): Int {
            val normalized = prayerName?.lowercase(Locale.ROOT)
                ?: return R.drawable.prayer_widget_header_default
            return when {
                normalized.contains("fajr") || normalized.contains("imsak") ->
                    R.drawable.prayer_widget_header_imsak
                normalized.contains("sunrise") || normalized.contains("gunes") ->
                    R.drawable.prayer_widget_header_gunes
                normalized.contains("dhuhr") || normalized.contains("ogle") ->
                    R.drawable.prayer_widget_header_ogle
                normalized.contains("asr") || normalized.contains("ikindi") ->
                    R.drawable.prayer_widget_header_ikindi
                normalized.contains("maghrib") || normalized.contains("aksam") ->
                    R.drawable.prayer_widget_header_aksam
                normalized.contains("isha") || normalized.contains("yatsi") ->
                    R.drawable.prayer_widget_header_yatsi
                else -> R.drawable.prayer_widget_header_default
            }
        }

        private fun scheduleNextWidgetUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val now = System.currentTimeMillis()
            val nextPrayer = getNextPrayer(context)
            val updateAt = if (
                nextPrayer != null &&
                nextPrayer.remainingMillis in 1 until ONE_HOUR_MILLIS
            ) {
                ((now / 1000) + 1) * 1000
            } else {
                ((now / 60000) + 1) * 60000
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                updateAt,
                widgetUpdatePendingIntent(context)
            )
        }

        private fun cancelWidgetUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            alarmManager.cancel(widgetUpdatePendingIntent(context))
        }

        private fun getNextPrayer(context: Context): WidgetPrayer? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val prayersJson = prefs.getString(KEY_PRAYERS_JSON, "[]") ?: "[]"
            val prayers = parsePrayers(prayersJson)
            val nextPrayerName = findNextPrayerName(prayers)
            return prayers.firstOrNull { it.name == nextPrayerName } ?: prayers.firstOrNull()
        }

        private fun widgetUpdatePendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                action = ACTION_WIDGET_MINUTE_UPDATE
            }
            return PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
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
