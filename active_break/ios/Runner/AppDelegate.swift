import Flutter
import UIKit
import BackgroundTasks
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var flutterMethodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 设置Flutter方法通道
    let controller = window?.rootViewController as! FlutterViewController
    flutterMethodChannel = FlutterMethodChannel(
      name: "com.activebreak/background_reminder",
      binaryMessenger: controller.binaryMessenger
    )
    
    // 设置方法通道处理器
    flutterMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call: call, result: result)
    }
    
    // 请求通知权限
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted {
        print("通知权限已授予")
      } else {
        print("通知权限被拒绝: \(error?.localizedDescription ?? "未知错误")")
      }
    }
    
    // 注册后台任务处理器 (iOS 13+)
    if #available(iOS 13.0, *) {
      let currentTime = Date()
      let taskIdentifier = "com.activebreak.app.background-processing"
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📱 开始注册BGTaskScheduler后台任务处理器")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🆔 任务标识符: \(taskIdentifier)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📅 注册时间: \(DateFormatter.fullFormatter.string(from: currentTime))")
      
      let registrationSuccess = BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
        // 这里是系统真正调用后台任务的地方！
        print("[\(DateFormatter.logFormatter.string(from: Date()))] 🚨🚨🚨 系统调用BGTaskScheduler处理器! 🚨🚨🚨")
        print("[\(DateFormatter.logFormatter.string(from: Date()))] 🎯 任务标识符: \(task.identifier)")
        print("[\(DateFormatter.logFormatter.string(from: Date()))] ⏰ 系统调用时间: \(DateFormatter.fullFormatter.string(from: Date()))")
        print("[\(DateFormatter.logFormatter.string(from: Date()))] 📋 任务类型: \(type(of: task))")
        print("[\(DateFormatter.logFormatter.string(from: Date()))] 🔥 这证明iOS系统确实触发了后台任务!")
        
        if let processingTask = task as? BGProcessingTask {
          self.handleBackgroundTask(task: processingTask)
        } else {
          print("[\(DateFormatter.logFormatter.string(from: Date()))] ❌ 任务类型转换失败: \(type(of: task))")
        }
      }
      
      if registrationSuccess {
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ✅ BGTaskScheduler注册成功!")
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] 💡 现在等待iOS系统调度后台任务...")
      } else {
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ❌ BGTaskScheduler注册失败!")
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔍 可能原因: 任务标识符已被注册或Info.plist配置错误")
      }
    } else {
      print("[\(DateFormatter.logFormatter.string(from: Date()))] ⚠️ iOS版本过低(< 13.0)，无法使用BGTaskScheduler")
    }
    
    // 应用启动时调度初始后台任务
    if #available(iOS 13.0, *) {
      print("[\(DateFormatter.logFormatter.string(from: Date()))] 🚀 应用启动，调度初始后台任务")
      scheduleNextBackgroundTask()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 处理Flutter方法调用
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkBackgroundTaskStatus":
      checkBackgroundTaskStatus(result: result)
    case "triggerBackgroundTask":
      triggerBackgroundTask(result: result)
    case "checkIntelligentReminders":
      // 这个方法已经在performBackgroundReminderCheck中处理
      performBackgroundReminderCheck { success in
        result(success)
      }
    case "getSystemInfo":
      getSystemInfo(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // 检查后台任务状态
  private func checkBackgroundTaskStatus(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      let status: [String: Any] = [
        "backgroundTaskRegistered": true,
        "taskIdentifier": "com.activebreak.app.background-processing",
        "backgroundModesEnabled": Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil,
        "notificationPermissionGranted": false // 将异步检查
      ]
      
      // 异步检查通知权限
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
          var updatedStatus: [String: Any] = status
          updatedStatus["notificationPermissionGranted"] = settings.authorizationStatus == .authorized
          result(updatedStatus)
        }
      }
    } else {
      result(["error": "iOS 13+ required for BGTaskScheduler"])
    }
  }
  
  // 手动触发后台任务（用于测试）
  private func triggerBackgroundTask(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      print("[\(DateFormatter.logFormatter.string(from: Date()))] 🧪 手动触发后台任务测试")
      
      // 创建一个模拟的后台任务
      let mockTask = MockBGProcessingTask()
      handleBackgroundTask(task: mockTask)
      
      result(["success": true, "message": "后台任务已手动触发"])
    } else {
      result(["error": "iOS 13+ required for BGTaskScheduler"])
    }
  }
  
  /// 获取系统信息
  /// @param result Flutter结果回调
  private func getSystemInfo(result: @escaping FlutterResult) {
    var systemInfo: [String: Any] = [:]
    
    // 获取设备信息
    systemInfo["deviceModel"] = UIDevice.current.model
    systemInfo["iosVersion"] = UIDevice.current.systemVersion
    
    // 获取电池信息
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel
    let batteryState = UIDevice.current.batteryState
    
    systemInfo["batteryLevel"] = Int(batteryLevel * 100)
    systemInfo["isCharging"] = (batteryState == .charging || batteryState == .full)
    
    // 获取低电量模式状态
    if #available(iOS 9.0, *) {
      systemInfo["lowPowerModeEnabled"] = ProcessInfo.processInfo.isLowPowerModeEnabled
    } else {
      systemInfo["lowPowerModeEnabled"] = false
    }
    
    // 检查后台应用刷新状态
    if #available(iOS 7.0, *) {
      let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
      systemInfo["backgroundAppRefreshEnabled"] = (backgroundRefreshStatus == .available)
      systemInfo["backgroundRefreshStatus"] = backgroundRefreshStatusString(backgroundRefreshStatus)
    } else {
      systemInfo["backgroundAppRefreshEnabled"] = false
      systemInfo["backgroundRefreshStatus"] = "unavailable"
    }
    
    // 检查通知权限
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        systemInfo["notificationPermissionGranted"] = (settings.authorizationStatus == .authorized)
        systemInfo["notificationAuthorizationStatus"] = self.notificationAuthorizationStatusString(settings.authorizationStatus)
        
        result(systemInfo)
      }
    }
  }
  
  /// 将后台刷新状态转换为字符串
  /// @param status 后台刷新状态
  /// @return String 状态字符串
  @available(iOS 7.0, *)
  private func backgroundRefreshStatusString(_ status: UIBackgroundRefreshStatus) -> String {
    switch status {
    case .available:
      return "available"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    @unknown default:
      return "unknown"
    }
  }
  
  /// 将通知授权状态转换为字符串
  /// @param status 通知授权状态
  /// @return String 状态字符串
  private func notificationAuthorizationStatusString(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .provisional:
      return "provisional"
    case .ephemeral:
      return "ephemeral"
    @unknown default:
      return "unknown"
    }
  }
  
  // iOS 13+ 后台任务处理
  @available(iOS 13.0, *)
  func handleBackgroundTask(task: BGProcessingTask) {
    let currentTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🎯 BGTaskScheduler触发后台任务!")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📋 任务标识符: \(task.identifier)")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⏰ 系统触发时间: \(DateFormatter.fullFormatter.string(from: currentTime))")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔄 这是系统自动调度的真实后台任务执行!")
    
    handleBackgroundTaskInternal(identifier: task.identifier, expirationHandler: task.expirationHandler, setTaskCompleted: task.setTaskCompleted)
  }
  
  // 处理模拟后台任务
  @available(iOS 13.0, *)
  func handleBackgroundTask(task: MockBGProcessingTask) {
    handleBackgroundTaskInternal(identifier: task.identifier, expirationHandler: task.expirationHandler, setTaskCompleted: task.setTaskCompleted)
  }
  
  // 通用后台任务处理逻辑
  @available(iOS 13.0, *)
  private func handleBackgroundTaskInternal(identifier: String, expirationHandler: (() -> Void)?, setTaskCompleted: @escaping (Bool) -> Void) {
    let startTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: startTime))] 🚀 开始执行后台任务: \(identifier)")
    
    // 注意：对于模拟任务，我们不能设置expirationHandler，因为它不是真实的BGTask
    
    // 执行后台提醒检查
    DispatchQueue.global(qos: .background).async {
      self.performBackgroundReminderCheck { success in
        let endTime = Date()
        print("[\(DateFormatter.logFormatter.string(from: endTime))] ✅ 后台提醒检查完成: \(success)，总执行时长: \(endTime.timeIntervalSince(startTime))秒")
        setTaskCompleted(success)
        
        // 调度下一个后台任务
        self.scheduleNextBackgroundTask()
      }
    }
  }
  
  // 执行后台提醒检查
  private func performBackgroundReminderCheck(completion: @escaping (Bool) -> Void) {
    print("开始执行后台提醒检查")
    
    // 调用Flutter的智能提醒检查方法
    flutterMethodChannel?.invokeMethod("checkIntelligentReminders", arguments: nil) { result in
      if let success = result as? Bool {
        print("Flutter智能提醒检查完成: \(success)")
        completion(success)
      } else if let error = result as? FlutterError {
        print("Flutter智能提醒检查失败: \(error.message ?? "未知错误")")
        // 如果Flutter调用失败，发送一个简单的提醒作为备用
        self.sendFallbackReminder()
        completion(false)
      } else {
        print("Flutter智能提醒检查返回未知结果")
        // 如果Flutter调用失败，发送一个简单的提醒作为备用
        self.sendFallbackReminder()
        completion(false)
      }
    }
  }
  
  // 备用提醒方法
  private func sendFallbackReminder() {
    let content = UNMutableNotificationContent()
    content.title = "运动提醒"
    content.body = "该起来活动一下了！保持健康的工作习惯。"
    content.sound = .default
    content.badge = 1
    
    let request = UNNotificationRequest(
      identifier: "fallback_reminder_\(Date().timeIntervalSince1970)",
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("发送备用通知失败: \(error.localizedDescription)")
      } else {
        print("备用通知发送成功")
      }
    }
  }
  
  // 调度下一个后台任务
  @available(iOS 13.0, *)
  private func scheduleNextBackgroundTask() {
    let currentTime = Date()
    let nextExecutionTime = Date(timeIntervalSinceNow: 60) // 1分钟后执行
    let taskIdentifier = "com.activebreak.app.background-processing"
    
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📅 开始调度下一个后台任务")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🕐 当前本地时间: \(DateFormatter.localTimeFormatter.string(from: currentTime))")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⏰ 预计执行时间: \(DateFormatter.localTimeFormatter.string(from: nextExecutionTime))")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🌍 当前时区: \(TimeZone.current.identifier)")
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⏱️ 时区偏移: \(TimeZone.current.secondsFromGMT() / 3600)小时")
    
    let request = BGProcessingTaskRequest(identifier: taskIdentifier)
    request.earliestBeginDate = nextExecutionTime
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false
    
    // 检查提交前的任务状态
    BGTaskScheduler.shared.getPendingTaskRequests { pendingTasks in
      let logTime = DateFormatter.logFormatter.string(from: Date())
      print("[\(logTime)] 📋 提交前待执行任务数量: \(pendingTasks.count)")
    }
    
    do {
      // 先取消之前的任务
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🗑️ 已取消之前的后台任务")
      
      // 检查后台应用刷新权限
      let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔍 后台应用刷新状态: \(backgroundRefreshStatus.rawValue)")
      
      switch backgroundRefreshStatus {
      case .available:
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ✅ 后台应用刷新可用")
      case .denied:
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ❌ 后台应用刷新被拒绝 - 用户在设置中禁用了后台应用刷新")
      case .restricted:
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⚠️ 后台应用刷新受限 - 可能由于家长控制或企业策略")
      @unknown default:
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] ❓ 未知的后台应用刷新状态")
      }
      
      // 提交新任务
      try BGTaskScheduler.shared.submit(request)
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ✅ 后台任务调度成功")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🆔 任务标识符: \(taskIdentifier)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⏳ 等待系统在 \(DateFormatter.localTimeFormatter.string(from: nextExecutionTime)) 后执行")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⚠️ 重要提示: iOS系统会根据以下因素决定是否真正执行后台任务:")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📱 1. 设备电量状态 (低电量模式会限制后台任务)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📊 2. 应用使用频率 (不常用的应用后台任务会被限制)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔋 3. 设备充电状态 (充电时更容易触发后台任务)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⏰ 4. 用户使用模式 (系统学习用户习惯来调度任务)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🎯 如果看到上面的🚨🚨🚨日志，说明系统确实触发了后台任务!")
      
      // 延迟检查任务是否成功提交
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        BGTaskScheduler.shared.getPendingTaskRequests { pendingTasks in
          let logTime = DateFormatter.logFormatter.string(from: Date())
          print("[\(logTime)] 📋 提交后待执行的后台任务数量: \(pendingTasks.count)")
          
          if pendingTasks.isEmpty {
            print("[\(logTime)] ⚠️ 警告: 任务提交后队列仍为空，可能的原因:")
            print("[\(logTime)] 1️⃣ 后台应用刷新被禁用")
            print("[\(logTime)] 2️⃣ 系统资源不足")
            print("[\(logTime)] 3️⃣ 应用权限不足")
            print("[\(logTime)] 4️⃣ 任务标识符未在Info.plist中正确配置")
          } else {
            for task in pendingTasks {
              let executeTime = task.earliestBeginDate ?? Date()
              print("[\(logTime)] 📝 待执行任务: \(task.identifier)")
              print("[\(logTime)] ⏰ 最早执行时间: \(DateFormatter.localTimeFormatter.string(from: executeTime))")
            }
          }
        }
      }
      
    } catch {
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ❌ 调度后台任务失败: \(error.localizedDescription)")
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔍 错误详情: \(error)")
      
      // 如果是因为任务过多导致的错误，尝试清理所有任务后重新调度
      if (error as NSError).code == 1 { // BGTaskSchedulerErrorCodeUnavailable
        print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🧹 尝试清理所有后台任务后重新调度")
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          do {
            try BGTaskScheduler.shared.submit(request)
            print("[\(DateFormatter.logFormatter.string(from: Date()))] ✅ 清理后重新调度成功")
          } catch {
            print("[\(DateFormatter.logFormatter.string(from: Date()))] ❌ 清理后重新调度仍然失败: \(error.localizedDescription)")
          }
        }
      }
    }
  }
  
  // 应用进入后台时调度后台任务
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    
    let currentTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📱 应用进入后台")
    
    if #available(iOS 13.0, *) {
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔄 开始调度后台任务...")
      scheduleNextBackgroundTask()
    } else {
      print("[\(DateFormatter.logFormatter.string(from: currentTime))] ⚠️ iOS版本过低，使用传统后台获取")
    }
  }
  
  // 应用从后台返回前台
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    
    let currentTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📱 应用即将进入前台")
    
    // 检查待执行的后台任务
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.getPendingTaskRequests { pendingTasks in
        let logTime = DateFormatter.logFormatter.string(from: Date())
        print("[\(logTime)] 📋 前台检查：当前待执行的后台任务数量: \(pendingTasks.count)")
        for task in pendingTasks {
          print("[\(logTime)] 📝 待执行任务: \(task.identifier), 最早执行时间: \(task.earliestBeginDate ?? Date())")
        }
      }
    }
  }
  
  // 应用已进入前台
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    let currentTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 📱 应用已激活")
  }
  
  // iOS 12及以下版本的后台获取
  override func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let currentTime = Date()
    print("[\(DateFormatter.logFormatter.string(from: currentTime))] 🔄 执行传统后台获取")
    performBackgroundReminderCheck { success in
      let endTime = Date()
      print("[\(DateFormatter.logFormatter.string(from: endTime))] ✅ 传统后台获取完成: \(success)")
      completionHandler(success ? .newData : .failed)
    }
  }
}

// MARK: - MockBGAppRefreshTask for Testing
// 模拟后台任务协议
@available(iOS 13.0, *)
protocol MockBackgroundTask {
  var identifier: String { get }
  var expirationHandler: (() -> Void)? { get set }
  func setTaskCompleted(success: Bool)
}

@available(iOS 13.0, *)
class MockBGProcessingTask: MockBackgroundTask {
  private var _identifier: String = "com.activebreak.app.background-processing"
  private var _expirationHandler: (() -> Void)?
  private var _completed: Bool = false
  
  init() {
    // 模拟后台任务初始化
  }
  
  var identifier: String {
    return _identifier
  }
  
  var expirationHandler: (() -> Void)? {
    get { return _expirationHandler }
    set { _expirationHandler = newValue }
  }
  
  func setTaskCompleted(success: Bool) {
    _completed = true
    print("[\(DateFormatter.logFormatter.string(from: Date()))] 🧪 模拟后台任务完成: \(success)")
  }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
  static let logFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    formatter.timeZone = TimeZone.current // 使用本地时区
    return formatter
  }()
  
  static let fullFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = TimeZone.current // 使用本地时区
    return formatter
  }()
  
  static let localTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.current
    return formatter
  }()
}
