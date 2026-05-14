import SwiftUI

/// 画面上部のヘッダー。左にアプリ名、右にアカウント導線。
struct PlotRootBreadcrumb: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// 縦区切りの高さ（文字サイズ設定に `@ScaledMetric` で追従）
    @ScaledMetric(relativeTo: .title) private var titleDividerHeight: CGFloat = 28
    
    let screenTitle: String
    var onAccountTapped: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text("Plotty")
                    .font(.scaledTitleLarge())
                    .foregroundStyle(primary)
                
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(tertiary)
                    .frame(width: 2, height: titleDividerHeight)
                    .accessibilityHidden(true)
                
                Text(screenTitle)
                    .font(.scaledBodyMedium())
                    .fontWeight(.medium)
                    .foregroundStyle(secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .truncationMode(.tail)
                    .animation(.quick, value: screenTitle)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onAccountTapped) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(primary)
                    .accessibilityLabel("アカウント")
            }
            .buttonStyle(GlassIconButtonStyle())
        }
        .padding(.leading, Spacing.screenEdge + Spacing.sm)
        .padding(.trailing, Spacing.screenEdge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Plotty、\(screenTitle)")
    }
    
    private var primary: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondary: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiary: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}
