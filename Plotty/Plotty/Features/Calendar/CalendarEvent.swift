import SwiftUI

// MARK: - 予定（カレンダー用のデータモデル）
struct CalendarEvent: Identifiable {
    let id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var swatch: AccentSwatch
    var location: String
    var notes: String
    var isAllDay: Bool

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        swatch: AccentSwatch,
        location: String = "",
        notes: String = "",
        isAllDay: Bool = false
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.swatch = swatch
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
    }

    var color: Color { swatch.color }
}

// MARK: - 本実装時削除（開発用サンプルデータ）
extension CalendarEvent {
    static var sampleData: [CalendarEvent] {
        let today = Date()
        let cal = Calendar.current
        let y = cal.date(byAdding: .day, value: -1, to: today)!
        
        return [
            CalendarEvent(
                title: "チームミーティング",
                startTime: cal.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                swatch: .sky
            ),
            CalendarEvent(
                title: "ランチ",
                startTime: cal.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                swatch: .sage
            ),
            CalendarEvent(
                title: "昨日の振り返り",
                startTime: cal.date(bySettingHour: 18, minute: 0, second: 0, of: y)!,
                endTime: cal.date(bySettingHour: 18, minute: 45, second: 0, of: y)!,
                swatch: .coral
            ),
        ]
    }
}
