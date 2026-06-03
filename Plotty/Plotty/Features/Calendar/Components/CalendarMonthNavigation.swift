import SwiftUI

// MARK: - 月切り替えヘッダー
struct CalendarMonthNavigation: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let monthAnchor: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CompactGlassIconButtonStyle())
            
            Spacer()
            
            Text(PlotDateFormatter.yearMonth(monthAnchor, language: appSettings.language))
                .font(.scaledTitleSmall())
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CompactGlassIconButtonStyle())
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}

// MARK: - コンパクトなガラスアイコンボタン（Liquid Glass）
private struct CompactGlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassEffect(.regular.interactive(), in: Circle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
