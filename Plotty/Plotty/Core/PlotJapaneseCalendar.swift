import Foundation

// MARK: - 日本の祝日カレンダー（Holidays JP API）
/// 日本の国民の祝日を取得・キャッシュするサービス
/// データソース: https://holidays-jp.github.io/ (内閣府CSV由来、MIT License)
actor PlotJapaneseCalendarService {
    static let shared = PlotJapaneseCalendarService()
    
    private let apiURL = URL(string: "https://holidays-jp.github.io/api/v1/date.json")!
    private let cacheKey = "PlotJapaneseHolidaysCache"
    private let cacheTimestampKey = "PlotJapaneseHolidaysCacheTimestamp"
    private let cacheDuration: TimeInterval = 60 * 60 * 24 * 7 // 1週間
    
    private var memoryCache: [String: String]?
    
    private init() {}
    
    /// 祝日データを取得（キャッシュ優先、必要に応じてAPI取得）
    func fetchHolidays() async -> [String: String] {
        // メモリキャッシュがあればそれを返す
        if let cache = memoryCache {
            return cache
        }
        
        // ディスクキャッシュを確認
        if let cached = loadFromDiskCache() {
            memoryCache = cached
            return cached
        }
        
        // APIから取得
        do {
            let holidays = try await fetchFromAPI()
            memoryCache = holidays
            saveToDiskCache(holidays)
            return holidays
        } catch {
            // 通信失敗時は期限切れキャッシュも許容
            if let expired = loadFromDiskCache(ignoreExpiry: true) {
                memoryCache = expired
                return expired
            }
            // フォールバック: 空の辞書
            return [:]
        }
    }
    
    /// 指定した日が祝日かどうか
    func isHoliday(_ date: Date) async -> Bool {
        let holidays = await fetchHolidays()
        let key = dateKey(for: date)
        return holidays[key] != nil
    }
    
    /// 指定した日の祝日名を取得
    func holidayName(for date: Date) async -> String? {
        let holidays = await fetchHolidays()
        let key = dateKey(for: date)
        return holidays[key]
    }
    
    // MARK: - Private
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    private func fetchFromAPI() async throws -> [String: String] {
        let (data, response) = try await URLSession.shared.data(from: apiURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let holidays = try JSONDecoder().decode([String: String].self, from: data)
        return holidays
    }
    
    private func loadFromDiskCache(ignoreExpiry: Bool = false) -> [String: String]? {
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: cacheKey) else {
            return nil
        }
        
        if !ignoreExpiry {
            let timestamp = defaults.double(forKey: cacheTimestampKey)
            let cacheDate = Date(timeIntervalSince1970: timestamp)
            if Date().timeIntervalSince(cacheDate) > cacheDuration {
                return nil
            }
        }
        
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
    
    private func saveToDiskCache(_ holidays: [String: String]) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(holidays) {
            defaults.set(data, forKey: cacheKey)
            defaults.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }
}

// MARK: - 同期アクセス用のラッパー（UIから使いやすくするため）
/// CalendarMonthGridなど同期的にアクセスする箇所向け
enum PlotJapaneseCalendar {
    
    /// キャッシュ済みの祝日データ（起動時に非同期でロード）
    private static var cachedHolidays: [String: String] = [:]
    private static var isLoaded = false
    
    /// アプリ起動時に呼び出して祝日データをプリロード
    static func preload() {
        guard !isLoaded else { return }
        isLoaded = true
        
        Task {
            let holidays = await PlotJapaneseCalendarService.shared.fetchHolidays()
            await MainActor.run {
                cachedHolidays = holidays
            }
        }
    }
    
    /// 指定した日が祝日かどうか（同期版、キャッシュ使用）
    static func isHoliday(_ date: Date) -> Bool {
        let key = dateKey(for: date)
        return cachedHolidays[key] != nil
    }
    
    /// 指定した日の祝日名を取得（同期版、キャッシュ使用）
    static func holidayName(for date: Date) -> String? {
        let key = dateKey(for: date)
        return cachedHolidays[key]
    }
    
    /// 指定した年の祝日一覧を取得（同期版、キャッシュ使用）
    static func holidays(for year: Int) -> [Date: String] {
        let cal = Calendar(identifier: .gregorian)
        var result: [Date: String] = [:]
        
        for (key, name) in cachedHolidays {
            if let date = parseDate(key),
               cal.component(.year, from: date) == year {
                result[date] = name
            }
        }
        
        return result
    }
    
    // MARK: - Private
    
    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    private static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.date(from: string)
    }
}
