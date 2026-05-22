import SwiftUI

// MARK: - 余白（8pt グリッド・HIG に沿った段階）
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    /// 画面左右の余白（指で持ちやすい幅の目安）
    static let screenEdge: CGFloat = 25
    
    /// タブバーの高さ（FooterTabBar のタブ行で使用）
    static let tabBarHeight: CGFloat = 60
    
    /// HIG 推奨の最小タップ領域（44pt）
    static let minTouchTarget: CGFloat = 44
    
    /// ＋ボタンとタブ行のすき間（タブバー最下端基準）
    static let floatingAddGapAboveTabBar: CGFloat = screenEdge
    
    /// チャット入力欄とタブ行のすき間（`ChatTabView` 下端はタブ inset 直上）
    static let chatComposerGapAboveTabBar: CGFloat = 16
    
    /// メモ・TODO・カレンダー一覧のスクロール末尾に足す下余白（＋はタブ上にオーバーレイ）
    static let tabbedScrollBottomInset: CGFloat = 56 + floatingAddGapAboveTabBar
    
    /// チャット入力ドック分のスクロール余白（タブバー高さは含めない・inset で確保済み）
    static let chatComposerScrollClearance: CGFloat =
        84 + minTouchTarget * 3 + sm + xs + xxs * 2
}

// MARK: - 余白用のショートカット（View 拡張）
extension View {
    func paddingXXS() -> some View {
        padding(Spacing.xxs)
    }
    
    func paddingXS() -> some View {
        padding(Spacing.xs)
    }
    
    func paddingSM() -> some View {
        padding(Spacing.sm)
    }
    
    func paddingMD() -> some View {
        padding(Spacing.md)
    }
    
    func paddingLG() -> some View {
        padding(Spacing.lg)
    }
    
    func paddingXL() -> some View {
        padding(Spacing.xl)
    }
    
    func paddingXXL() -> some View {
        padding(Spacing.xxl)
    }
}
