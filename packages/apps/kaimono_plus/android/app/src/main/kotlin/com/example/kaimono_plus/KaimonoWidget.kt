package com.example.kaimono_plus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class KaimonoWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val items = decodeItems(widgetData.getString(itemsKey, null))
            val emptyMessage = widgetData.getString(emptyMessageKey, null).orEmpty()
            val views = RemoteViews(context.packageName, R.layout.kaimono_widget).apply {
                val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.kaimono_widget_container, launchIntent)

                setTextViewText(
                    R.id.kaimono_widget_title,
                    widgetData.getString(titleKey, null)?.takeIf { it.isNotBlank() }
                        ?: "買うものリスト",
                )
                setTextViewText(R.id.kaimono_widget_updated_at, widgetData.getString(updatedAtKey, null).orEmpty())

                if (items.isEmpty()) {
                    setViewVisibility(R.id.kaimono_widget_items, View.GONE)
                    setViewVisibility(R.id.kaimono_widget_empty, View.VISIBLE)
                    setTextViewText(
                        R.id.kaimono_widget_empty,
                        emptyMessage.ifBlank { "表示する買うものがありません" },
                    )
                } else {
                    setViewVisibility(R.id.kaimono_widget_items, View.VISIBLE)
                    setViewVisibility(R.id.kaimono_widget_empty, View.GONE)
                }

                itemViewIds.forEachIndexed { index, viewId ->
                    val item = items.getOrNull(index)
                    if (item == null) {
                        setViewVisibility(viewId, View.GONE)
                    } else {
                        setViewVisibility(viewId, View.VISIBLE)
                        setTextViewText(viewId, "○ $item")
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun decodeItems(rawItems: String?): List<String> {
        if (rawItems.isNullOrBlank()) return emptyList()

        return runCatching {
            val jsonArray = JSONArray(rawItems)
            List(jsonArray.length()) { index -> jsonArray.optString(index) }
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .take(itemViewIds.size)
        }.getOrDefault(emptyList())
    }

    companion object {
        private const val titleKey = "kaimono_widget_title"
        private const val itemsKey = "kaimono_widget_items"
        private const val updatedAtKey = "kaimono_widget_updated_at"
        private const val emptyMessageKey = "kaimono_widget_empty_message"

        private val itemViewIds = listOf(
            R.id.kaimono_widget_item_1,
            R.id.kaimono_widget_item_2,
            R.id.kaimono_widget_item_3,
            R.id.kaimono_widget_item_4,
            R.id.kaimono_widget_item_5,
            R.id.kaimono_widget_item_6,
            R.id.kaimono_widget_item_7,
            R.id.kaimono_widget_item_8,
        )
    }
}
