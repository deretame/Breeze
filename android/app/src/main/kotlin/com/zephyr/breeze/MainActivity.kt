package com.zephyr.breeze

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Debug
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val TAG = "ImpellerConfig"
        private const val IMPELLER_CHANNEL = "impeller_config"
        private const val PREFS_NAME = "flutter_engine_config"
        private const val KEY_FORCE_ENABLE_IMPELLER = "force_enable_impeller"
    }

    private val CHANNEL = "memory_monitor"
    private val VOLUME_CHANNEL = "volume_key_handler"
    private val VOLUME_EVENT_CHANNEL = "volume_key_events"
    
    private var volumeKeyInterceptionEnabled = false
    private var volumeEventSink: EventChannel.EventSink? = null

    override fun createFlutterFragment(): FlutterFragment {
        val shellArgs = FlutterShellArgs.fromIntent(intent)
        val isAdreno800 = isAdreno800Series()
        val forceEnableImpeller = isForceEnableImpeller()

        if (isAdreno800 && !forceEnableImpeller) {
            // 针对该硬件强制回退到 Skia（禁用 Impeller）
            // Adreno 800 系列使用 IMR（立即模式渲染），而非 TBR（瓦片渲染）
            // 与 Impeller 的渲染路径组合时会出现明显性能下降
            shellArgs.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
            Log.w(TAG, "Adreno 800 series detected. Disabling Impeller to avoid IMR performance degradation.")
        }

        if (isAdreno800 && forceEnableImpeller) {
            Log.w(TAG, "Adreno 800 series detected, but force-enable switch is ON. Keeping Impeller enabled.")
        }

        return FlutterFragment.withNewEngine()
            .flutterShellArgs(shellArgs)
            .shouldAutomaticallyHandleOnBackPressed(true)
            .build()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemoryInfo" -> {
                    try {
                        val memoryInfo = getMemoryInfo()
                        result.success(memoryInfo)
                    } catch (e: Exception) {
                        result.error("MEMORY_ERROR", "Failed to get memory info", e.message)
                    }
                }
                "getDartMemoryInfo" -> {
                    try {
                        val dartMemoryInfo = getDartMemoryInfo()
                        result.success(dartMemoryInfo)
                    } catch (e: Exception) {
                        result.error("DART_MEMORY_ERROR", "Failed to get Dart memory info", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 音量键拦截 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableInterception" -> {
                    volumeKeyInterceptionEnabled = true
                    result.success(null)
                }
                "disableInterception" -> {
                    volumeKeyInterceptionEnabled = false
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 音量键事件 EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IMPELLER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setForceEnableImpeller" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    saveForceEnableImpeller(enable)
                    Log.i(TAG, "Updated force enable Impeller: $enable")
                    result.success(null)
                }
                "getForceEnableImpeller" -> {
                    result.success(isForceEnableImpeller())
                }
                "isImpellerForceEnableSupported" -> {
                    result.success(isAdreno800Series())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveForceEnableImpeller(enable: Boolean) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_FORCE_ENABLE_IMPELLER, enable)
            .apply()
    }

    private fun isForceEnableImpeller(): Boolean {
        return getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_FORCE_ENABLE_IMPELLER, false)
    }

    private fun getMemoryInfo(): Map<String, Long> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        // 获取应用的内存使用情况
        val memoryClass = activityManager.memoryClass
        val largeMemoryClass = activityManager.largeMemoryClass
        
        // 获取当前进程的内存使用
        val runtime = Runtime.getRuntime()
        val nativeHeapSize = Debug.getNativeHeapSize()
        val nativeHeapAllocatedSize = Debug.getNativeHeapAllocatedSize()
        val nativeHeapFreeSize = Debug.getNativeHeapFreeSize()

        return mapOf(
            "totalMemory" to memoryInfo.totalMem,
            "availableMemory" to memoryInfo.availMem,
            "threshold" to memoryInfo.threshold,
            "lowMemory" to if (memoryInfo.lowMemory) 1L else 0L,
            "memoryClass" to memoryClass.toLong() * 1024 * 1024, // Convert MB to bytes
            "largeMemoryClass" to largeMemoryClass.toLong() * 1024 * 1024,
            "maxMemory" to runtime.maxMemory(),
            "totalMemoryRuntime" to runtime.totalMemory(),
            "freeMemoryRuntime" to runtime.freeMemory(),
            "nativeHeapSize" to nativeHeapSize,
            "nativeHeapAllocatedSize" to nativeHeapAllocatedSize,
            "nativeHeapFreeSize" to nativeHeapFreeSize
        )
    }

    private fun getDartMemoryInfo(): Map<String, Long> {
        val runtime = Runtime.getRuntime()
        
        // 获取 Runtime 内存信息
        val maxMemory = runtime.maxMemory()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        
        // 获取进程内存信息
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processMemoryInfo = activityManager.getProcessMemoryInfo(intArrayOf(android.os.Process.myPid()))
        val pmi = if (processMemoryInfo.isNotEmpty()) processMemoryInfo[0] else null
        
        // 获取 Native 堆信息
        val nativeHeapSize = Debug.getNativeHeapSize()
        val nativeHeapAllocated = Debug.getNativeHeapAllocatedSize()
        val nativeHeapFree = Debug.getNativeHeapFreeSize()
        
        return mapOf(
            "dartHeapUsed" to usedMemory,
            "dartHeapCapacity" to maxMemory,
            "dartHeapCommitted" to totalMemory,
            "externalMemory" to nativeHeapAllocated,
            "maxMemory" to maxMemory,
            "totalMemory" to totalMemory,
            "freeMemory" to freeMemory,
            "usedMemory" to usedMemory,
            "nativeHeapSize" to nativeHeapSize,
            "nativeHeapAllocated" to nativeHeapAllocated,
            "nativeHeapFree" to nativeHeapFree,
            "processPss" to (pmi?.totalPss?.toLong()?.times(1024) ?: 0L), // Convert KB to bytes
            "processPrivateDirty" to (pmi?.totalPrivateDirty?.toLong()?.times(1024) ?: 0L),
            "processSharedDirty" to (pmi?.totalSharedDirty?.toLong()?.times(1024) ?: 0L)
        )
    }

    /**
     * 检测设备是否为 Adreno 800 系列 GPU（骁龙 8 Elite / Gen 5）。
     * 这类 GPU 使用 IMR（立即模式渲染），与 Impeller 组合时存在性能问题。
     *
     * 已知受影响 GPU：
     * - Adreno 830（骁龙 8 Elite，SM8750）
     * - Adreno 840（骁龙 8 Gen 5，SM8850，预期）
     */
    private fun isAdreno800Series(): Boolean {
        // 1. 优先检查严格的 SoC 型号（Android 12+）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val socModel = Build.SOC_MODEL ?: ""
            // SM8750 = 骁龙 8 Elite（Adreno 830）
            // SM8850 = 骁龙 8 Gen 5（Adreno 840，预期）
            if (socModel.contains("SM8750") || socModel.contains("SM8850")) {
                Log.d(TAG, "Detected Adreno 800 series via SOC_MODEL: $socModel")
                return true
            }
        }

        // 2. 回退检查硬件代号（兼容低版本或 SOC_MODEL 缺失场景）
        val hardware = Build.HARDWARE ?: ""
        // "sun" 是骁龙 8 Elite 的代号
        // "pakala" 也是已知代号之一
        if (hardware.equals("sun", ignoreCase = true) || hardware.equals("pakala", ignoreCase = true)) {
            Log.d(TAG, "Detected Adreno 800 series via HARDWARE: $hardware")
            return true
        }

        return false
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (volumeKeyInterceptionEnabled) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeEventSink?.success("volume_down")
                    return true // 拦截事件
                }
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeEventSink?.success("volume_up")
                    return true // 拦截事件
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
