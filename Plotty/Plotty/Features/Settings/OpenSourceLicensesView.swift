import SwiftUI

// MARK: - オープンソースライセンス
struct OpenSourceLicense: Identifiable {
    let id = UUID()
    let name: String
    let license: String
    let url: String?
}

struct OpenSourceLicensesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let libraries: [OpenSourceLicense] = [
        OpenSourceLicense(name: "SwiftUI", license: "Apple SDK License", url: "https://developer.apple.com"),
        OpenSourceLicense(name: "SF Symbols", license: "Apple SF Symbols License", url: nil),
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(libraries) { lib in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(lib.name)
                            .font(.scaledBodyLarge().weight(.semibold))
                            .foregroundStyle(primaryColor)
                        Text(lib.license)
                            .font(.scaledCaption())
                            .foregroundStyle(secondaryColor)
                        if let url = lib.url, let link = URL(string: url) {
                            Link("ライセンスを見る", destination: link)
                                .font(.scaledCaption())
                        }
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("オープンソース")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
        .plotAnalyticsScreen(.openSource)
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

#Preview {
    NavigationStack {
        OpenSourceLicensesView()
            .ambientBackground()
    }
}
