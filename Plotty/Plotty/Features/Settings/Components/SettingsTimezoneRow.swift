import SwiftUI

// MARK: - タイムゾーン選択行
struct SettingsTimezoneRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("タイムゾーン")
                .font(.scaledBodyLarge())
                .foregroundStyle(textColor)
            
            Picker("タイムゾーン", selection: Binding(
                get: { appSettings.timezoneIdentifier },
                set: { appSettings.timezoneIdentifier = $0 }
            )) {
                Text("東京 (JST)").tag("Asia/Tokyo")
                Text("UTC").tag("UTC")
                Text("ロサンゼルス").tag("America/Los_Angeles")
                Text("ロンドン").tag("Europe/London")
            }
            .pickerStyle(.menu)
            .tint(textColor)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
