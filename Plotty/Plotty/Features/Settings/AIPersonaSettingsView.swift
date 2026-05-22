import SwiftUI

// MARK: - AI 人格設定（`ai_persona_config`）
struct AIPersonaSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: AIPersonaConfig = .default
    
    var body: some View {
        Form {
            Section("基本") {
                TextField("名前", text: $draft.name)
                TextField("トーン", text: $draft.tone)
                TextField("役割", text: $draft.identity)
            }
            
            Section {
                TextField("禁止トピック（カンマ区切り）", text: prohibitedTopicsText, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("禁止トピック")
            } footer: {
                Text("政治・宗教など、AI が避ける話題を指定します。")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("AI の口調")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    appSettings.aiPersona = draft
                    dismiss()
                }
            }
        }
        .onAppear {
            draft = appSettings.aiPersona
        }
    }
    
    private var prohibitedTopicsText: Binding<String> {
        Binding(
            get: { draft.prohibitedTopics.joined(separator: ", ") },
            set: {
                draft.prohibitedTopics = $0
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        )
    }
}

#Preview {
    NavigationStack {
        AIPersonaSettingsView()
            .environment(\.appSettings, AppSettings())
    }
}
