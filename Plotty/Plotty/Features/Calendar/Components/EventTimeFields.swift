import SwiftUI

// MARK: - 予定の日時入力（終日なら日付、それ以外は開始〜終了。作成・編集シートで共通）
struct EventTimeFields: View {
    @Binding var start: Date
    @Binding var end: Date
    let isAllDay: Bool
    
    var body: some View {
        if isAllDay {
            DatePicker("日付", selection: $start, displayedComponents: [.date])
        } else {
            DatePicker("開始", selection: $start, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: start) { oldStart, newStart in
                    keepEndAfterStart(oldStart: oldStart, newStart: newStart)
                }
            DatePicker("終了", selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    /// 開始を動かして終了を追い越したら、それまでの長さを保ったまま終了も後ろへずらす
    private func keepEndAfterStart(oldStart: Date, newStart: Date) {
        guard end <= newStart else { return }
        let previousDuration = end.timeIntervalSince(oldStart)
        let defaultDuration: TimeInterval = 3600
        end = newStart.addingTimeInterval(previousDuration > 0 ? previousDuration : defaultDuration)
    }
}
