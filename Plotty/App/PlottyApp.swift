import SwiftUI

@main
struct PlottyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            Text("Plotty")
        }
    }
}
