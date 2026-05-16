import SwiftUI

// MARK: - 予定作成シート
struct CalendarCreateSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftStart: Date
    @Binding var draftEnd: Date
    @Binding var draftSwatch: AccentSwatch
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField("タイトル", text: $draftTitle)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                DatePicker("開始", selection: $draftStart, displayedComponents: [.date, .hourAndMinute])
                DatePicker("終了", selection: $draftEnd, displayedComponents: [.date, .hourAndMinute])
                
                Text("カラー")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(AccentSwatch.allCases) { sw in
                        Button {
                            draftSwatch = sw
                        } label: {
                            Circle()
                                .fill(sw.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(draftSwatch == sw ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .navigationTitle("予定を追加")
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
