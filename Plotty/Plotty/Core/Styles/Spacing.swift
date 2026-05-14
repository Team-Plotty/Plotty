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
    static let screenEdge: CGFloat = 35
    
    /// タブバーの高さ（FooterTabBar で使用）
    static let tabBarHeight: CGFloat = 60
    
    /// 右下 FAB（56pt）の下端からの余白。タブバーの上に配置されるよう調整。
    static let floatingAddButtonBottomInset: CGFloat = tabBarHeight + md
    
    /// スクロール末尾の干渉を避けるための追加下余白（FAB高＋下オフセット＋余白）
    static let floatingAddButtonClearance: CGFloat = 56 + floatingAddButtonBottomInset + lg
    
    /// `ContentView` の `TabView` に付ける FAB 用の下余白（メインコンテンツを「上に寄せ」FAB と干渉しにくくする）
    static let fabMainContentBottomInset: CGFloat = 56 + md + sm
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
