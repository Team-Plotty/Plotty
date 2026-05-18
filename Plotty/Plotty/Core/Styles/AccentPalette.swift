import SwiftUI

/// メモや予定の色分けに使う、アクセント色のプリセット一覧。
enum AccentSwatch: String, CaseIterable, Identifiable {
    case graphite
    case paper
    case sage
    case sky
    case coral
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .graphite: return "チャコール"
        case .paper: return "ペーパー"
        case .sage: return "セージ"
        case .sky: return "スカイ"
        case .coral: return "コーラル"
        }
    }
    
    /// セグメントコントロール用の短いラベル
    var segmentTitle: String {
        switch self {
        case .graphite: return "グレー"
        case .paper: return "ペーパ"
        case .sage: return "セージ"
        case .sky: return "スカイ"
        case .coral: return "コーラ"
        }
    }
    
    var color: Color {
        switch self {
        case .graphite:
            return Color(hex: "#6B6A68")
        case .paper:
            return Color(hex: "#C9C4BC")
        case .sage:
            return Color(hex: "#8FA894")
        case .sky:
            return Color(hex: "#8BA7C4")
        case .coral:
            return Color(hex: "#C98F8F")
        }
    }
}
