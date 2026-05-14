//
//  PlottyApp.swift
//  Plotty
//
//  作成: Aloha  2026/05/10
//  アプリのエントリ。`@main` と環境の注入。
//

import SwiftUI

@main
struct PlottyApp: App {
    @State private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appSettings, appSettings)
        }
    }
}
