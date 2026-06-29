import SwiftUI

// MARK: - プロフィール同期エラー
enum UserProfileSyncError: LocalizedError, Equatable {
    case offline
    case pullFailed
    case pushFailed

    var errorDescription: String? {
        switch self {
        case .offline:
            return "インターネットに接続してから、もう一度お試しください。"
        case .pullFailed:
            return "クラウドの設定を取得できませんでした。"
        case .pushFailed:
            return "設定の保存に失敗しました。しばらくしてから再試行してください。"
        }
    }
}

// MARK: - `public.users` とローカル設定の双方向同期
@Observable
@MainActor
final class UserSettingsSync {
    private let appSettings: AppSettings
    private weak var accountSession: AccountSession?

    private(set) var isSyncing = false
    private(set) var isApplyingRemote = false
    private(set) var lastError: String?

    init(appSettings: AppSettings, accountSession: AccountSession) {
        self.appSettings = appSettings
        self.accountSession = accountSession
        accountSession.onProfileSyncNeeded = { [weak self] in
            await self?.pullFromRemote()
        }
    }

    func clearLastError() {
        lastError = nil
    }

    /// ログイン直後などにクラウド → 端末へ反映する。
    func pullFromRemote() async {
        guard accountSession?.isAuthenticated == true else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let profile = try await UserProfileService.fetchCurrentUserProfile()
            isApplyingRemote = true
            appSettings.applyRemoteProfile(
                timezoneIdentifier: profile.timezoneIdentifier,
                aiPersona: profile.aiPersona
            )
            if let displayName = profile.displayName {
                accountSession?.applyRemoteDisplayName(displayName)
            }
            isApplyingRemote = false
            lastError = nil
        } catch {
            isApplyingRemote = false
            lastError = UserProfileSyncError.pullFailed.localizedDescription
        }
    }

    func pushDisplayName(_ name: String, isOnline: Bool) async -> Result<Void, UserProfileSyncError> {
        guard isOnline else { return .failure(.offline) }
        guard accountSession?.isAuthenticated == true else { return .success(()) }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await UserProfileService.updateProfile(displayName: name)
            lastError = nil
            return .success(())
        } catch {
            lastError = UserProfileSyncError.pushFailed.localizedDescription
            return .failure(.pushFailed)
        }
    }

    func pushTimezone(_ identifier: String, isOnline: Bool) async -> Result<Void, UserProfileSyncError> {
        guard isOnline else { return .failure(.offline) }
        guard accountSession?.isAuthenticated == true else { return .success(()) }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await UserProfileService.updateProfile(timezoneIdentifier: identifier)
            lastError = nil
            return .success(())
        } catch {
            lastError = UserProfileSyncError.pushFailed.localizedDescription
            return .failure(.pushFailed)
        }
    }

    func pushAIPersona(_ config: AIPersonaConfig, isOnline: Bool) async -> Result<Void, UserProfileSyncError> {
        guard isOnline else { return .failure(.offline) }
        guard accountSession?.isAuthenticated == true else { return .success(()) }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await UserProfileService.updateProfile(aiPersona: config)
            lastError = nil
            return .success(())
        } catch {
            lastError = UserProfileSyncError.pushFailed.localizedDescription
            return .failure(.pushFailed)
        }
    }
}

private struct UserSettingsSyncKey: EnvironmentKey {
    static let defaultValue = UserSettingsSync(
        appSettings: AppSettings(),
        accountSession: AccountSession(supabaseEnabled: false)
    )
}

extension EnvironmentValues {
    var userSettingsSync: UserSettingsSync {
        get { self[UserSettingsSyncKey.self] }
        set { self[UserSettingsSyncKey.self] = newValue }
    }
}
