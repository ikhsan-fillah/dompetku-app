package com.fillah.dompetku

import android.content.ComponentName
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(messenger, "tally/payment_notifications").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val handler = Handler(Looper.getMainLooper())
                    PaymentNotificationBridge.sink = { packageName, text, postTime ->
                        handler.post {
                            events.success(
                                mapOf(
                                    "package" to packageName,
                                    "text" to text,
                                    "postTime" to postTime,
                                ),
                            )
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    PaymentNotificationBridge.sink = null
                }
            },
        )

        MethodChannel(messenger, "tally/notification_access").setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> {
                    val enabled = Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners",
                    )?.contains(
                        ComponentName(this, PaymentNotificationService::class.java).flattenToString(),
                    ) == true
                    result.success(enabled)
                }
                "openSettings" -> {
                    startActivity(android.content.Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
