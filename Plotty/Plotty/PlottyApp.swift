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
    @State private var accountSession = AccountSession()
    @State private var plotDataStore = PlotDataStore()
    @State private var connectivity = ConnectivityMonitor()
    
    init() {
        // 日本の祝日データをプリロード（Holidays JP API）
        PlotJapaneseCalendar.preload()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appSettings, appSettings)
                .environment(\.accountSession, accountSession)
                .environment(\.plotDataStore, plotDataStore)
                .environment(\.connectivity, connectivity)
                .onOpenURL { url in
                    SupabaseManager.handleOpenURL(url)
                }
        }
    }
}
