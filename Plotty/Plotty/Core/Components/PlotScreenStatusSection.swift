import SwiftUI

// MARK: - 一覧画面用の状態カード（offline / error）
struct PlotScreenStatusSection: View {
    let isOffline: Bool
    let errorMessage: String?
    var onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            if isOffline {
                PlotOfflineBanner()
            }
            if let errorMessage {
                PlotErrorBanner(message: errorMessage, onRetry: onRetry)
            }
        }
    }
}

// MARK: - 初回読み込みオーバーレイ
struct PlotListLoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    PlotLoadingOverlay(message: message)
                }
            }
            .allowsHitTesting(!isLoading)
    }
}

extension View {
    func plotListLoading(_ isLoading: Bool, message: String = "読み込み中…") -> some View {
        modifier(PlotListLoadingModifier(isLoading: isLoading, message: message))
    }
}
