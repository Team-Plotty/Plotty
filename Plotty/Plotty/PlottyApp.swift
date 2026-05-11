//
//  PlottyApp.swift
//  Plotty
//
//  Created by Aloha on 2026/05/10.
//

import SwiftUI
import UIKit

@main
struct PlottyApp: App {
    @State private var appSettings = AppSettings()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appSettings, appSettings)
        }
    }
}
