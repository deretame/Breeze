import Cocoa
import FlutterMacOS
import Darwin

@main
class AppDelegate: FlutterAppDelegate {
  private var activity: NSObjectProtocol?
  private var launchLockFD: Int32 = -1

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in NSApp.windows {
        if window.isMiniaturized {
          window.deminiaturize(self)
        } else if !window.isVisible {
          window.setIsVisible(true)
        }
        window.makeKeyAndOrderFront(self)
      }
      NSApp.activate(ignoringOtherApps: true)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if launchLockFD == -1 {
      let lockPath = (NSHomeDirectory() as NSString)
        .appendingPathComponent("Library/Application Support/Breeze/.launch.lock")
      let fileManager = FileManager.default
      let lockDir = (lockPath as NSString).deletingLastPathComponent

      if !fileManager.fileExists(atPath: lockDir) {
        try? fileManager.createDirectory(
          atPath: lockDir,
          withIntermediateDirectories: true,
          attributes: nil
        )
      }

      launchLockFD = open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
      if launchLockFD == -1 || flock(launchLockFD, LOCK_EX | LOCK_NB) != 0 {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        for app in runningApps where app.processIdentifier != getpid() {
          app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
          break
        }
        if launchLockFD != -1 {
          close(launchLockFD)
          launchLockFD = -1
        }
        NSApp.terminate(nil)
        return
      }
    }

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
