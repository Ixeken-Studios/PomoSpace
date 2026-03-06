package com.example.pomospace

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.pomospace/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                Thread {
                    val apps = getInstalledApps()
                    runOnUiThread {
                        result.success(apps)
                    }
                }.start()
            } else if (call.method == "launchApp") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val launched = launchApp(packageName)
                    result.success(launched)
                } else {
                    result.error("INVALID_ARGS", "Package name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val installedApps = mutableListOf<Map<String, Any>>()

        for (packageInfo in packages) {
            val launchIntent = pm.getLaunchIntentForPackage(packageInfo.packageName)
            if (launchIntent != null && packageInfo.packageName != packageName) {
                val appName = packageInfo.loadLabel(pm).toString()
                val icon = packageInfo.loadIcon(pm)
                val base64Icon = encodeToBase64(icon)

                val appData = mapOf(
                    "packageName" to packageInfo.packageName,
                    "appName" to appName,
                    "icon" to base64Icon
                )
                installedApps.add(appData)
            }
        }
        return installedApps.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun launchApp(packageName: String): Boolean {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            return true
        }
        return false
    }

    private fun encodeToBase64(drawable: Drawable): String {
        try {
            var bitmap: Bitmap? = null
            
            if (drawable is BitmapDrawable) {
                bitmap = drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
            
            if (bitmap != null) {
                val maxSize = 96
                val bWidth = bitmap.width
                val bHeight = bitmap.height
                
                var finalBitmap = bitmap
                if (bWidth > maxSize || bHeight > maxSize) {
                    val ratio = Math.min(maxSize.toFloat() / bWidth, maxSize.toFloat() / bHeight)
                    val newWidth = Math.round(ratio * bWidth)
                    val newHeight = Math.round(ratio * bHeight)
                    finalBitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
                }
                
                val outputStream = ByteArrayOutputStream()
                finalBitmap?.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                val byteArray = outputStream.toByteArray()
                return Base64.encodeToString(byteArray, Base64.NO_WRAP)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return ""
    }
}
