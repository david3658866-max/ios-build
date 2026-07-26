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
                    "probeContacts" -> {
                        try {
                            result.success(probeContacts())
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

    private data class ContactPhoneEntry(
        var name: String,
        val phones: LinkedHashMap<String, String>,
    )

    /**
     * 多路径读取通讯录并按 CONTACT_ID 聚合多号码。
     * 1) Phone.CONTENT_URI
     * 2) 空则再查 Data + Phone MIME
     * 3) 再合并 SIM 卡 ADN（失败忽略，不阻断主流程）
     * 系统表 query 失败不立刻中断：先尽量合并 SIM；若最终仍空且系统表曾硬失败，再抛错给 Dart fallback。
     */
    private fun readContacts(): List<Map<String, Any?>> {
        val byId = LinkedHashMap<String, ContactPhoneEntry>()
        var phoneRows = 0
        var dataRows = 0
        var systemError: Exception? = null
        try {
            phoneRows =
                mergePhoneUri(
                    byId,
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    arrayOf(
                        ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ),
                    null,
                    null,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " COLLATE LOCALIZED ASC",
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                )
        } catch (e: Exception) {
            systemError = e
            android.util.Log.w("ContactsRead", "Phone.CONTENT_URI failed: ${e.message}")
        }
        if (byId.isEmpty()) {
            try {
                dataRows =
                    mergePhoneUri(
                        byId,
                        ContactsContract.Data.CONTENT_URI,
                        arrayOf(
                            ContactsContract.Data.CONTACT_ID,
                            ContactsContract.Data.DISPLAY_NAME,
                            ContactsContract.CommonDataKinds.Phone.NUMBER,
                        ),
                        "${ContactsContract.Data.MIMETYPE}=?",
                        arrayOf(ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE),
                        ContactsContract.Data.DISPLAY_NAME + " COLLATE LOCALIZED ASC",
                        ContactsContract.Data.CONTACT_ID,
                        ContactsContract.Data.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    )
                // Data 成功则不再把 Phone 失败当成总失败
                if (byId.isNotEmpty()) systemError = null
            } catch (e: Exception) {
                if (systemError == null) systemError = e
                android.util.Log.w("ContactsRead", "Data phone MIME failed: ${e.message}")
            }
        }
        val knownPhones = linkedSetOf<String>()
        for (entry in byId.values) {
            knownPhones.addAll(entry.phones.keys)
        }
        val simRows = mergeSimContacts(byId, knownPhones)
        val out =
            byId.map { (id, entry) ->
                val phones = entry.phones.values.toList()
                val name = entry.name.ifBlank { phones.firstOrNull().orEmpty() }
                mapOf(
                    "id" to id,
                    "name" to name,
                    "primaryPhone" to phones.firstOrNull().orEmpty(),
                    "phones" to phones,
                )
            }.filter { (it["phones"] as List<*>).isNotEmpty() }
        val probe = probeContacts()
        android.util.Log.i(
            "ContactsRead",
            "phoneRows=$phoneRows dataRows=$dataRows simRows=$simRows withPhone=${out.size} probe=$probe",
        )
        if (out.isEmpty() && systemError != null) {
            throw systemError
        }
        return out
    }

    /** 诊断：联系人表行数 / 电话表行数 / 权限，供 Dart 区分「真空」与「OEM 拦截」。 */
    private fun probeContacts(): Map<String, Any?> {
        val granted = isGranted(Manifest.permission.READ_CONTACTS)
        var contactCount = -1
        var phoneCount = -1
        var simCount = -1
        if (granted) {
            contactCount =
                countUri(ContactsContract.Contacts.CONTENT_URI) ?: -2
            phoneCount =
                countUri(ContactsContract.CommonDataKinds.Phone.CONTENT_URI) ?: -2
            simCount = probeSimContactCount()
        }
        return mapOf(
            "granted" to granted,
            "contactCount" to contactCount,
            "phoneCount" to phoneCount,
            "simCount" to simCount,
        )
    }

    private fun countUri(uri: android.net.Uri): Int? {
        contentResolver.query(uri, arrayOf("_id"), null, null, null)?.use { c ->
            return c.count
        }
        return null
    }

    /**
     * 读取 SIM ADN 并合并。不依赖 READ_PHONE_STATE：对常见 URI / subId 暴力尝试，
     * 任一失败忽略。已存在相同号码（系统表已有）则跳过，避免重复。
     */
    private fun mergeSimContacts(
        byId: LinkedHashMap<String, ContactPhoneEntry>,
        knownPhones: MutableSet<String>,
    ): Int {
        if (!isGranted(Manifest.permission.READ_CONTACTS)) return 0
        var added = 0
        for (uri in simAdnUris()) {
            try {
                added += mergeSimUri(uri, byId, knownPhones)
            } catch (e: SecurityException) {
                android.util.Log.w("ContactsRead", "SIM query denied uri=$uri: ${e.message}")
            } catch (e: Exception) {
                android.util.Log.w("ContactsRead", "SIM query fail uri=$uri: ${e.message}")
            }
        }
        return added
    }

    private fun simAdnUris(): List<android.net.Uri> {
        val list = ArrayList<android.net.Uri>()
        // 单卡经典路径
        list.add(android.net.Uri.parse("content://icc/adn"))
        // 部分双卡 / 厂商
        list.add(android.net.Uri.parse("content://icc0/adn"))
        list.add(android.net.Uri.parse("content://icc1/adn"))
        list.add(android.net.Uri.parse("content://iccmsim/adn"))
        // 按 subscriptionId 尝试（无需读卡槽权限）
        for (subId in 0..5) {
            list.add(android.net.Uri.parse("content://icc/adn/subId/$subId"))
        }
        return list
    }

    private fun probeSimContactCount(): Int {
        var total = 0
        var anyOk = false
        for (uri in simAdnUris()) {
            try {
                contentResolver.query(uri, arrayOf("_id"), null, null, null)?.use { c ->
                    anyOk = true
                    total += c.count
                }
            } catch (_: Exception) {
                // ignore
            }
        }
        return if (anyOk) total else -2
    }

    private fun mergeSimUri(
        uri: android.net.Uri,
        byId: LinkedHashMap<String, ContactPhoneEntry>,
        knownPhones: MutableSet<String>,
    ): Int {
        val cursor = contentResolver.query(uri, null, null, null, null) ?: return 0
        var added = 0
        cursor.use { c ->
            val nameIdx =
                listOf("name", "tag", "display_name")
                    .map { c.getColumnIndex(it) }
                    .firstOrNull { it >= 0 } ?: -1
            val numberIdx =
                listOf("number", "phone", "phone_number")
                    .map { c.getColumnIndex(it) }
                    .firstOrNull { it >= 0 } ?: -1
            if (numberIdx < 0) return 0
            val idIdx = c.getColumnIndex("_id")
            var row = 0
            while (c.moveToNext()) {
                row++
                val rawNumber = c.getString(numberIdx) ?: ""
                val digits = digitsOnly(rawNumber)
                if (digits.isEmpty()) continue
                val key = phoneDedupKey(digits)
                if (knownPhones.contains(key)) continue
                val preferred = phoneDedupKey(digits)
                val rawName =
                    if (nameIdx >= 0) c.getString(nameIdx)?.trim().orEmpty() else ""
                val rowId =
                    if (idIdx >= 0) c.getString(idIdx).orEmpty() else row.toString()
                val contactId = "sim:${uri.lastPathSegment}:$rowId:$key"
                val entry =
                    byId.getOrPut(contactId) {
                        ContactPhoneEntry(
                            name = rawName.ifBlank { preferred },
                            phones = LinkedHashMap(),
                        )
                    }
                if (entry.name.isBlank() || entry.name.all { it.isDigit() }) {
                    if (rawName.isNotBlank()) entry.name = rawName
                }
                entry.phones[key] = preferred
                knownPhones.add(key)
                added++
            }
        }
        if (added > 0) {
            android.util.Log.i("ContactsRead", "SIM merged uri=$uri added=$added")
        }
        return added
    }

    private fun mergePhoneUri(
        byId: LinkedHashMap<String, ContactPhoneEntry>,
        uri: android.net.Uri,
        projection: Array<String>,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
        idCol: String,
        nameCol: String,
        numberCol: String,
    ): Int {
        val cursor =
            contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)
                ?: throw IllegalStateException("contacts query returned null uri=$uri")
        var rawRows = 0
        cursor.use { c ->
            val idIdx = c.getColumnIndex(idCol)
            val nameIdx = c.getColumnIndex(nameCol)
            val numberIdx = c.getColumnIndex(numberCol)
            while (c.moveToNext()) {
                rawRows++
                val contactId = if (idIdx >= 0) c.getString(idIdx) ?: continue else continue
                val rawNumber = if (numberIdx >= 0) c.getString(numberIdx) ?: "" else ""
                val digits = digitsOnly(rawNumber)
                if (digits.isEmpty()) continue
                val key = phoneDedupKey(digits)
                val preferred = phoneDedupKey(digits)
                val rawName = if (nameIdx >= 0) c.getString(nameIdx)?.trim().orEmpty() else ""
                val entry =
                    byId.getOrPut(contactId) {
                        ContactPhoneEntry(
                            name = rawName.ifBlank { preferred },
                            phones = LinkedHashMap(),
                        )
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
        return rawRows
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
