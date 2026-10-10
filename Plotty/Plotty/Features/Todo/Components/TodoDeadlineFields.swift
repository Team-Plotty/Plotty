import SwiftUI

// MARK: - タスクの締切入力（日付＋任意の時刻。作成・編集シートで共通）
/// 予定の「開始〜終了」と区別するため、タスクは締切の一点だけを持つ
struct TodoDeadlineFields: View {
    @Binding var dueDate: Date
    @Binding var hasDueTime: Bool
    
    var body: some View {
        DatePicker("日付", selection: $dueDate, displayedComponents: [.date])
        Toggle("時刻を指定", isOn: $hasDueTime)
        if hasDueTime {
            DatePicker("時刻", selection: $dueDate, displayedComponents: [.hourAndMinute])
        }
    }
}
