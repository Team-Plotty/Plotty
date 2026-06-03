import Foundation

// MARK: - 言語対応の日付フォーマッター
/// アプリの言語設定に応じた日付フォーマットを提供
enum PlotDateFormatter {
    
    /// 日時表示（例: "2026年6月1日（月）18:49" / "Jun 1, 2026 at 6:49 PM"）
    static func dateTime(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        
        switch language {
        case .japanese:
            formatter.dateFormat = "yyyy年M月d日（E）H:mm"
        case .english:
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    /// 日付のみ（例: "2026年6月1日（月）" / "Jun 1, 2026"）
    static func date(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        
        switch language {
        case .japanese:
            formatter.dateFormat = "yyyy年M月d日（E）"
        case .english:
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    /// 日付と祝日名（例: "2026年1月1日（木）| 元日" / "Jan 1, 2026 | New Year's Day"）
    static func dateWithHoliday(_ date: Date, language: AppLanguage) -> String {
        var result = self.date(date, language: language)
        
        if let holidayName = PlotJapaneseCalendar.holidayName(for: date) {
            result += " | \(holidayName)"
        }
        
        return result
    }
    
    /// 年月表示（例: "2026年6月" / "June 2026"）
    static func yearMonth(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        
        switch language {
        case .japanese:
            formatter.dateFormat = "yyyy年M月"
        case .english:
            formatter.dateFormat = "MMMM yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    /// 時刻のみ（例: "18:49" / "6:49 PM"）
    static func time(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        
        switch language {
        case .japanese:
            formatter.dateFormat = "H:mm"
        case .english:
            formatter.dateFormat = "h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    /// 時刻範囲（例: "18:00 - 19:00" / "6:00 PM - 7:00 PM"）
    static func timeRange(from start: Date, to end: Date, language: AppLanguage) -> String {
        "\(time(start, language: language)) - \(time(end, language: language))"
    }
    
    /// 日時範囲（例: "2026年6月1日（月）18:00 〜 19:00" / "Jun 1, 2026 at 6:00 PM 〜 7:00 PM"）
    static func dateTimeRange(from start: Date, to end: Date, language: AppLanguage) -> String {
        "\(dateTime(start, language: language)) 〜 \(dateTime(end, language: language))"
    }
}
