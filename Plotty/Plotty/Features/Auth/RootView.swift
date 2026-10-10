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
        // 切り替え中に新旧の画面を重ねてクロスディゾルブさせるため Group ではなく ZStack
        ZStack {
            #if DEBUG
            if PlotDebug.keyboardProbeOnly {
                KeyboardProbeView()
            } else if accountSession.isAuthenticated {
                ContentView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
            #else
            if accountSession.isAuthenticated {
                ContentView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
            #endif
        }
        .animation(.crossDissolve, value: accountSession.isAuthenticated)
        // アプリ全体でスクロールバーを出さない。環境値として配下の ScrollView / List / Form やシートにも引き継がれる
        .scrollIndicators(.hidden)
        // DatePicker などシステム部品の日付表記を端末の言語ではなくアプリの言語設定にそろえる
        .environment(\.locale, appSettings.language.locale)
        .preferredColorScheme(appSettings.theme.colorScheme)
        .environment(\.plotColorScheme, plotColorScheme)
    }
}

