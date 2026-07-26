package com.cyberis.vortek.deviceid

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Standard Flutter plugin for device fingerprint channel.
 * Survives antivirus shells that replace/break MainActivity handlers.
 * Channel name must stay: com.cyberis.vortek/device_info
 */
class ImDeviceIdPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = appContext
        if (ctx == null) {
            result.error("NO_CONTEXT", "plugin not attached", null)
            return
        }
        when (call.method) {
            "readAndroidId" -> {
                try {
                    result.success(readAndroidId(ctx))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "readOrCreateAndroidHardwareId" -> {
                try {
                    result.success(readOrCreateAndroidAppGenId(ctx))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "readImei" -> {
                try {
                    result.success(readImeiMap(ctx))
                } catch (e: SecurityException) {
                    result.success(mapOf("imei" to null, "imei2" to null))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.cyberis.vortek/device_info"
    }

    @Suppress("HardwareIds")
    private fun readAndroidId(context: Context): String {
        val raw = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID,
        )?.trim().orEmpty()
        if (raw.isEmpty() || raw.equals("unknown", ignoreCase = true)) {
            return ""
        }
        if (raw.equals("9774d56d682e549c", ignoreCase = true)) {
            return ""
        }
        if (raw.equals("0000000000000000", ignoreCase = true) ||
            raw.equals("ffffffffffffffff", ignoreCase = true)
        ) {
            return ""
        }
        if (raw.matches(Regex("(?i)^[A-Z]{2,}\\d[A-Z0-9]*(\\.[0-9A-Z]+)+$"))) {
            return ""
        }
        if (raw.length < 8) {
            return ""
        }
        if (raw.matches(Regex("(?i)^([0-9A-F])\\1{7,}$"))) {
            return ""
        }
        return raw
    }

    private fun readOrCreateAndroidAppGenId(context: Context): String {
        val prefs = context.getSharedPreferences("vortek_device", Context.MODE_PRIVATE)
        val key = "appgen_hardware_id"
        val existing = prefs.getString(key, null)?.trim().orEmpty()
        if (isUsableAppGenId(existing)) {
            return existing
        }
        if (existing.isNotEmpty()) {
            android.util.Log.w("DeviceId", "discard corrupt appgen id, regenerating")
        }
        val fresh = "appgen:" + java.util.UUID.randomUUID().toString()
        prefs.edit().putString(key, fresh).apply()
        android.util.Log.w("DeviceId", "ANDROID_ID unusable, using appgen fallback")
        return fresh
    }

    private fun isUsableAppGenId(raw: String): Boolean {
        if (!raw.startsWith("appgen:", ignoreCase = true)) return false
        val rest = raw.substring(7)
        return rest.matches(
            Regex("(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"),
        )
    }

    @Suppress("DEPRECATION", "HardwareIds", "MissingPermission")
    private fun readImeiMap(context: Context): Map<String, String?> {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_PHONE_STATE,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return mapOf("imei" to null, "imei2" to null)
        }
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        fun normalize(value: String?): String? {
            val v = value?.trim().orEmpty()
            return v.ifBlank { null }
        }
        val imei1 =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    normalize(tm.imei)
                } catch (_: SecurityException) {
                    null
                } catch (_: Exception) {
                    null
                }
            } else {
                try {
                    normalize(tm.deviceId)
                } catch (_: SecurityException) {
                    null
                } catch (_: Exception) {
                    null
                }
            }
        val imei2 =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    normalize(tm.getImei(1))
                } catch (_: Exception) {
                    null
                }
            } else {
                null
            }
        return mapOf("imei" to imei1, "imei2" to imei2)
    }
}
