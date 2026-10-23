package com.fillah.dompetku

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/// Membaca notifikasi pembayaran dari app yang dipantau. Jika Flutter sedang
/// mendengarkan, teks langsung diteruskan ke Dart untuk diparse. Jika app
/// tertutup, teks ditahan sebentar di [PendingNotificationStore] dan dihapus
/// begitu Dart mengambilnya.
class PaymentNotificationService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return
        if (!MONITORED_PACKAGES.contains(packageName)) return
        val extras = sbn.notification.extras ?: return
        val text = listOfNotNull(
            extras.getCharSequence(Notification.EXTRA_TITLE),
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT),
        ).joinToString(" ")
        if (text.isBlank()) return
        if (!PaymentNotificationBridge.emit(packageName, text, sbn.postTime)) {
            PendingNotificationStore.add(applicationContext, packageName, text, sbn.postTime)
        }
    }

    companion object {
        val MONITORED_PACKAGES = setOf(
            "id.co.bca.mobile",
            "com.gojek.gopay",
            "com.gojek.app",
            "com.shopee.id",
            "id.dana",
            "id.co.bri.brimo",
            "com.jago.digitalBanking",
            "ovo.id",
            "com.telkom.mwallet",
            "id.bmri.livin",
            "src.com.bni",
            "com.bsm.activity2",
            "com.bcadigital.blu",
            "id.co.bankbkemobile.digitalbank",
            "com.btpn.dc",
        )
    }
}

object PaymentNotificationBridge {
    var sink: ((String, String, Long) -> Unit)? = null

    /// Mengembalikan false bila tidak ada pendengar, supaya pemanggil
    /// menyimpannya ke antrean.
    fun emit(packageName: String, text: String, postTime: Long): Boolean {
        val current = sink ?: return false
        current(packageName, text, postTime)
        return true
    }
}

/// Antrean notifikasi yang masuk saat app tertutup. Dibatasi jumlah dan
/// umurnya, dan dikosongkan setiap kali Dart mengambilnya.
object PendingNotificationStore {
    private const val PREFS = "tally_pending_notifications"
    private const val KEY = "items"
    private const val MAX_ITEMS = 50
    private const val MAX_AGE_MS = 24L * 60 * 60 * 1000

    @Synchronized
    fun add(context: Context, packageName: String, text: String, postTime: Long) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val items = load(prefs.getString(KEY, null))
        items.put(
            JSONObject()
                .put("package", packageName)
                .put("text", text)
                .put("postTime", postTime),
        )
        val trimmed = JSONArray()
        val start = maxOf(0, items.length() - MAX_ITEMS)
        for (i in start until items.length()) trimmed.put(items.get(i))
        prefs.edit().putString(KEY, trimmed.toString()).apply()
    }

    @Synchronized
    fun drain(context: Context): List<Map<String, Any>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val items = load(prefs.getString(KEY, null))
        prefs.edit().remove(KEY).apply()
        val cutoff = System.currentTimeMillis() - MAX_AGE_MS
        val result = mutableListOf<Map<String, Any>>()
        for (i in 0 until items.length()) {
            val item = items.optJSONObject(i) ?: continue
            val postTime = item.optLong("postTime")
            if (postTime < cutoff) continue
            result.add(
                mapOf(
                    "package" to item.optString("package"),
                    "text" to item.optString("text"),
                    "postTime" to postTime,
                ),
            )
        }
        return result
    }

    private fun load(raw: String?): JSONArray =
        try {
            if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
}
