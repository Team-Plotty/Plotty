import SwiftUI

// MARK: - 一覧カード用・団子メニュー（編集 / 削除）
struct PlotCardMenuButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let onEdit: () -> Void
    let onDelete: () -> Void
    var pinAction: PinAction?
    
    struct PinAction {
        let title: String
        let systemImage: String
        let handler: () -> Void
    }
    
    var body: some View {
        Menu {
            Button(action: onEdit) {
                Label("編集", systemImage: "pencil")
            }
            
            if let pinAction {
                Button(action: pinAction.handler) {
                    Label(pinAction.title, systemImage: pinAction.systemImage)
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: Spacing.minTouchTarget, height: Spacing.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("その他の操作")
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

// MARK: - カード＋団子メニュー行（ガラス面は行全体）
struct PlotCardActionRow<Content: View>: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    var pinAction: PlotCardMenuButton.PinAction?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PlotCardMenuButton(
                onEdit: onEdit,
                onDelete: onDelete,
                pinAction: pinAction
            )
            .padding(.top, Spacing.xxs)
            .padding(.trailing, Spacing.xxs)
        }
        .background {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }
}
