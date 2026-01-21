//
//  remindApp.swift
//  remind
//
//  Created by Andy on 2026/1/20.
//

import SwiftUI
import UserNotifications
import UIKit
import CoreHaptics

/// 应用入口点
/// 负责初始化应用并设置主窗口内容
@main
struct remindApp: App {
    /// UIApplication 代理：用于设置通知代理、处理前台通知振动
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// 应用场景主体
    /// 定义应用的窗口组和初始视图
    var body: some Scene {
        WindowGroup {
            // 设置主视图为 ContentView
            ContentView()
                // 在应用级别设置语言环境为中文，确保所有组件使用中文界面
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }
}

/// AppDelegate 用于配置通知代理并在前台触发振动
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var hapticEngine: CHHapticEngine?
    
    /// 为避免系统节流，这里做一个短暂的持续振动：在 2 秒内每 0.4 秒触发一次触感
    /// 现在改为更接近“时钟计时器”的连续振动：优先用 CoreHaptics 播放一段多脉冲模式，设备不支持时回退到系统触感多次触发
    private func playTimerStyleVibration() {
        // CoreHaptics 支持则播放一段密集脉冲
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                try ensureHapticEngine()
                let events: [CHHapticEvent] = stride(from: 0.0, through: 4.0, by: 0.35).map { t in
                    CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                                  ],
                                  relativeTime: t)
                }
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try hapticEngine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
                return
            } catch {
                print("Haptic pattern play failed: \(error.localizedDescription)")
            }
        }
        
        // 回退：2 秒内多次系统触感
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        let intervals: [TimeInterval] = [0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.8, 3.2, 3.6, 4.0]
        for delay in intervals {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                generator.notificationOccurred(.warning)
            }
        }
    }
    
    /// 初始化并启动触觉引擎
    private func ensureHapticEngine() throws {
        if hapticEngine == nil {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason.rawValue)")
            }
            hapticEngine?.resetHandler = { [weak self] in
                try? self?.hapticEngine?.start()
            }
        }
        try hapticEngine?.start()
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerCategories(center: center)
        return true
    }
    
    private func registerCategories(center: UNUserNotificationCenter) {
        let complete = UNNotificationAction(identifier: "COMPLETE_REMINDER_ACTION",
                                            title: "完成",
                                            options: [.foreground])
        let category = UNNotificationCategory(identifier: "REMINDER_CATEGORY",
                                              actions: [complete],
                                              intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }
    
    /// 前台收到通知时，手动触发一次触感反馈以实现振动
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        playTimerStyleVibration()
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 用户点击通知或后台送达回到前台时，也触发一次振动
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        playTimerStyleVibration()
        
        if response.actionIdentifier == "COMPLETE_REMINDER_ACTION",
           let reminderIdString = response.notification.request.content.userInfo["reminderId"] as? String,
           let reminderId = UUID(uuidString: reminderIdString) {
            Task { @MainActor in
                ReminderManager.shared.completeReminder(withId: reminderId)
            }
        }
        completionHandler()
    }
}
