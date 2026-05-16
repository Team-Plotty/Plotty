import SwiftUI

// MARK: - 新規メモ作成シート
struct MemoCreateSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftContent: String
    @Binding var draftAccent: AccentSwatch
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField("タイトル", text: $draftTitle)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                TextField("本文（任意）", text: $draftContent, axis: .vertical)
                    .font(.scaledBodyMedium())
                    .foregroundStyle(textColor)
                    .lineLimit(3...8)
                
                Text("カラー")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(AccentSwatch.allCases) { swatch in
                        Button {
                            draftAccent = swatch
                        } label: {
                            Circle()
                                .fill(swatch.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            draftAccent == swatch ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .navigationTitle("新しいメモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("保存", action: onSave)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
