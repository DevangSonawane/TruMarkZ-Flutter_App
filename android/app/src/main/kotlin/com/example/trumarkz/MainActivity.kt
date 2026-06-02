package com.example.trumarkz

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.core.view.WindowCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  private val downloadsChannelName = "trumarkz/downloads"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    WindowCompat.setDecorFitsSystemWindows(window, false)
    window.statusBarColor = Color.TRANSPARENT
    window.navigationBarColor = Color.TRANSPARENT

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      window.isNavigationBarContrastEnforced = false
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "saveFileToDownloads" -> {
            val fileName = call.argument<String>("fileName")?.trim().orEmpty()
            val mimeType = call.argument<String>("mimeType")?.trim().orEmpty()
            val bytes = call.argument<ByteArray>("bytes")

            if (fileName.isEmpty() || bytes == null) {
              result.error("invalid_args", "Missing fileName or bytes", null)
              return@setMethodCallHandler
            }

            try {
              val contentResolver = applicationContext.contentResolver
              val displayName = fileName
              val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
              val values = android.content.ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(
                  MediaStore.MediaColumns.MIME_TYPE,
                  if (mimeType.isNotEmpty()) mimeType else "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                  put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/trumarkz_templates",
                  )
                  put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
              }

              val uri = contentResolver.insert(collection, values)
              if (uri == null) {
                result.error("save_failed", "Unable to create download entry", null)
                return@setMethodCallHandler
              }

              contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
              } ?: run {
                contentResolver.delete(uri, null, null)
                result.error("save_failed", "Unable to open output stream", null)
                return@setMethodCallHandler
              }

              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val finalizeValues = android.content.ContentValues().apply {
                  put(MediaStore.MediaColumns.IS_PENDING, 0)
                }
                contentResolver.update(uri, finalizeValues, null, null)
              }

              result.success(uri.toString())
            } catch (e: Exception) {
              result.error("save_failed", e.message, null)
            }
          }
          else -> result.notImplemented()
        }
      }
  }
}
