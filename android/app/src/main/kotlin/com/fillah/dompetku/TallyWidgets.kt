package com.fillah.dompetku

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Widget 4x2: saldo bulan ini dan tombol catat cepat. Teks sudah diformat
/// (dan disamarkan bila perlu) di Dart lewat HomeWidgetService, jadi di sini
/// hanya ditampilkan. Diperbarui saat data berubah, bukan berkala.
class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_balance).apply {
                setTextViewText(R.id.widget_label, widgetData.getString("label", "Saldo bulan ini"))
                setTextViewText(R.id.widget_updated, widgetData.getString("updated", ""))
                setTextViewText(R.id.widget_balance, widgetData.getString("balance", "Rp ••••••"))
                setTextViewText(R.id.widget_income, widgetData.getString("income", ""))
                setTextViewText(R.id.widget_expense, widgetData.getString("expense", ""))
                setTextViewText(R.id.widget_add_expense, widgetData.getString("add_expense", "+ Pengeluaran"))
                setTextViewText(R.id.widget_add_income, widgetData.getString("add_income", "+ Pemasukan"))
                setOnClickPendingIntent(R.id.widget_root, launch(context, "tally://open"))
                setOnClickPendingIntent(R.id.widget_add_expense, launch(context, "tally://catat/expense"))
                setOnClickPendingIntent(R.id.widget_add_income, launch(context, "tally://catat/income"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/// Widget 2x2: persen anggaran bulan ini yang terpakai.
class BudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_budget).apply {
                setTextViewText(R.id.widget_budget_label, widgetData.getString("budget_label", "Anggaran"))
                setTextViewText(R.id.widget_budget_percent, widgetData.getString("budget_percent", "0%"))
                setTextViewText(R.id.widget_budget_caption, widgetData.getString("budget_caption", "terpakai"))
                setTextViewText(R.id.widget_budget_left, widgetData.getString("budget_left", ""))
                setProgressBar(R.id.widget_budget_bar, 100, progressOf(widgetData), false)
                setOnClickPendingIntent(R.id.widget_root, launch(context, "tally://anggaran"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/// Angka bisa tersimpan sebagai Int atau Long; getInt pada Long akan crash
/// dan widget tampil "Tidak dapat memuat widget".
private fun progressOf(widgetData: SharedPreferences): Int =
    ((widgetData.all["budget_progress"] as? Number)?.toInt() ?: 0).coerceIn(0, 100)

private fun launch(context: Context, uri: String) =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))
