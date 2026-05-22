import SwiftUI

// MARK: - 月切り替えヘッダー
struct CalendarMonthNavigation: View {
    @Environment(\.colorScheme) private var colorScheme
    let monthAnchor: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
            
            Spacer()
            
            Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                .font(.scaledTitleSmall())
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
