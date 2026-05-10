//
//  PlottyApp.swift
//  Plotty
//
//  Created by Aloha on 2026/05/10.
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
