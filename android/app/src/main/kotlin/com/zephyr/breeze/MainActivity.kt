package com.zephyr.breeze

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Debug
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import java.io.File
import java.util.UUID
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

        init {
            System.loadLibrary("windcore")
        }

        @JvmStatic
        private external fun initRustlsPlatformVerifier(context: Context)
    }

    private val CHANNEL = "memory_monitor"
    private val VOLUME_CHANNEL = "volume_key_handler"
    private val VOLUME_EVENT_CHANNEL = "volume_key_events"
    private val SYSTEM_UI_CHANNEL = "system_ui_control"
    private val REALSR_CHANNEL = "realsr_super_resolution"
    
    private var volumeKeyInterceptionEnabled = false
    private var volumeEventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initRustlsPlatformVerifier(applicationContext)
        super.onCreate(savedInstanceState)
    }

    override fun createFlutterFragment(): FlutterFragment {
        val shellArgs = FlutterShellArgs.fromIntent(intent)
        val forceEnableImpeller = isForceEnableImpeller()

        if (!forceEnableImpeller) {
            shellArgs.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
            Log.i(TAG, "Impeller is disabled by user setting on this device.")
        }

        if (forceEnableImpeller) {
            Log.i(TAG, "Impeller force-enable switch is ON. Keeping Impeller enabled.")
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
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_UI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hideSystemBars" -> {
                    setInstantSystemUiVisibility(immersive = true)
                    result.success(null)
                }
                "showSystemBars" -> {
                    setInstantSystemUiVisibility(immersive = false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REALSR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractAssets" -> {
                    val force = call.argument<Boolean>("force") ?: false
                    Thread {
                        try {
                            extractRealSrAssets(applicationContext, force)
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("EXTRACT_ERROR", e.message, e.stackTraceToString()) }
                        }
                    }.start()
                }
                "upscale" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    if (inputPath == null || outputPath == null) {
                        result.error("BAD_ARGS", "inputPath and outputPath are required", null)
                        return@setMethodCallHandler
                    }
                    val inputExtension = call.argument<String>("inputExtension") ?: "png"
                    val executable = call.argument<String>("executable") ?: "realcugan-ncnn"
                    val modelDir = call.argument<String>("modelDir") ?: "models-pro"
                    val scale = call.argument<Int>("scale") ?: 2
                    val noiseLevel = call.argument<Int>("noiseLevel") ?: -1
                    val tileSize = call.argument<Int>("tileSize") ?: 0
                    val syncGapMode = call.argument<Int>("syncGapMode") ?: 3
                    Thread {
                        try {
                            ensureRealSrAssetsExtracted(applicationContext)
                            val workDir = File(applicationContext.cacheDir, "realsr/${UUID.randomUUID()}")
                            val nativeLibDir = applicationInfo.nativeLibraryDir
                            val exeFile = File(nativeLibDir, executableToLibName(executable))
                            if (!exeFile.exists() || !exeFile.canExecute()) {
                                runOnUiThread { result.error("NOT_FOUND", "$executable (${exeFile.name}) not found or not executable in $nativeLibDir", null) }
                                return@Thread
                            }
                            File(outputPath).parentFile?.mkdirs()

                            // realcugan-ncnn 根据路径后缀判断图片格式，
                            // Dart 侧已通过文件头检测到真实扩展名并传进来。
                            val tempInput = File(workDir, "input_tmp.$inputExtension")
                            val tempOutput = File(workDir, "output_tmp.png")
                            File(inputPath).inputStream().use { input ->
                                tempInput.outputStream().use { output -> input.copyTo(output) }
                            }

                            val cmd = mutableListOf(
                                exeFile.absolutePath,
                                "-i", tempInput.absolutePath,
                                "-o", tempOutput.absolutePath,
                                "-m", modelDir,
                                "-s", scale.toString(),
                                "-n", noiseLevel.toString()
                            )
                            if (tileSize > 0) {
                                cmd.add("-t")
                                cmd.add(tileSize.toString())
                            }
                            if (syncGapMode in 0..3) {
                                cmd.add("-c")
                                cmd.add(syncGapMode.toString())
                            }
                            val pb = ProcessBuilder(cmd).apply {
                                directory(workDir)
                                environment()["LD_LIBRARY_PATH"] = nativeLibDir
                                redirectErrorStream(false)
                            }
                            val process = pb.start()
                            val stdout = process.inputStream.bufferedReader().use { it.readText() }
                            val stderr = process.errorStream.bufferedReader().use { it.readText() }
                            val exitCode = process.waitFor()

                            if (exitCode == 0 && tempOutput.exists()) {
                                tempOutput.inputStream().use { input ->
                                    File(outputPath).outputStream().use { output -> input.copyTo(output) }
                                }
                            }
                            tempInput.delete()
                            tempOutput.delete()
                            workDir.deleteRecursively()

                            runOnUiThread {
                                result.success(
                                    mapOf(
                                        "success" to (exitCode == 0),
                                        "exitCode" to exitCode,
                                        "outputPath" to outputPath,
                                        "stdout" to stdout,
                                        "stderr" to stderr
                                    )
                                )
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("UPSCALE_ERROR", e.message, e.stackTraceToString()) }
                        }
                    }.start()
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

    private fun executableToLibName(executable: String): String {
        return when (executable) {
            "realcugan-ncnn" -> "librealcugan_ncnn.so"
            "realsr-ncnn" -> "librealsr_ncnn.so"
            "waifu2x-ncnn" -> "libwaifu2x_ncnn.so"
            "srmd-ncnn" -> "libsrmd_ncnn.so"
            "mnnsr-ncnn" -> "libmnnsr_ncnn.so"
            "resize-ncnn" -> "libresize_ncnn.so"
            else -> "lib$executable.so"
        }
    }

    private fun ensureRealSrAssetsExtracted(context: Context) {
        val workDir = File(context.cacheDir, "realsr")
        val marker = File(workDir, ".extracted_v2")
        if (marker.exists()) {
            return
        }
        extractRealSrAssets(context, false)
    }

    private fun extractRealSrAssets(context: Context, force: Boolean) {
        val workDir = File(context.cacheDir, "realsr")
        val marker = File(workDir, ".extracted_v2")
        if (!force && marker.exists()) {
            return
        }
        Log.i("RealSR", "Extracting model assets to ${workDir.absolutePath}")
        if (workDir.exists()) {
            workDir.deleteRecursively()
        }
        workDir.mkdirs()
        val assetRoot = "flutter_assets/asset/realsr"
        val entries = context.assets.list(assetRoot) ?: emptyArray()
        for (entry in entries) {
            // 只复制模型目录和少量配置；可执行文件/动态库从 jniLibs 读取
            if (entry.startsWith("models-") || entry == "colors.xml" || entry == "delegates.xml") {
                // 直接把子项复制到 workDir，避免多出一层 realsr/ 目录
                copyAssetPath(context.assets, "$assetRoot/$entry", workDir)
            }
        }
        marker.createNewFile()
        Log.i("RealSR", "Model assets extraction finished")
    }

    private fun copyAssetPath(assetManager: android.content.res.AssetManager, assetPath: String, destDir: File) {
        val entries = assetManager.list(assetPath)
        if (entries == null || entries.isEmpty()) {
            val outFile = File(destDir, assetPath.substringAfterLast("/"))
            assetManager.open(assetPath).use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            }
            Log.d("RealSR", "Copied ${outFile.absolutePath}, size=${outFile.length()}")
        } else {
            val dir = File(destDir, assetPath.substringAfterLast("/"))
            dir.mkdirs()
            for (entry in entries) {
                copyAssetPath(assetManager, "$assetPath/$entry", dir)
            }
        }
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

    @Suppress("DEPRECATION")
    private fun setInstantSystemUiVisibility(immersive: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val controller = window.decorView.windowInsetsController ?: run {
                fallbackSystemUiVisibility(immersive)
                return
            }
            if (immersive) {
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            } else {
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_DEFAULT
                controller.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            }
            return
        }
        fallbackSystemUiVisibility(immersive)
    }

    @Suppress("DEPRECATION")
    private fun fallbackSystemUiVisibility(immersive: Boolean) {
        var flags = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        )
        if (immersive) {
            flags = flags or (
                View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE
            )
        }
        window.decorView.systemUiVisibility = flags
    }
}
