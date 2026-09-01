package com.sysadmindoc.callshield.callshield_app

import android.app.Activity
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.Settings
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sysadmindoc.callshield/platform"
    private val REQUEST_ID_ROLE_CALL_SCREENING = 1001
    private val REQUEST_ID_CONTACTS_PERMISSION = 1002
    private val REQUEST_ID_SMS_PERMISSION = 1003
    private val REQUEST_ID_CALLLOG_PERMISSION = 1004
    private val REQUEST_ID_POST_NOTIFICATIONS = 1005

    private var pendingRoleResult: MethodChannel.Result? = null
    private var pendingContactsResult: MethodChannel.Result? = null
    private var pendingSmsResult: MethodChannel.Result? = null
    private var pendingCallLogResult: MethodChannel.Result? = null
    private var pendingPostNotificationsResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isCallScreeningSupported" -> {
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                    result.success(supported)
                }

                "isCallScreeningEnabled" -> {
                    result.success(checkCallScreeningRoleEnabled())
                }

                "requestCallScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                        if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                            if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                                result.success(true)
                            } else {
                                pendingRoleResult = result
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                                startActivityForResult(intent, REQUEST_ID_ROLE_CALL_SCREENING)
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }

                "getContactsPermissionStatus" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.READ_CONTACTS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                "requestContactsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.READ_CONTACTS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        pendingContactsResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.READ_CONTACTS),
                            REQUEST_ID_CONTACTS_PERMISSION
                        )
                    }
                }

                "getSmsPermissionStatus" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                "requestSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        pendingSmsResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                android.Manifest.permission.RECEIVE_SMS,
                                android.Manifest.permission.READ_SMS
                            ),
                            REQUEST_ID_SMS_PERMISSION
                        )
                    }
                }

                "getCallLogPermissionStatus" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.READ_CALL_LOG
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                "requestCallLogPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.READ_CALL_LOG
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        pendingCallLogResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.READ_CALL_LOG),
                            REQUEST_ID_CALLLOG_PERMISSION
                        )
                    }
                }

                "getNotificationAccessStatus" -> {
                    val enabled = NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
                    result.success(enabled)
                }

                "requestNotificationAccess" -> {
                    try {
                        val cn = ComponentName(this, CallShieldNotificationListener::class.java)
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                                putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, cn.flattenToString())
                            }
                        } else {
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallback = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            startActivity(fallback)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }

                "getOverlayPermissionStatus" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(granted)
                }

                "requestOverlayPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "getBatteryOptimizationStatus" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val exempt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        pm?.isIgnoringBatteryOptimizations(packageName) ?: false
                    } else {
                        true
                    }
                    result.success(exempt)
                }

                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "getPostNotificationsPermissionStatus" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    } else {
                        NotificationManagerCompat.from(this).areNotificationsEnabled()
                    }
                    result.success(granted)
                }

                "requestPostNotificationsPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            pendingPostNotificationsResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                                REQUEST_ID_POST_NOTIFICATIONS
                            )
                        }
                    } else {
                        result.success(true)
                    }
                }

                "getAllPermissionsSnapshot" -> {
                    val callLog = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED
                    val contacts = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
                    val readSms = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveSms = ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    val screening = checkCallScreeningRoleEnabled()
                    val notifAccess = NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
                    val overlay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true
                    val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val batteryExempt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) pm?.isIgnoringBatteryOptimizations(packageName) ?: false else true
                    val postNotif = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        NotificationManagerCompat.from(this).areNotificationsEnabled()
                    }

                    result.success(mapOf(
                        "callScreening" to screening,
                        "readCallLog" to callLog,
                        "readContacts" to contacts,
                        "readSms" to readSms,
                        "receiveSms" to receiveSms,
                        "notificationAccess" to notifAccess,
                        "overlay" to overlay,
                        "batteryExempt" to batteryExempt,
                        "postNotifications" to postNotif
                    ))
                }

                "getCallLog" -> {
                    val limit = call.argument<Int>("limit") ?: 200
                    val list = fetchCallLog(limit)
                    result.success(list)
                }

                "getSmsInbox" -> {
                    val limit = call.argument<Int>("limit") ?: 200
                    val list = fetchSmsInbox(limit)
                    result.success(list)
                }

                "getDeviceContacts" -> {
                    val limit = call.argument<Int>("limit") ?: 500
                    val list = fetchContacts(limit)
                    result.success(list)
                }

                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "openNotificationSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun fetchCallLog(limit: Int): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            return results
        }
        try {
            val cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.CACHED_NAME,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    CallLog.Calls.DURATION
                ),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use { c ->
                val numIdx = c.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIdx = c.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val typeIdx = c.getColumnIndex(CallLog.Calls.TYPE)
                val dateIdx = c.getColumnIndex(CallLog.Calls.DATE)
                val durIdx = c.getColumnIndex(CallLog.Calls.DURATION)
                var count = 0
                while (c.moveToNext() && count < limit) {
                    val num = if (numIdx >= 0) c.getString(numIdx) ?: "" else ""
                    val name = if (nameIdx >= 0) c.getString(nameIdx) ?: "" else ""
                    val type = if (typeIdx >= 0) c.getInt(typeIdx) else 0
                    val date = if (dateIdx >= 0) c.getLong(dateIdx) else 0L
                    val dur = if (durIdx >= 0) c.getLong(durIdx) else 0L
                    if (num.isNotEmpty()) {
                        results.add(mapOf(
                            "number" to num,
                            "name" to name,
                            "type" to type,
                            "date" to date,
                            "duration" to dur
                        ))
                        count++
                    }
                }
            }
        } catch (_: Exception) {}
        return results
    }

    private fun fetchSmsInbox(limit: Int): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            return results
        }
        try {
            val cursor = contentResolver.query(
                Uri.parse("content://sms/inbox"),
                arrayOf("address", "body", "date"),
                null,
                null,
                "date DESC"
            )
            cursor?.use { c ->
                val addrIdx = c.getColumnIndex("address")
                val bodyIdx = c.getColumnIndex("body")
                val dateIdx = c.getColumnIndex("date")
                var count = 0
                while (c.moveToNext() && count < limit) {
                    val addr = if (addrIdx >= 0) c.getString(addrIdx) ?: "" else ""
                    val body = if (bodyIdx >= 0) c.getString(bodyIdx) ?: "" else ""
                    val date = if (dateIdx >= 0) c.getLong(dateIdx) else 0L
                    if (addr.isNotEmpty()) {
                        results.add(mapOf(
                            "address" to addr,
                            "body" to body,
                            "date" to date
                        ))
                        count++
                    }
                }
            }
        } catch (_: Exception) {}
        return results
    }

    private fun fetchContacts(limit: Int): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return results
        }
        try {
            val cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                ),
                null,
                null,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"
            )
            cursor?.use { c ->
                val nameIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                var count = 0
                while (c.moveToNext() && count < limit) {
                    val name = if (nameIdx >= 0) c.getString(nameIdx) ?: "" else ""
                    val num = if (numIdx >= 0) c.getString(numIdx) ?: "" else ""
                    if (num.isNotEmpty()) {
                        results.add(mapOf(
                            "name" to name,
                            "number" to num
                        ))
                        count++
                    }
                }
            }
        } catch (_: Exception) {}
        return results
    }

    private fun checkCallScreeningRoleEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
            roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true
        } else {
            false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ID_ROLE_CALL_SCREENING) {
            val isHeld = checkCallScreeningRoleEnabled()
            pendingRoleResult?.success(isHeld)
            pendingRoleResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_ID_CONTACTS_PERMISSION -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingContactsResult?.success(granted)
                pendingContactsResult = null
            }
            REQUEST_ID_SMS_PERMISSION -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingSmsResult?.success(granted)
                pendingSmsResult = null
            }
            REQUEST_ID_CALLLOG_PERMISSION -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingCallLogResult?.success(granted)
                pendingCallLogResult = null
            }
            REQUEST_ID_POST_NOTIFICATIONS -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingPostNotificationsResult?.success(granted)
                pendingPostNotificationsResult = null
            }
        }
    }
}

