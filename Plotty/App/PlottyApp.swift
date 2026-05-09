import SwiftUI

@main
struct PlottyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Plotty")
                    NavigationLink("設定へ") {
                        SettingsView()
                    }
                }
                .padding()
            }
            .onOpenURL { url in
                SupabaseManager.client.handle(url)
            }
        }
    }
}
