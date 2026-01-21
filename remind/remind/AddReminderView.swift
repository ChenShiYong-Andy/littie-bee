import SwiftUI

/// 添加提醒视图
/// 用于创建新的提醒事项，包括提醒标题和提醒时间
struct AddReminderView: View {
    /// 环境变量：用于关闭当前视图
    @Environment(\.dismiss) var dismiss
    
    /// 提醒管理器：负责管理提醒事项的增删改查
    @ObservedObject var manager: ReminderManager

    /// 提醒标题：用户输入的提醒内容
    @State private var title: String = ""
    
    /// 提醒时间：用户选择的提醒日期和时间
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                // 提醒内容输入区域
                Section(header: Text("提醒内容")) {
                    TextField("输入提醒事项", text: $title)
                }

                // 提醒时间选择区域
                Section(header: Text("提醒时间")) {
                    DatePicker("选择时间", selection: $selectedDate)
                }
            }
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            // 在整个视图层级设置语言环境，确保 DatePicker 使用中文界面
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .toolbar {
                // 取消按钮：关闭当前视图，不保存
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                // 保存按钮：将提醒添加到管理器并关闭视图
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        manager.addReminder(title: title, date: selectedDate)
                        dismiss()
                    }
                    // 当标题为空时禁用保存按钮
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}