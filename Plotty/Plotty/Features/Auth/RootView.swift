import SwiftUI

// MARK: - 認証前後のルート
struct RootView: View {
    @Environment(\.accountSession) private var accountSession
    @Environment(\.appSettings) private var appSettings
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var plotColorScheme: ColorScheme {
        appSettings.theme.colorScheme ?? systemColorScheme
    }
    
    var body: some View {
        Group {
            if PlotDebug.keyboardProbeOnly {
                KeyboardProbeView()
            } else if accountSession.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .environment(\.plotColorScheme, plotColorScheme)
    }
}

