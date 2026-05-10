//
//  ContentView.swift
//  Plotty
//
//  Created by Aloha on 2026/05/10.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appSettings) private var appSettings
    
    @State private var selectedTab = TabItem.chat.rawValue
    @State private var chatInput = ""
    @State private var sendButtonState: SendButtonState = .empty
    @State private var messages: [ChatMessage] = ChatMessage.sampleData
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            TabView(selection: $selectedTab) {
                MemoView()
                    .tag(TabItem.memo.rawValue)
                TodoView()
                    .tag(TabItem.todo.rawValue)
                ChatTabView()
                    .tag(TabItem.chat.rawValue)
                CalendarTabView()
                    .tag(TabItem.calendar.rawValue)
                SettingsView()
                    .tag(TabItem.settings.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomChrome
        }
    }
    
    private var bottomChrome: some View {
        VStack(spacing: Spacing.xs) {
            if selectedTab == TabItem.chat.rawValue {
                FloatingInputBar(
                    text: $chatInput,
                    sendButtonState: $sendButtonState,
                    onSend: handleChatSend
                )
                .padding(.horizontal, Spacing.chatHorizontal)
            }
            FooterTabBar(selectedTab: $selectedTab)
        }
    }
    
    private func handleChatSend() {
        guard !chatInput.isEmpty else { return }
        
        let userMessage = ChatMessage(
            role: .user,
            text: chatInput,
            chips: [],
            timestamp: Date()
        )
        
        sendButtonState = .processing
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            messages.append(userMessage)
            sendButtonState = .done
            chatInput = ""
        }
    }
}

#Preview {
    ContentView()
        .environment(\.appSettings, AppSettings())
}
