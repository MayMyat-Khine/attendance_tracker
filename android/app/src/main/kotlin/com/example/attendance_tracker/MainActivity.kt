package com.example.attendance_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "request") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                requestPhotoAccess(result)
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        if (requestCode == REQUEST_PHOTO) {
            val result = pendingResult
            pendingResult = null
            result?.success(hasPhotoAccess())
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun requestPhotoAccess(result: MethodChannel.Result) {
        if (hasPhotoAccess()) {
            result.success(true)
            return
        }
        if (pendingResult != null) {
            result.success(false)
            return
        }
        pendingResult = result
        ActivityCompat.requestPermissions(this, arrayOf(photoPermission()), REQUEST_PHOTO)
    }

    private fun photoPermission(): String {
        return if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun hasPhotoAccess(): Boolean {
        val granted =
            ContextCompat.checkSelfPermission(this, photoPermission()) ==
                PackageManager.PERMISSION_GRANTED
        return granted || hasPartialPhotoAccess()
    }

    private fun hasPartialPhotoAccess(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return false
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED,
        ) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        private const val CHANNEL = "attendance_tracker/photo_permission"
        private const val REQUEST_PHOTO = 4101
    }
}
