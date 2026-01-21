import Foundation
import Combine
import UserNotifications

/// 提醒管理器
/// 负责管理提醒事项的增删改查、通知调度和数据持久化
/// 使用 @MainActor 确保所有操作在主线程执行
@MainActor
final class ReminderManager: ObservableObject {
    /// 单例，便于通知回调时操作数据
    static let shared = ReminderManager()
    
    /// 提醒事项列表：使用 @Published 标记，当列表变化时自动通知视图更新
    @Published var reminders: [Reminder] = []

    /// UserDefaults 存储键：用于保存和加载提醒数据
    private let saveKey = "savedReminders"

    /// 初始化管理器
    /// 自动加载已保存的提醒并请求通知权限
    private init() {
        loadReminders()
        requestNotificationPermission()
    }

    /// 请求系统通知权限
    /// 向用户请求发送通知的权限（包括提醒、声音和角标）
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else {
                print("通知权限被拒绝")
            }
        }
    }

    /// 添加新的提醒事项
    /// - Parameters:
    ///   - title: 提醒标题
    ///   - date: 提醒日期和时间
    /// 如果提醒时间在未来，会自动创建系统通知
    func addReminder(title: String, date: Date) {
        var newReminder = Reminder(title: title, reminderDate: date)
        
        // 只有当时间在未来时才设置通知
        if date > Date() {
            newReminder.notificationId = scheduleNotification(for: newReminder, at: date)
        }
        
        reminders.append(newReminder)
        saveReminders()
    }

    /// 调度系统通知
    /// - Parameters:
    ///   - title: 通知内容
    ///   - date: 通知触发时间
    /// - Returns: 通知的唯一标识符，用于后续取消通知
    func scheduleNotification(for reminder: Reminder, at date: Date) -> String {
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "提醒"
        content.body = reminder.title
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "REMINDER_CATEGORY"
        content.userInfo = ["reminderId": reminder.id.uuidString]

        // 设置通知触发时间
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // 创建通知请求并添加到系统
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知设置失败: \(error.localizedDescription)")
            } else {
                print("通知已设置: \(identifier)")
            }
        }

        return identifier
    }

    /// 删除提醒事项
    /// - Parameter reminder: 要删除的提醒事项
    /// 同时会取消关联的系统通知
    func deleteReminder(_ reminder: Reminder) {
        // 取消关联的通知
        if let notificationId = reminder.notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }

        // 从列表中移除提醒
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }
    
    /// 批量删除提醒
    /// - Parameter ids: 需要删除的提醒 ID 集合
    func deleteReminders(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        
        // 先取消关联通知
        let notificationIds = reminders
            .filter { ids.contains($0.id) }
            .compactMap { $0.notificationId }
        if !notificationIds.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIds)
        }
        
        reminders.removeAll { ids.contains($0.id) }
        saveReminders()
    }

    /// 切换提醒事项的完成状态
    /// - Parameter reminder: 要切换状态的提醒事项
    /// 将已完成状态切换为未完成，或反之
    func toggleReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
            saveReminders()
        }
    }
    
    /// 通过 ID 完成提醒（用于通知动作）
    func completeReminder(withId id: UUID) {
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            reminders[index].isCompleted = true
            if let notificationId = reminders[index].notificationId {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
            }
            saveReminders()
        }
    }

    /// 保存提醒列表到 UserDefaults
    /// 使用 JSON 编码将提醒数据持久化存储
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    /// 从 UserDefaults 加载提醒列表
    /// 应用启动时自动调用，恢复之前保存的提醒数据
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
        }
    }
}