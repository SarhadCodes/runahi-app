package com.rounahi.rounahi.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.rounahi.rounahi.MainActivity
import com.rounahi.rounahi.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

abstract class RounahiBaseWidget : HomeWidgetProvider() {
    abstract val layoutId: Int

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, layoutId)
            bind(views, widgetData)
            val deepLink = deepLink(widgetData)
            val pending = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(deepLink)
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    abstract fun bind(views: RemoteViews, data: SharedPreferences)
    abstract fun deepLink(data: SharedPreferences): String
}

class RounahiAyahWidget : RounahiBaseWidget() {
    override val layoutId = R.layout.widget_ayah
    override fun bind(views: RemoteViews, data: SharedPreferences) {
        views.setTextViewText(R.id.widget_brand, data.getString("brand", "رووناهى"))
        views.setTextViewText(R.id.widget_arabic, data.getString("ayah_arabic", "وَقُل رَّبِّ زِدْنِي عِلْمًا"))
        views.setTextViewText(R.id.widget_translation, data.getString("ayah_translation", ""))
    }
    override fun deepLink(data: SharedPreferences): String {
        val id = data.getString("ayah_id", "20-114")
        return "rounahi://app/verses/$id"
    }
}

class RounahiWordWidget : RounahiBaseWidget() {
    override val layoutId = R.layout.widget_word
    override fun bind(views: RemoteViews, data: SharedPreferences) {
        views.setTextViewText(R.id.widget_brand, data.getString("brand", "رووناهى"))
        views.setTextViewText(R.id.widget_arabic, data.getString("ayah_arabic", "عِلْم"))
        views.setTextViewText(R.id.widget_translation, data.getString("daily_message", ""))
    }
    override fun deepLink(data: SharedPreferences): String {
        val id = data.getString("word_id", "word-ilm")
        return "rounahi://app/words/$id"
    }
}

class RounahiTopicWidget : RounahiBaseWidget() {
    override val layoutId = R.layout.widget_topic
    override fun bind(views: RemoteViews, data: SharedPreferences) {
        views.setTextViewText(R.id.widget_brand, data.getString("brand", "رووناهى"))
        views.setTextViewText(R.id.widget_title, data.getString("topic_title", ""))
        views.setTextViewText(R.id.widget_translation, data.getString("daily_message", ""))
    }
    override fun deepLink(data: SharedPreferences): String {
        val id = data.getString("topic_id", "topic-ilm")
        return "rounahi://app/topics/$id"
    }
}

class RounahiLatestWidget : RounahiBaseWidget() {
    override val layoutId = R.layout.widget_latest
    override fun bind(views: RemoteViews, data: SharedPreferences) {
        views.setTextViewText(R.id.widget_brand, data.getString("brand", "رووناهى"))
        views.setTextViewText(R.id.widget_title, data.getString("latest_title", ""))
        views.setTextViewText(R.id.widget_translation, data.getString("latest_kind", ""))
    }
    override fun deepLink(data: SharedPreferences): String {
        val kind = data.getString("latest_kind", "topics")
        val id = data.getString("topic_id", "topic-ilm")
        return "rounahi://app/$kind/$id"
    }
}

class RounahiCompactWidget : RounahiBaseWidget() {
    override val layoutId = R.layout.widget_compact
    override fun bind(views: RemoteViews, data: SharedPreferences) {
        views.setTextViewText(R.id.widget_brand, data.getString("brand", "رووناهى"))
        views.setTextViewText(R.id.widget_arabic, data.getString("ayah_arabic", "رووناهى"))
    }
    override fun deepLink(data: SharedPreferences): String = "rounahi://app/home"
}
