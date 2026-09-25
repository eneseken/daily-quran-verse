package com.muslim.pro

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.concurrent.TimeUnit

/**
 * Home screen widget showing today's Quran verse.
 *
 * Flutter (see lib/services/daily_verse_widget_service.dart) has no way to
 * run while the app is closed, so on every app open / language change it
 * pre-writes *both* today's and tomorrow's verse text into the widget's
 * shared prefs, tagged with the epoch-day today's verse was computed for.
 * Android then wakes this provider on its own roughly every 30 minutes
 * (the OS-enforced floor for updatePeriodMillis) and onUpdate below figures
 * out, purely from the device clock, whether "today" has rolled over to
 * the pre-computed "tomorrow" — so the widget flips at local midnight even
 * if the app never comes to the foreground that day.
 *
 * If the app stays closed for more than a day, the pre-computed window is
 * exhausted and the widget just holds on the last verse it has until the
 * app reopens and refills the window.
 *
 * The same call also mirrors the Customize screen's active wallpaper (and
 * its light/dark verse-text choice): Flutter writes a downscaled copy of
 * the selected theme photo to disk and hands over its path, which is
 * decoded straight into the widget's ImageView below.
 *
 * The widget is user-resizable (see resizeMode in
 * daily_verse_widget_info.xml) — the verse TextView uses autoSizeTextType
 * in the layout so its font grows for a short ayah and shrinks for a long
 * one within whatever box the current widget size gives it, and
 * onAppWidgetOptionsChanged below forces a redraw right after a resize so
 * launchers that don't already repaint the RemoteViews on their own still
 * pick up the new autosized font immediately rather than on the next
 * periodic update.
 */
class DailyVerseWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId -> updateWidget(context, appWidgetManager, widgetId, widgetData) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val todayEpochDay = TimeUnit.MILLISECONDS.toDays(System.currentTimeMillis())
        // Stored as a string on the Dart side (see DailyVerseWidgetService)
        // to dodge Int32/Int64 ambiguity in the platform channel codec.
        val storedEpochDay = widgetData.getString(KEY_TODAY_EPOCH_DAY, null)?.toLongOrNull() ?: -1L

        val useTomorrow = todayEpochDay == storedEpochDay + 1
        val verseText = if (useTomorrow) {
            widgetData.getString(KEY_TOMORROW_TEXT, null)
        } else {
            widgetData.getString(KEY_TODAY_TEXT, null)
        } ?: context.getString(R.string.widget_placeholder_text)
        val reference = if (useTomorrow) {
            widgetData.getString(KEY_TOMORROW_REFERENCE, null)
        } else {
            widgetData.getString(KEY_TODAY_REFERENCE, null)
        } ?: ""

        val darkText = widgetData.getString(KEY_DARK_TEXT, null) == "1"
        val backgroundPath = widgetData.getString(KEY_BACKGROUND_PATH, null)
        val backgroundBitmap = backgroundPath?.let {
            // A stale path (deleted file, app storage cleared) just falls
            // back to no photo rather than crashing the widget.
            runCatching { BitmapFactory.decodeFile(it) }.getOrNull()
        }

        val views = RemoteViews(context.packageName, R.layout.daily_verse_widget).apply {
            setTextViewText(R.id.widget_verse_text, verseText)
            setTextViewText(R.id.widget_verse_reference, reference)

            if (backgroundBitmap != null) {
                setImageViewBitmap(R.id.widget_background_image, backgroundBitmap)
                setViewVisibility(R.id.widget_background_image, View.VISIBLE)
                // Only override the text color from the layout's
                // theme-aware default (@color/widget_ink) when a photo is
                // actually showing behind it — the plain widget_background
                // fallback already contrasts correctly against that
                // default in both themes.
                setTextColor(
                    R.id.widget_verse_text,
                    if (darkText) DARK_INK else Color.WHITE,
                )
            } else {
                setViewVisibility(R.id.widget_background_image, View.GONE)
            }

            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_verse_text, pendingIntent)
            setOnClickPendingIntent(R.id.widget_verse_reference, pendingIntent)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    companion object {
        // Must match the keys written by DailyVerseWidgetService in Dart.
        private const val KEY_TODAY_TEXT = "daily_verse_today_text"
        private const val KEY_TODAY_REFERENCE = "daily_verse_today_reference"
        private const val KEY_TODAY_EPOCH_DAY = "daily_verse_today_epoch_day"
        private const val KEY_TOMORROW_TEXT = "daily_verse_tomorrow_text"
        private const val KEY_TOMORROW_REFERENCE = "daily_verse_tomorrow_reference"
        private const val KEY_DARK_TEXT = "daily_verse_dark_text"
        private const val KEY_BACKGROUND_PATH = "daily_verse_background_path"

        // Mirrors _Palette.body / the dark-text ink used on Customize tiles.
        private const val DARK_INK = 0xFF252320.toInt()
    }
}
