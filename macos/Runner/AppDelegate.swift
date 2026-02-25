import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var activity: NSObjectProtocol?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        for window in NSApp.windows {
            if !window.isVisible {
                window.setIsVisible(true)
            }
            window.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // mainWindow 可能还未就绪，回退到遍历所有 window
    guard let controller = (NSApp.mainWindow?.contentViewController
        ?? NSApp.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController) as? FlutterViewController else {
      super.applicationDidFinishLaunching(notification)
      return
    }
    let channel = FlutterMethodChannel(name: "com.breeze.macos/activity", binaryMessenger: controller.engine.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "startActivity":
        self?.startActivity(result: result)
      case "stopActivity":
        self?.stopActivity(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  private func startActivity(result: @escaping FlutterResult) {
    if activity == nil {
      activity = ProcessInfo.processInfo.beginActivity(
        options: [
          .userInitiated,
          .idleSystemSleepDisabled,
          .suddenTerminationDisabled
        ],
        reason: "正在后台同步/下载漫画"
      )
    }
    result(true)
  }

  private func stopActivity(result: @escaping FlutterResult) {
    if let activity = activity {
      ProcessInfo.processInfo.endActivity(activity)
      self.activity = nil
    }
    result(true)
  }
}
