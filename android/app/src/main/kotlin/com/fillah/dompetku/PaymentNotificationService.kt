package com.fillah.dompetku

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/// Membaca notifikasi pembayaran dari app yang dipantau. Teks hanya diteruskan
/// ke Dart untuk diparse; tidak pernah disimpan di sisi native.
class PaymentNotificationService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return
        if (!MONITORED_PACKAGES.contains(packageName)) return
        val extras = sbn.notification.extras ?: return
        val text = listOfNotNull(
            extras.getCharSequence(Notification.EXTRA_TITLE),
            extras.getCharSequence(Notification.EXTRA_TEXT),
        ).joinToString(" ")
        if (text.isBlank()) return
        PaymentNotificationBridge.emit(packageName, text, sbn.postTime)
    }

    companion object {
        val MONITORED_PACKAGES = setOf(
            "id.co.bca.mobile",
            "com.gojek.gopay",
            "com.gojek.app",
            "com.shopee.id",
            "id.dana",
        )
    }
}

object PaymentNotificationBridge {
    var sink: ((String, String, Long) -> Unit)? = null

    fun emit(packageName: String, text: String, postTime: Long) {
        sink?.invoke(packageName, text, postTime)
    }
}
