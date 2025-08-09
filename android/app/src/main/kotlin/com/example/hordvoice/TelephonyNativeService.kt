package com.example.hordvoice

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.provider.CallLog
import android.database.Cursor
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class TelephonyNativeService(private val context: Context, flutterEngine: FlutterEngine) {
    private val CHANNEL = "hordvoice/telephony"
    private val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

    init {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> sendSMS(call, result)
                "makeCall" -> makeCall(call, result)
                "getCallLog" -> getCallLog(result)
                "getPhoneState" -> getPhoneState(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun sendSMS(call: MethodCall, result: Result) {
        try {
            val phoneNumber = call.argument<String>("phoneNumber")
            val message = call.argument<String>("message")
            
            if (phoneNumber != null && message != null) {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                result.success("SMS envoyé avec succès")
            } else {
                result.error("INVALID_ARGUMENT", "Numéro ou message manquant", null)
            }
        } catch (e: Exception) {
            result.error("SMS_ERROR", "Erreur envoi SMS: ${e.message}", null)
        }
    }

    private fun makeCall(call: MethodCall, result: Result) {
        try {
            val phoneNumber = call.argument<String>("phoneNumber")
            
            if (phoneNumber != null) {
                val intent = Intent(Intent.ACTION_CALL)
                intent.data = Uri.parse("tel:$phoneNumber")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success("Appel initié")
            } else {
                result.error("INVALID_ARGUMENT", "Numéro de téléphone manquant", null)
            }
        } catch (e: Exception) {
            result.error("CALL_ERROR", "Erreur appel: ${e.message}", null)
        }
    }

    private fun getCallLog(result: Result) {
        try {
            val callList = mutableListOf<Map<String, Any>>()
            val cursor: Cursor? = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                null,
                null,
                null,
                CallLog.Calls.DATE + " DESC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val number = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                    val type = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE))
                    val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                    val duration = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))

                    val callInfo = mapOf(
                        "number" to number,
                        "type" to type,
                        "date" to date,
                        "duration" to duration
                    )
                    callList.add(callInfo)
                }
            }
            
            result.success(callList)
        } catch (e: Exception) {
            result.error("CALL_LOG_ERROR", "Erreur lecture journal: ${e.message}", null)
        }
    }

    private fun getPhoneState(result: Result) {
        try {
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            
            val phoneInfo = mapOf(
                "simState" to telephonyManager.simState,
                "networkOperatorName" to (telephonyManager.networkOperatorName ?: ""),
                "isNetworkRoaming" to telephonyManager.isNetworkRoaming
            )
            
            result.success(phoneInfo)
        } catch (e: Exception) {
            result.error("PHONE_STATE_ERROR", "Erreur état téléphone: ${e.message}", null)
        }
    }
}
