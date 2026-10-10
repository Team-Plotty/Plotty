import SwiftUI

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
