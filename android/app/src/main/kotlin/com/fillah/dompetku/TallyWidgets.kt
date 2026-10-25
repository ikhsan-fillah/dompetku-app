package com.fillah.dompetku

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.view.View
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

/// Widget 2x2: donat pengeluaran per kategori bulan ini dan 3 teratas.
/// Potongan donat dikirim dari Dart sebagai "AARRGGBB:pecahan;..." (urut
/// terbesar), lalu digambar sekali menjadi bitmap tiap data berubah.
class CategoryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val slices = parseSlices(widgetData.getString("cat_slices", "") ?: "")
        val sizePx = (84 * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
        val donut = drawDonut(sizePx, slices, context.resources.displayMetrics.density)
        val names = listOf(R.id.cat_name1, R.id.cat_name2, R.id.cat_name3)
        val dots = listOf(R.id.cat_dot1, R.id.cat_dot2, R.id.cat_dot3)
        val items = listOf(R.id.cat_item1, R.id.cat_item2, R.id.cat_item3)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_category).apply {
                setTextViewText(R.id.cat_label, widgetData.getString("cat_label", "Pengeluaran"))
                setTextViewText(R.id.cat_total, widgetData.getString("cat_total", ""))
                setTextViewText(R.id.cat_caption, widgetData.getString("cat_caption", ""))
                setImageViewBitmap(R.id.cat_donut, donut)
                for (i in 0 until 3) {
                    val name = widgetData.getString("cat_name${i + 1}", "") ?: ""
                    setViewVisibility(items[i], if (name.isEmpty()) View.INVISIBLE else View.VISIBLE)
                    setTextViewText(names[i], name)
                    slices.getOrNull(i)?.let { setInt(dots[i], "setColorFilter", it.first) }
                }
                setOnClickPendingIntent(R.id.widget_root, launch(context, "tally://open"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

private fun parseSlices(raw: String): List<Pair<Int, Float>> =
    raw.split(';').mapNotNull { part ->
        val bits = part.split(':')
        if (bits.size != 2) return@mapNotNull null
        val color = bits[0].toLongOrNull(16)?.toInt() ?: return@mapNotNull null
        val fraction = bits[1].toFloatOrNull() ?: return@mapNotNull null
        if (fraction <= 0f) null else color to fraction
    }

/// Cincin abu sebagai alas, lalu potongan per kategori dengan celah tipis.
private fun drawDonut(sizePx: Int, slices: List<Pair<Int, Float>>, density: Float): Bitmap {
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val stroke = 11f * density
    val inset = stroke / 2f
    val rect = RectF(inset, inset, sizePx - inset, sizePx - inset)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = stroke
    }
    paint.color = 0xFFEBE4D4.toInt()
    canvas.drawArc(rect, 0f, 360f, false, paint)
    val gap = if (slices.size > 1) 1.6f else 0f
    var start = -90f
    for ((color, fraction) in slices) {
        val sweep = 360f * fraction
        paint.color = color
        canvas.drawArc(rect, start + gap / 2, (sweep - gap).coerceAtLeast(0.5f), false, paint)
        start += sweep
    }
    return bitmap
}

/// Angka bisa tersimpan sebagai Int atau Long; getInt pada Long akan crash
/// dan widget tampil "Tidak dapat memuat widget".
private fun progressOf(widgetData: SharedPreferences): Int =
    ((widgetData.all["budget_progress"] as? Number)?.toInt() ?: 0).coerceIn(0, 100)

private fun launch(context: Context, uri: String) =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))
