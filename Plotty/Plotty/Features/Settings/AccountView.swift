import SwiftUI

// MARK: - アカウント（設定からシートで開く想定。メイン画面と同じ余白・ガラスカード）
struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("ログインやプロフィールは今後ここにまとめます。")
                    .font(.scaledBodyMedium())
                    .foregroundStyle(secondaryTextColor)
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("この画面は今後、ログイン状態やプロフィールなどをまとめる場所として使えます。")
                        .font(.scaledBodyMedium())
                        .foregroundStyle(secondaryTextColor)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("アカウント")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(primaryTextColor)
                }
                .buttonStyle(GlassIconButtonStyle())
                .accessibilityLabel("閉じる")
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .ambientBackground()
    }
    .preferredColorScheme(.dark)
}
