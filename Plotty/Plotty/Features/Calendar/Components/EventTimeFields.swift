import SwiftUI

// MARK: - 予定の日時入力（終日なら日付、それ以外は開始と任意の終了。作成・編集シートで共通）
struct EventTimeFields: View {
    @Binding var start: Date
    /// nil は「終了時刻を決めていない」予定
    @Binding var end: Date?
    let isAllDay: Bool
    
    private static let defaultDuration: TimeInterval = 3600
    
    var body: some View {
        if isAllDay {
            DatePicker("日付", selection: $start, displayedComponents: [.date])
        } else {
            DatePicker("開始", selection: $start, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: start) { oldStart, newStart in
                    keepEndAfterStart(oldStart: oldStart, newStart: newStart)
                }
            Toggle("終了時刻を指定", isOn: hasEnd)
            if let end {
                DatePicker(
                    "終了",
                    selection: Binding(get: { end }, set: { self.end = $0 }),
                    in: start...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }
    
    /// オンにした直後は開始の 1 時間後から選べるようにする
    private var hasEnd: Binding<Bool> {
        Binding(
            get: { end != nil },
            set: { isOn in end = isOn ? start.addingTimeInterval(Self.defaultDuration) : nil }
        )
    }
    
    /// 開始を動かして終了を追い越したら、それまでの長さを保ったまま終了も後ろへずらす
    private func keepEndAfterStart(oldStart: Date, newStart: Date) {
        guard let currentEnd = end, currentEnd <= newStart else { return }
        let previousDuration = currentEnd.timeIntervalSince(oldStart)
        end = newStart.addingTimeInterval(previousDuration > 0 ? previousDuration : Self.defaultDuration)
    }
}
