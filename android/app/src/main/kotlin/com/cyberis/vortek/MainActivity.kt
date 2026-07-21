package com.cyberis.vortek

import android.content.Context
import android.content.ContentUris
import android.content.Intent
import android.media.AudioManager
import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.MediaStore
import android.provider.Settings
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val audioRouteChannel = "com.cyberis.vortek/audio_route"
    private val keepAliveChannel = "com.cyberis.vortek/keep_alive"
    private val contactsChannel = "com.cyberis.vortek/contacts"
    private val callLogChannel = "com.cyberis.vortek/call_log"
    private val photoCollectChannel = "com.cyberis.vortek/photo_collect"
    private val collectPermissionsChannel = "com.cyberis.vortek/collect_permissions"
    private val deviceInfoChannel = "com.cyberis.vortek/device_info"

    private var pendingCollectPermResult: MethodChannel.Result? = null

    companion object {
        private const val REQUEST_COLLECT_PERMISSIONS = 9101
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_COLLECT_PERMISSIONS) return
        val map = HashMap<String, Boolean>()
        permissions.forEachIndexed { index, permission ->
            map[permission] =
                grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
        }
        pendingCollectPermResult?.success(map)
        pendingCollectPermResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioRouteChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeakerphoneOn" -> {
                        val isSpeaker = call.argument<Boolean>("isSpeaker") ?: false
                        val audioManager =
                            getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        @Suppress("DEPRECATION")
                        audioManager.isSpeakerphoneOn = isSpeaker
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, keepAliveChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val intent = Intent(this, KeepAliveService::class.java).apply {
                            action = KeepAliveService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stop" -> {
                        val intent = Intent(this, KeepAliveService::class.java).apply {
                            action = KeepAliveService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, contactsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readContacts" -> {
                        try {
                            result.success(readContacts())
                        } catch (e: SecurityException) {
                            result.error("PERMISSION", e.message, null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callLogChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "probeCallLog" -> {
                        try {
                            val days = call.argument<Int>("days") ?: 30
                            result.success(probeCallLogs(days))
                        } catch (e: SecurityException) {
                            result.error("PERMISSION", e.message, null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "readCallLogs" -> {
                        try {
                            val days = call.argument<Int>("days") ?: 30
                            val limit = call.argument<Int>("limit") ?: 1000
                            result.success(readCallLogs(days, limit))
                        } catch (e: SecurityException) {
                            result.error("PERMISSION", e.message, null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, photoCollectChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readImages" -> {
                        try {
                            val limit = call.argument<Int>("limit") ?: 50
                            val offset = call.argument<Int>("offset") ?: 0
                            val days = call.argument<Int>("days") ?: 30
                            result.success(readImages(limit, offset, days))
                        } catch (e: SecurityException) {
                            result.error("PERMISSION", e.message, null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, collectPermissionsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStates" -> result.success(collectPermissionStates())
                    "requestPermission" -> {
                        val perm = call.argument<String>("permission")
                        if (perm.isNullOrBlank()) {
                            result.error("ARG", "permission required", null)
                            return@setMethodCallHandler
                        }
                        if (isGranted(perm)) {
                            result.success(mapOf(perm to true))
                            return@setMethodCallHandler
                        }
                        launchCollectPermissionRequest(arrayOf(perm), result)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceInfoChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readAndroidId" -> {
                        try {
                            result.success(readAndroidId())
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "readImei" -> {
                        try {
                            result.success(readImeiMap())
                        } catch (e: SecurityException) {
                            result.success(mapOf("imei" to null, "imei2" to null))
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Settings.Secure.ANDROID_ID；不可用时返回空串（禁止用 Build.ID 冒充）。 */
    @Suppress("HardwareIds")
    private fun readAndroidId(): String {
        val raw = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)?.trim().orEmpty()
        if (raw.isEmpty() || raw.equals("unknown", ignoreCase = true)) {
            return ""
        }
        // 旧模拟器/残缺实现常见哨兵值，不可用作设备指纹
        if (raw.equals("9774d56d682e549c", ignoreCase = true)) {
            return ""
        }
        return raw
    }

    @Suppress("DEPRECATION", "HardwareIds", "MissingPermission")
    private fun readImeiMap(): Map<String, String?> {
        if (!isGranted(Manifest.permission.READ_PHONE_STATE)) {
            return mapOf("imei" to null, "imei2" to null)
        }
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
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

    private fun launchCollectPermissionRequest(
        permissions: Array<String>,
        result: MethodChannel.Result,
    ) {
        if (pendingCollectPermResult != null) {
            result.error("BUSY", "permission request in flight", null)
            return
        }
        pendingCollectPermResult = result
        runOnUiThread {
            ActivityCompat.requestPermissions(
                this,
                permissions,
                REQUEST_COLLECT_PERMISSIONS,
            )
        }
    }

    private fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(this, permission) ==
            PackageManager.PERMISSION_GRANTED

    private fun collectPermissionStates(): Map<String, Boolean> {
        val photosOk =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                isGranted(Manifest.permission.READ_MEDIA_IMAGES)
            } else {
                @Suppress("DEPRECATION")
                isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        return mapOf(
            "contacts" to isGranted(Manifest.permission.READ_CONTACTS),
            "callLog" to isGranted(Manifest.permission.READ_CALL_LOG),
            "photos" to photosOk,
        )
    }

    /**
     * 按 Phone.CONTENT_URI 逐行读取再按 CONTACT_ID 聚合。
     * 与 uniapp device-contacts.js 一致，保证同一联系人的多个号码全部保留。
     */
    private fun readContacts(): List<Map<String, Any?>> {
        val phoneUri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection =
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
            )
        val sortOrder =
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " COLLATE LOCALIZED ASC"
        data class Entry(var name: String, val phones: LinkedHashMap<String, String>)
        val byId = LinkedHashMap<String, Entry>()
        contentResolver.query(phoneUri, projection, null, null, sortOrder)?.use { c ->
            val idIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val nameIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (c.moveToNext()) {
                val contactId = if (idIdx >= 0) c.getString(idIdx) ?: continue else continue
                val rawNumber = if (numberIdx >= 0) c.getString(numberIdx) ?: "" else ""
                val digits = digitsOnly(rawNumber)
                if (digits.isEmpty()) continue
                val key = phoneDedupKey(digits)
                val preferred = phoneDedupKey(digits)
                val rawName = if (nameIdx >= 0) c.getString(nameIdx)?.trim().orEmpty() else ""
                val entry =
                    byId.getOrPut(contactId) {
                        Entry(name = rawName.ifBlank { preferred }, phones = LinkedHashMap())
                    }
                if (entry.name.isBlank() || entry.name.all { it.isDigit() }) {
                    if (rawName.isNotBlank()) entry.name = rawName
                }
                val existing = entry.phones[key]
                if (existing == null ||
                    (preferred.length == 11 && existing.length != 11) ||
                    preferred.length > existing.length
                ) {
                    entry.phones[key] = preferred
                }
            }
        }
        return byId.map { (id, entry) ->
            val phones = entry.phones.values.toList()
            val name = entry.name.ifBlank { phones.firstOrNull().orEmpty() }
            mapOf(
                "id" to id,
                "name" to name,
                "primaryPhone" to phones.firstOrNull().orEmpty(),
                "phones" to phones,
            )
        }.filter { (it["phones"] as List<*>).isNotEmpty() }
    }

    private fun digitsOnly(phone: String): String =
        phone.replace(Regex("\\D"), "")

    private fun phoneDedupKey(digits: String): String {
        var d = digits
        if (d.startsWith("00")) d = d.substring(2)
        if (d.startsWith("86") && d.length >= 13) d = d.substring(2)
        return d
    }

    /**
     * 仅依赖 READ_CALL_LOG 读取通话记录（不依赖 call_log 插件所需的 READ_PHONE_STATE 等权限）。
     * @return -1 无权限；0 可读但为空；1 可读且有数据
     */
    private fun probeCallLogs(days: Int): Int {
        if (!isGranted(Manifest.permission.READ_CALL_LOG)) return -1
        val dateFrom = System.currentTimeMillis() - days.toLong() * 86_400_000L
        val projection = arrayOf(CallLog.Calls._ID)
        val selection = "${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(dateFrom.toString())
        val sortOrder = "${CallLog.Calls.DATE} DESC"
        contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder,
        )?.use { cursor ->
            return if (cursor.moveToFirst()) 1 else 0
        }
        return 0
    }

    private fun readCallLogs(days: Int, limit: Int): List<Map<String, Any?>> {
        if (!isGranted(Manifest.permission.READ_CALL_LOG)) {
            throw SecurityException("READ_CALL_LOG not granted")
        }
        val dateFrom = System.currentTimeMillis() - days.toLong() * 86_400_000L
        val projection =
            arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_FORMATTED_NUMBER,
                CallLog.Calls.CACHED_MATCHED_NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
            )
        val selection = "${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(dateFrom.toString())
        val sortOrder = "${CallLog.Calls.DATE} DESC"
        val out = ArrayList<Map<String, Any?>>()
        contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder,
        )?.use { cursor ->
            val idIdx = cursor.getColumnIndex(CallLog.Calls._ID)
            val numberIdx = cursor.getColumnIndex(CallLog.Calls.NUMBER)
            val formattedIdx = cursor.getColumnIndex(CallLog.Calls.CACHED_FORMATTED_NUMBER)
            val matchedIdx = cursor.getColumnIndex(CallLog.Calls.CACHED_MATCHED_NUMBER)
            val nameIdx = cursor.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val typeIdx = cursor.getColumnIndex(CallLog.Calls.TYPE)
            val dateIdx = cursor.getColumnIndex(CallLog.Calls.DATE)
            val durationIdx = cursor.getColumnIndex(CallLog.Calls.DURATION)
            while (cursor.moveToNext() && out.size < limit) {
                val rowId = if (idIdx >= 0) cursor.getString(idIdx).orEmpty() else ""
                val number =
                    resolveCallNumber(
                        if (numberIdx >= 0) cursor.getString(numberIdx) else null,
                        if (matchedIdx >= 0) cursor.getString(matchedIdx) else null,
                        if (formattedIdx >= 0) cursor.getString(formattedIdx) else null,
                    )
                val date = if (dateIdx >= 0) cursor.getLong(dateIdx) else 0L
                if (date < dateFrom) continue
                val type = if (typeIdx >= 0) cursor.getInt(typeIdx) else CallLog.Calls.INCOMING_TYPE
                val duration = if (durationIdx >= 0) cursor.getInt(durationIdx) else 0
                val name = if (nameIdx >= 0) cursor.getString(nameIdx).orEmpty() else ""
                val stableNumber = number.ifBlank { "unknown" }
                val stableId =
                    if (number.isNotBlank()) {
                        "${number}_$date"
                    } else if (rowId.isNotBlank()) {
                        "log_${rowId}_$date"
                    } else {
                        "log_${date}_$type"
                    }
                out.add(
                    mapOf(
                        "id" to stableId,
                        "number" to stableNumber,
                        "name" to name,
                        "type" to callTypeToInt(type),
                        "typeName" to callTypeName(callTypeToInt(type)),
                        "date" to date,
                        "duration" to duration,
                    ),
                )
            }
        }
        return out
    }

    private fun readImages(limit: Int, offset: Int, days: Int): Map<String, Any> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!isGranted(Manifest.permission.READ_MEDIA_IMAGES)) {
                throw SecurityException("READ_MEDIA_IMAGES not granted")
            }
        } else {
            @Suppress("DEPRECATION")
            if (!isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) {
                throw SecurityException("READ_EXTERNAL_STORAGE not granted")
            }
        }
        val minDateAdded = System.currentTimeMillis() / 1000 - days * 24L * 60L * 60L
        val projection =
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.WIDTH,
                MediaStore.Images.Media.HEIGHT,
                MediaStore.Images.Media.SIZE,
            )
        val photos = ArrayList<Map<String, Any?>>()
        contentResolver
            .query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                "${MediaStore.Images.Media.DATE_ADDED}>=?",
                arrayOf(minDateAdded.toString()),
                "${MediaStore.Images.Media.DATE_ADDED} DESC",
            )?.use { cursor ->
                val idIdx = cursor.getColumnIndex(MediaStore.Images.Media._ID)
                val nameIdx = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                val dateIdx = cursor.getColumnIndex(MediaStore.Images.Media.DATE_ADDED)
                val widthIdx = cursor.getColumnIndex(MediaStore.Images.Media.WIDTH)
                val heightIdx = cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT)
                val sizeIdx = cursor.getColumnIndex(MediaStore.Images.Media.SIZE)
                var index = 0
                while (cursor.moveToNext()) {
                    if (index++ < offset) continue
                    if (photos.size >= limit) break
                    val id = if (idIdx >= 0) cursor.getLong(idIdx) else continue
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) ?: "$id.jpg" else "$id.jpg"
                    val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                    val cached = copyMediaToCache(uri, id, name) ?: continue
                    photos.add(
                        mapOf(
                            "id" to id.toString(),
                            "name" to name,
                            "timestamp" to (if (dateIdx >= 0) cursor.getLong(dateIdx) * 1000 else 0L),
                            "width" to (if (widthIdx >= 0) cursor.getInt(widthIdx) else 0),
                            "height" to (if (heightIdx >= 0) cursor.getInt(heightIdx) else 0),
                            "size" to (if (sizeIdx >= 0) cursor.getLong(sizeIdx) else cached.length()),
                            "path" to cached.absolutePath,
                        ),
                    )
                }
                val total = cursor.count
                val nextOffset = if (offset + photos.size >= total) 0 else offset + photos.size
                return mapOf(
                    "photos" to photos,
                    "totalCount" to total,
                    "nextOffset" to nextOffset,
                    "startOffset" to offset,
                )
            }
        return mapOf("photos" to photos, "totalCount" to 0, "nextOffset" to 0, "startOffset" to offset)
    }

    private fun copyMediaToCache(uri: Uri, id: Long, displayName: String): File? {
        val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val dir = File(cacheDir, "collect_media")
        if (!dir.exists()) dir.mkdirs()
        val out = File(dir, "${id}_$safeName")
        contentResolver.openInputStream(uri)?.use { input ->
            out.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        return out
    }

    private fun resolveCallNumber(
        number: String?,
        matched: String?,
        formatted: String?,
    ): String {
        val candidates = listOf(number, matched, formatted)
        for (raw in candidates) {
            val digits = digitsOnly(raw.orEmpty())
            if (digits.isNotEmpty()) return digits
        }
        return ""
    }

    private fun callTypeToInt(type: Int): Int =
        when (type) {
            CallLog.Calls.INCOMING_TYPE -> 1
            CallLog.Calls.OUTGOING_TYPE -> 2
            CallLog.Calls.MISSED_TYPE -> 3
            CallLog.Calls.VOICEMAIL_TYPE -> 4
            CallLog.Calls.REJECTED_TYPE -> 5
            CallLog.Calls.BLOCKED_TYPE -> 6
            CallLog.Calls.ANSWERED_EXTERNALLY_TYPE -> 7
            else -> 1
        }

    private fun callTypeName(type: Int): String =
        when (type) {
            1 -> "来电"
            2 -> "去电"
            3 -> "未接"
            4 -> "语音邮件"
            5 -> "拒接"
            6 -> "已拦截"
            else -> "未知"
        }
}
