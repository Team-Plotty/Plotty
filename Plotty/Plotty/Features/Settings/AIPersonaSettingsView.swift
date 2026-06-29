import SwiftUI

// MARK: - AI 人格設定（`ai_persona_config`）
struct AIPersonaSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    @Environment(\.userSettingsSync) private var userSettingsSync
    @Environment(\.connectivity) private var connectivity
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: AIPersonaConfig = .default
    @State private var saveError: String?
    @State private var isSaving = false
    
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

            if let saveError {
                Section {
                    PlotErrorBanner(message: saveError, onRetry: nil)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("AI の口調")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
                    .disabled(isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(isSaving)
            }
        }
        .overlay {
            if isSaving {
                PlotLoadingOverlay(message: "保存しています…")
            }
        }
        .onAppear {
            draft = appSettings.aiPersona
            saveError = nil
        }
        .plotAnalyticsScreen(.aiPersona)
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

    private func save() {
        saveError = nil
        isSaving = true
        appSettings.aiPersona = draft

        Task { @MainActor in
            let result = await userSettingsSync.pushAIPersona(draft, isOnline: connectivity.isOnline)
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        AIPersonaSettingsView()
            .environment(\.appSettings, AppSettings())
    }
}
