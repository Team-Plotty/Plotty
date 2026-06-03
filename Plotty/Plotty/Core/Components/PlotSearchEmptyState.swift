import SwiftUI

// MARK: - 検索結果なしの空状態
enum PlotSearchEmptyResource {
    case memo
    case todo
    
    func title(searchText: String, language: AppLanguage) -> String {
        let quoted = "「\(searchText)」"
        switch (self, language) {
        case (.memo, .japanese):
            return "\(quoted)に一致するメモは見つかりませんでした"
        case (.todo, .japanese):
            return "\(quoted)に一致するタスクは見つかりませんでした"
        case (.memo, .english):
            return "No memos found for \"\(searchText)\""
        case (.todo, .english):
            return "No tasks found for \"\(searchText)\""
        }
    }
    
    func description(language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "別のキーワードで検索してみてください"
        case .english:
            return "Try searching with a different keyword"
        }
    }
}

struct PlotSearchEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let searchText: String
    let resource: PlotSearchEmptyResource
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(secondaryColor)
            
            Text(resource.title(searchText: searchText, language: appSettings.language))
                .font(.scaledBodyLarge())
                .foregroundStyle(secondaryColor)
                .multilineTextAlignment(.center)
            
            Text(resource.description(language: appSettings.language))
                .font(.scaledBodySmall())
                .foregroundStyle(tertiaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.screenEdge)
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}

// MARK: - フィルタ結果なしの空状態
struct PlotFilterEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let resource: PlotSearchEmptyResource
    
    private var title: String {
        switch (resource, appSettings.language) {
        case (.memo, .japanese): return "該当するメモがありません"
        case (.todo, .japanese): return "該当するタスクがありません"
        case (.memo, .english): return "No matching memos"
        case (.todo, .english): return "No matching tasks"
        }
    }
    
    private var description: String {
        switch appSettings.language {
        case .japanese: return "フィルタ条件を変えてみてください"
        case .english: return "Try changing your filters"
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: resource == .memo ? "doc.text" : "checklist")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(secondaryColor)
            
            Text(title)
                .font(.scaledBodyLarge())
                .foregroundStyle(secondaryColor)
            
            Text(description)
                .font(.scaledBodySmall())
                .foregroundStyle(tertiaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.screenEdge)
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}
