package com.dailyenglishquest.app

import android.content.res.AssetManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val MODEL_CHANNEL = "com.dailyenglishquest/model"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MODEL_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "extractModel") {
                    val assetPath = call.argument<String>("assetPath") ?: ""
                    val outputPath = call.argument<String>("outputPath") ?: ""

                    try {
                        val outputFile = File(outputPath)
                        if (outputFile.exists()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        outputFile.parentFile?.mkdirs()
                        val inputStream = assets.open(assetPath, AssetManager.ACCESS_STREAMING)
                        val outputStream = FileOutputStream(outputFile)
                        val buffer = ByteArray(8192)
                        var bytesRead: Int
                        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                            outputStream.write(buffer, 0, bytesRead)
                        }
                        outputStream.close()
                        inputStream.close()

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
