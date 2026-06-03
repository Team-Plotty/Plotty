import SwiftUI

// MARK: - 予定作成シート
struct CalendarCreateSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftStart: Date
    @Binding var draftEnd: Date
    @Binding var draftSwatch: AccentSwatch
    @Binding var draftLocation: String
    @Binding var draftNotes: String
    @Binding var draftIsAllDay: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PlotFormCard(title: "内容") {
                        TextField("タイトル", text: $draftTitle)
                            .font(.scaledBodyLarge())
                            .foregroundStyle(textColor)
                            .onChange(of: draftTitle) { _, newValue in
                                draftTitle = PlotInputLimits.clamp(newValue, max: PlotInputLimits.title)
                            }
                        PlotCharacterCountFooter(
                            current: draftTitle.count,
                            maximum: PlotInputLimits.title
                        )
                        
                        TextField("場所（任意）", text: $draftLocation)
                            .font(.scaledBodyMedium())
                            .foregroundStyle(textColor)
                            .onChange(of: draftLocation) { _, newValue in
                                draftLocation = PlotInputLimits.clamp(newValue, max: PlotInputLimits.location)
                            }
                        
                        Toggle("終日", isOn: $draftIsAllDay)
                    }
                    
                    PlotFormCard(title: "日時") {
                        if draftIsAllDay {
                            DatePicker("日付", selection: $draftStart, displayedComponents: [.date])
                        } else {
                            DatePicker("開始", selection: $draftStart, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("終了", selection: $draftEnd, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                    
                    PlotFormCard(title: "メモ") {
                        TextField("メモ（任意）", text: $draftNotes, axis: .vertical)
                            .font(.scaledBodyMedium())
                            .foregroundStyle(textColor)
                            .lineLimit(3...6)
                            .onChange(of: draftNotes) { _, newValue in
                                draftNotes = PlotInputLimits.clamp(newValue, max: PlotInputLimits.eventNotes)
                            }
                        PlotCharacterCountFooter(
                            current: draftNotes.count,
                            maximum: PlotInputLimits.eventNotes
                        )
                    }
                    
                    PlotFormCard(title: "カラー") {
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
                                .accessibilityLabel(sw.title)
                                .accessibilityAddTraits(draftSwatch == sw ? .isSelected : [])
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
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
        .frame(maxWidth: .infinity)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
