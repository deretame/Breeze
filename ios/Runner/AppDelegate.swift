import Flutter
import UIKit
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let memoryChannelName = "memory_monitor"
  private var memoryChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupMemoryChannel(pluginRegistry: engineBridge.pluginRegistry)
  }

  private func setupMemoryChannel(pluginRegistry: FlutterPluginRegistry) {
    if memoryChannel != nil {
      return
    }

    let registrar = pluginRegistry.registrar(forPlugin: memoryChannelName)
    let channel = FlutterMethodChannel(
      name: memoryChannelName,
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "AppDelegate deallocated", details: nil))
        return
      }

      switch call.method {
      case "getMemoryInfo":
        result(self.getMemoryInfo())
      case "getDartMemoryInfo":
        result(self.getDartMemoryInfo())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    memoryChannel = channel
  }

  private func getMemoryInfo() -> [String: Any] {
    let process = getProcessMemoryUsage()
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    let availableMemory = getAvailableMemory()

    return [
      "totalMemory": toInt64(totalMemory),
      "availableMemory": toInt64(availableMemory),
      "nativeHeapSize": toInt64(process.virtualSize),
      "nativeHeapAllocatedSize": toInt64(process.residentSize),
      "nativeHeapFreeSize": 0,
    ]
  }

  private func getDartMemoryInfo() -> [String: Any] {
    let process = getProcessMemoryUsage()
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    let usedMemory = process.residentSize
    let freeMemory = totalMemory > usedMemory ? totalMemory - usedMemory : 0

    return [
      "dartHeapUsed": toInt64(usedMemory),
      "dartHeapCapacity": toInt64(totalMemory),
      "dartHeapCommitted": toInt64(usedMemory),
      "externalMemory": toInt64(usedMemory),
      "maxMemory": toInt64(totalMemory),
      "totalMemory": toInt64(totalMemory),
      "freeMemory": toInt64(freeMemory),
      "usedMemory": toInt64(usedMemory),
      "nativeHeapSize": toInt64(process.virtualSize),
      "nativeHeapAllocated": toInt64(process.residentSize),
      "nativeHeapFree": 0,
      "processRss": toInt64(process.residentSize),
    ]
  }

  private func getAvailableMemory() -> UInt64 {
    var pageSize: vm_size_t = 0
    host_page_size(mach_host_self(), &pageSize)

    var vmStat = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
    )

    let result: kern_return_t = withUnsafeMutablePointer(to: &vmStat) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
        host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
      }
    }

    if result != KERN_SUCCESS {
      return 0
    }

    let freePages = UInt64(vmStat.free_count)
    let inactivePages = UInt64(vmStat.inactive_count)
    let speculativePages = UInt64(vmStat.speculative_count)
    return (freePages + inactivePages + speculativePages) * UInt64(pageSize)
  }

  private func getProcessMemoryUsage() -> (residentSize: UInt64, virtualSize: UInt64) {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<natural_t>.size
    )

    let result: kern_return_t = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), reboundPointer, &count)
      }
    }

    if result != KERN_SUCCESS {
      return (0, 0)
    }

    return (
      UInt64(info.resident_size),
      UInt64(info.virtual_size)
    )
  }

  private func toInt64(_ value: UInt64) -> Int64 {
    if value > UInt64(Int64.max) {
      return Int64.max
    }
    return Int64(value)
  }
}
