import SwiftUI

// MARK: - 認証前後のルート
struct RootView: View {
    @Environment(\.accountSession) private var accountSession
    @Environment(\.appSettings) private var appSettings
    
    var body: some View {
        Group {
            if accountSession.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
    }
}

