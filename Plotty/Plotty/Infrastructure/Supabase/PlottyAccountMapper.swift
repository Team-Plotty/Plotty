import Foundation
import Supabase

/// Supabase Auth の `User` をアプリ内 `PlottyAccount` に変換する。
enum PlottyAccountMapper {
    static func makeAccount(from user: User) -> PlottyAccount {
        PlottyAccount(
            id: user.id,
            displayName: resolveDisplayName(user: user),
            email: user.email ?? "",
            provider: resolveProvider(user: user)
        )
    }

    private static func resolveDisplayName(user: User) -> String {
        let candidates = [
            user.userMetadata["full_name"]?.stringValue,
            user.userMetadata["name"]?.stringValue,
            user.userMetadata["display_name"]?.stringValue,
        ]
        if let name = candidates.compactMap({ $0 }).first(where: { !$0.isEmpty }) {
            return name
        }
        if let email = user.email,
           let local = email.split(separator: "@").first,
           !local.isEmpty {
            return String(local)
        }
        return "Plotty ユーザー"
    }

    private static func resolveProvider(user: User) -> AuthProvider {
        if let provider = user.appMetadata["provider"]?.stringValue,
           let mapped = mapProvider(provider) {
            return mapped
        }
        if let identity = user.identities?.first,
           let mapped = mapProvider(identity.provider) {
            return mapped
        }
        return .email
    }

    private static func mapProvider(_ raw: String) -> AuthProvider? {
        switch raw {
        case "google": return .google
        case "apple": return .apple
        case "email": return .email
        default: return nil
        }
    }
}
