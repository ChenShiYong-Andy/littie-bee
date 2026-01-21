import SwiftUI
import UIKit

/// 主视图
/// 显示所有提醒事项的列表，支持添加、删除和标记完成
struct ContentView: View {
    /// 提醒管理器：使用 @StateObject 创建并持有管理器实例
    @StateObject private var manager = ReminderManager.shared
    
    /// 控制添加提醒视图的显示状态
    @State private var showingAddReminder = false
    
    /// 引导用户开启“持续横幅”的提示
    @State private var showingNotificationHint = false
    
    /// 选择模式下选中的提醒 ID
    @State private var selection = Set<UUID>()
    
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                // 遍历并显示所有提醒事项
                ForEach(sortedReminders) { reminder in
                    HStack {
                        // 提醒信息区域：显示标题和日期
                        VStack(alignment: .leading, spacing: 6) {
                            Text(reminder.title)
                                .font(.headline)
                                // 已完成的事项显示删除线
                                .strikethrough(reminder.isCompleted)
                                .foregroundColor(reminder.isCompleted ? .secondary : .primary)

                            // 显示格式化的提醒时间
                            Text(dateString(for: reminder.reminderDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 完成状态切换按钮
                        Button(action: {
                            manager.toggleReminder(reminder)
                        }) {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(reminder.isCompleted ? .green : .gray)
                                .imageScale(.large)
                        }
                    }
                    .padding(.vertical, 4)
                    // 滑动删除：只显示删除图标，不显示文字
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            manager.deleteReminder(reminder)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("我的提醒")
            .toolbar {
                // 编辑按钮（进入多选模式）
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                // 通知设置按钮：引导用户把横幅改为“持续”
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("通知设置") {
                        showingNotificationHint = true
                    }
                }
                // 添加提醒按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReminder = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                // 批量删除按钮，仅在选择模式且有选择时显示
                ToolbarItem(placement: .bottomBar) {
                    if !selection.isEmpty {
                        Button(role: .destructive) {
                            manager.deleteReminders(ids: selection)
                            selection.removeAll()
                        } label: {
                            Label("删除所选", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            // 显示添加提醒的弹窗
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(manager: manager)
            }
            .alert("设置持续横幅", isPresented: $showingNotificationHint) {
                Button("去设置") {
                    openNotificationSettings()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("iOS 不允许 App 默认开启持续横幅。请在系统设置中将本 App 的横幅样式改为“持续”。路径：设置 → 通知 → 提醒样式。")
            }
            // 空状态提示：当没有提醒时显示
            .overlay {
                if manager.reminders.isEmpty {
                    ContentUnavailableView {
                        Label("暂无提醒", systemImage: "bell.slash")
                    } description: {
                        Text("点击右上角 + 添加新提醒")
                    }
                }
            }
        }
    }

    /// 按时间排序的提醒列表
    /// 返回按提醒日期从早到晚排序的提醒数组
    private var sortedReminders: [Reminder] {
        manager.reminders.sorted { $0.reminderDate < $1.reminderDate }
    }

    /// 格式化日期显示
    /// - Parameter date: 要格式化的日期
    /// - Returns: 格式化后的日期字符串
    /// 根据日期是否为今天、明天或其他日期，显示不同的格式
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        // 今天：显示 "今天 HH:mm"
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        // 明天：显示 "明天 HH:mm"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "明天 HH:mm"
        // 其他日期：显示 "MM月dd日 HH:mm"
        } else {
            formatter.dateFormat = "MM月dd日 HH:mm"
        }

        return formatter.string(from: date)
    }
    
    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

}

/// 预览视图：用于 Xcode 预览功能
#Preview {
    ContentView()
}
