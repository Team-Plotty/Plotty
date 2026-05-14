import SwiftUI

// MARK: - アンビエント背景（アプリ全体の奥行きのある背景）
/// アプリ全体の背面背景。iOS 26 の Liquid Glass を前提に、背面は「単色」で統一する。
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        base
            .ignoresSafeArea()
    }
    
    // MARK: - 下地の単色
    private var base: some View {
        colorScheme == .dark ? Color.darkBase : Color.lightAmbientBase
    }
}

// MARK: - 背景を重ねる View 修飾子
struct AmbientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AmbientBackground()
            content
        }
    }
}

extension View {
    /// 背面に `AmbientBackground` を敷く。`animated` は将来用の互換パラメータ（現状未使用）。
    func ambientBackground(animated: Bool = false) -> some View {
        modifier(AmbientBackgroundModifier())
    }
}

#Preview("ダークモード") {
    VStack {
        Text("Plotty")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}

#Preview("ライトモード") {
    VStack {
        Text("Plotty")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.black)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AmbientBackground())
    .preferredColorScheme(.light)
}
