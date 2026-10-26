package vn.edu.vku.vku_expense_ocr

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.app.ActivityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — Entry point cho VKU Expense AI trên Android.
 *
 * Đăng ký MethodChannel "vn.edu.vku/device_info" để:
 * 1. getBatteryLevel   → Đọc mức pin hiện tại (%) qua BatteryManager.
 * 2. getDeviceInfo     → Trả về thông tin thiết bị (Model, SDK, OS version, RAM).
 * 3. triggerHaptic     → Kích hoạt rung phản hồi xúc giác (haptic feedback).
 *
 * Đây là minh họa thực tế cho Part 7 bài giảng:
 * "Platform Channels & Native Interoperability"
 * Sử dụng pattern Request–Response (MethodChannel).
 */
class MainActivity : FlutterActivity() {

    // Tên kênh giao tiếp — phải khớp chính xác bên Dart
    private val CHANNEL = "vn.edu.vku/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val level = getBatteryLevel()
                    if (level != -1) {
                        result.success(level)
                    } else {
                        result.error(
                            "UNAVAILABLE",
                            "Không thể đọc mức pin.",
                            null
                        )
                    }
                }

                "getDeviceInfo" -> {
                    result.success(getDeviceInfo())
                }

                "triggerHaptic" -> {
                    triggerHapticFeedback()
                    result.success(true)
                }

                else -> {
                    // Trả về notImplemented cho các method chưa hỗ trợ
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Đọc mức pin (%) thông qua BatteryManager system service.
     * Trả về giá trị 0-100 hoặc -1 nếu không đọc được.
     */
    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        } catch (e: Exception) {
            -1
        }
    }

    /**
     * Thu thập thông tin phần cứng thiết bị từ android.os.Build.
     * Trả về Map<String, String> để Dart nhận trực tiếp.
     */
    private fun getDeviceInfo(): Map<String, String> {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager?.getMemoryInfo(memInfo)
            val totalRamMB = memInfo.totalMem / (1024 * 1024)
            val availRamMB = memInfo.availMem / (1024 * 1024)

            mapOf(
                "model" to (Build.MODEL ?: "Unknown"),
                "manufacturer" to (Build.MANUFACTURER ?: "Unknown"),
                "brand" to (Build.BRAND ?: "Unknown"),
                "androidVersion" to (Build.VERSION.RELEASE ?: "Unknown"),
                "sdkInt" to Build.VERSION.SDK_INT.toString(),
                "product" to (Build.PRODUCT ?: "Unknown"),
                "hardware" to (Build.HARDWARE ?: "Unknown"),
                "totalRamMB" to totalRamMB.toString(),
                "availRamMB" to availRamMB.toString(),
                "securityPatch" to (Build.VERSION.SECURITY_PATCH ?: "N/A"),
            )
        } catch (e: Exception) {
            mapOf(
                "model" to (Build.MODEL ?: "Unknown"),
                "manufacturer" to (Build.MANUFACTURER ?: "Unknown"),
                "brand" to (Build.BRAND ?: "Unknown"),
                "androidVersion" to (Build.VERSION.RELEASE ?: "Unknown"),
                "sdkInt" to Build.VERSION.SDK_INT.toString(),
            )
        }
    }

    /**
     * Kích hoạt rung phản hồi xúc giác (haptic feedback) native.
     * Sử dụng VibrationEffect trên API 26+ hoặc Vibrator.vibrate() cho API cũ.
     * Thời gian rung: 50ms — đủ để người dùng cảm nhận khi quét hóa đơn thành công.
     */
    @Suppress("DEPRECATION")
    private fun triggerHapticFeedback() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // API 31+ — sử dụng VibratorManager
                val vibratorManager =
                    getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                val vibrator = vibratorManager?.defaultVibrator
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // API 26-30 — VibrationEffect
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                // API < 26 — deprecated vibrate(long)
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                vibrator?.vibrate(50)
            }
        } catch (e: Exception) {
            // Ignore haptic errors on restricted/budget devices
        }
    }
}
