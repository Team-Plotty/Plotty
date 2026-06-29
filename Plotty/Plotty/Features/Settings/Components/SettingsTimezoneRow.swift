import SwiftUI

// MARK: - タイムゾーン選択行
struct SettingsTimezoneRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    @Environment(\.userSettingsSync) private var userSettingsSync
    @Environment(\.connectivity) private var connectivity
    
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
        .onChange(of: appSettings.timezoneIdentifier) { oldValue, newValue in
            guard oldValue != newValue, !userSettingsSync.isApplyingRemote else { return }
            Task { @MainActor in
                _ = await userSettingsSync.pushTimezone(newValue, isOnline: connectivity.isOnline)
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
