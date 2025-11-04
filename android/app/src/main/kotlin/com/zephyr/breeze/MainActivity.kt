package com.zephyr.breeze

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "memory_monitor"

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
}
