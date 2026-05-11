//
//  ContentView.swift
//  Plotty
//
//  Created by Aloha on 2026/05/10.
//

import SwiftUI

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentView: View {
    @Environment(\.appSettings) private var appSettings
    
    @State private var selectedTab: TabItem = .chat
    @State private var chatInput = ""
    @State private var sendButtonState: SendButtonState = .empty
    
    @State private var inputBarHeight: CGFloat = 0
    private let tabBarHeightEstimate: CGFloat = 64
    private let inputBarLift: CGFloat = 30
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            TabView(selection: $selectedTab) {
                MemoView()
                    .tag(TabItem.memo)
                    .tabItem {
                        Label(TabItem.memo.label, systemImage: TabItem.memo.icon.active)
                    }
                TodoView()
                    .tag(TabItem.todo)
                    .tabItem {
                        Label(TabItem.todo.label, systemImage: TabItem.todo.icon.active)
                    }
                ChatTabView(bottomInset: inputBarHeight + tabBarHeightEstimate + 16)
                    .tag(TabItem.chat)
                    .tabItem {
                        Label("チャット", systemImage: TabItem.chat.icon.active)
                    }
                CalendarTabView()
                    .tag(TabItem.calendar)
                    .tabItem {
                        Label(TabItem.calendar.label, systemImage: TabItem.calendar.icon.active)
                    }
                SettingsView()
                    .tag(TabItem.settings)
                    .tabItem {
                        Label(TabItem.settings.label, systemImage: TabItem.settings.icon.active)
                    }
            }
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .overlay(alignment: .bottom) {
            if selectedTab == .chat {
                GeometryReader { proxy in
                    let bottom = proxy.safeAreaInsets.bottom
                    FloatingInputBar(
                        text: $chatInput,
                        sendButtonState: $sendButtonState,
                        onSend: handleChatSend
                    )
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, bottom + tabBarHeightEstimate + Spacing.xs + inputBarLift)
                    .background(
                        GeometryReader { p in
                            Color.clear
                                .preference(key: HeightPreferenceKey.self, value: p.size.height)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .ignoresSafeArea()
            }
        }
        .onPreferenceChange(HeightPreferenceKey.self) { inputBarHeight = $0 }
    }
    
    private func handleChatSend() {
        guard !chatInput.isEmpty else { return }
        sendButtonState = .processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            sendButtonState = .done
            chatInput = ""
        }
    }
}

#Preview {
    ContentView()
        .environment(\.appSettings, AppSettings())
}
