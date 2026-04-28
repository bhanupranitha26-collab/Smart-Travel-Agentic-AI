package com.example.smart_travel_app

import android.Manifest
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "smart_travel_app/sms_permissions"
    private val requestCode = 4001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasReadSmsPermission" -> {
                        result.success(hasReadSmsPermission())
                    }

                    "requestReadSmsPermission" -> {
                        if (hasReadSmsPermission()) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.READ_SMS),
                                requestCode
                            )
                        }
                    }

                    "queryInboxSms" -> {
                        if (!hasReadSmsPermission()) {
                            result.error(
                                "permission_denied",
                                "READ_SMS permission not granted.",
                                null
                            )
                        } else {
                            val count = call.argument<Int>("count") ?: 80
                            result.success(queryInboxSms(count))
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == this.requestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }

    private fun hasReadSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun queryInboxSms(limit: Int): List<Map<String, Any?>> {
        val messages = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.ADDRESS
        )

        val cursor = contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            val idIndex = it.getColumnIndex(Telephony.Sms._ID)
            val bodyIndex = it.getColumnIndex(Telephony.Sms.BODY)
            val dateIndex = it.getColumnIndex(Telephony.Sms.DATE)
            val addressIndex = it.getColumnIndex(Telephony.Sms.ADDRESS)

            var count = 0
            while (it.moveToNext() && count < limit) {
                messages.add(
                    mapOf(
                        "id" to if (idIndex >= 0) it.getString(idIndex) else null,
                        "body" to if (bodyIndex >= 0) it.getString(bodyIndex) else null,
                        "date" to if (dateIndex >= 0) it.getLong(dateIndex) else null,
                        "address" to if (addressIndex >= 0) it.getString(addressIndex) else null
                    )
                )
                count += 1
            }
        }

        return messages
    }
}
