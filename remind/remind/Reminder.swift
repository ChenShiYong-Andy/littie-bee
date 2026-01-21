import Foundation

/// 提醒事项数据模型
/// 表示一个提醒事项，包含标题、日期、完成状态等信息
struct Reminder: Identifiable, Codable {
    /// 唯一标识符：用于区分不同的提醒事项
    let id: UUID
    
    /// 提醒标题：提醒事项的内容描述
    var title: String
    
    /// 提醒日期：提醒事项的触发时间
    var reminderDate: Date
    
    /// 完成状态：标记提醒事项是否已完成
    var isCompleted: Bool
    
    /// 通知ID：系统通知的唯一标识符，用于取消通知
    var notificationId: String?

    /// 初始化提醒事项
    /// - Parameters:
    ///   - title: 提醒标题
    ///   - reminderDate: 提醒日期
    ///   - notificationId: 通知ID（可选），如果提供则关联系统通知
    init(title: String, reminderDate: Date, notificationId: String? = nil) {
        self.id = UUID()
        self.title = title
        self.reminderDate = reminderDate
        self.isCompleted = false
        self.notificationId = notificationId
    }
}