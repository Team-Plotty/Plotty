import Foundation
import OSLog
import SwiftUI

// MARK: - 画面識別子（`11` §2.4）

enum PlotAnalyticsScreen: String, Sendable {
    case chat
    case todo
    case memo
    case calendar
    case settings
    case login
    case signUp
    case emailOTP
    case account
    case help
    case terms
    case privacy
    case openSource
    case aiPersona
    case profileEdit
}

// MARK: - 計測（OSLog。MVP は端末ログのみ。将来 SDK 差し替え可能）

enum PlotAnalytics {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Plotty",
        category: "analytics"
    )

    static func trackScreen(_ screen: PlotAnalyticsScreen) {
        logger.info("event=screen_view screen=\(screen.rawValue, privacy: .public)")
    }

    static func trackCreate(
        entityType: PlotEntityType,
        source: String,
        screen: PlotAnalyticsScreen? = nil
    ) {
        logMutation(
            event: "create",
            entityType: entityType,
            source: source,
            screen: screen
        )
    }

    static func trackUpdate(
        entityType: PlotEntityType,
        source: String,
        screen: PlotAnalyticsScreen? = nil
    ) {
        logMutation(
            event: "update",
            entityType: entityType,
            source: source,
            screen: screen
        )
    }

    static func trackDelete(
        entityType: PlotEntityType,
        source: String,
        screen: PlotAnalyticsScreen? = nil
    ) {
        logMutation(
            event: "delete",
            entityType: entityType,
            source: source,
            screen: screen
        )
    }

    /// 認証・設定同期など API 以外の失敗
    static func trackFailure(
        action: String,
        error: Error,
        screen: PlotAnalyticsScreen? = nil,
        entityType: PlotEntityType? = nil
    ) {
        let code = errorCode(from: error)
        let requestId = requestId(from: error)
        logFailure(
            action: action,
            code: code,
            requestId: requestId,
            screen: screen,
            entityType: entityType
        )
    }

    static func trackFailure(
        action: String,
        code: String,
        screen: PlotAnalyticsScreen? = nil,
        entityType: PlotEntityType? = nil,
        requestId: String? = nil
    ) {
        logFailure(
            action: action,
            code: code,
            requestId: requestId,
            screen: screen,
            entityType: entityType
        )
    }

    static func trackAuthSuccess(action: String, provider: AuthProvider) {
        logger.info(
            "event=auth_success action=\(action, privacy: .public) provider=\(provider.rawValue, privacy: .public)"
        )
    }

    static func trackAuthFailure(action: String, error: AuthError, provider: AuthProvider?) {
        let providerLabel = provider?.rawValue ?? "unknown"
        logger.error(
            "event=failure action=\(action, privacy: .public) provider=\(providerLabel, privacy: .public) code=\(error.analyticsCode, privacy: .public)"
        )
    }

    // MARK: - Private

    private static func logMutation(
        event: String,
        entityType: PlotEntityType,
        source: String,
        screen: PlotAnalyticsScreen?
    ) {
        if let screen {
            logger.info(
                "event=\(event, privacy: .public) entity=\(entityType.rawValue, privacy: .public) source=\(source, privacy: .public) screen=\(screen.rawValue, privacy: .public)"
            )
        } else {
            logger.info(
                "event=\(event, privacy: .public) entity=\(entityType.rawValue, privacy: .public) source=\(source, privacy: .public)"
            )
        }
    }

    private static func logFailure(
        action: String,
        code: String,
        requestId: String?,
        screen: PlotAnalyticsScreen?,
        entityType: PlotEntityType?
    ) {
        let requestPart = requestId.map { " request_id=\($0)" } ?? ""
        let screenPart = screen.map { " screen=\($0.rawValue)" } ?? ""
        let entityPart = entityType.map { " entity=\($0.rawValue)" } ?? ""
        logger.error(
            "event=failure action=\(action, privacy: .public) code=\(code, privacy: .public)\(screenPart, privacy: .public)\(entityPart, privacy: .public)\(requestPart, privacy: .public)"
        )
    }

    private static func errorCode(from error: Error) -> String {
        if let apiError = error as? PlotAPIError {
            return apiError.apiErrorCode?.rawValue ?? apiError.analyticsFallbackCode
        }
        if let authError = error as? AuthError {
            return authError.analyticsCode
        }
        if let syncError = error as? UserProfileSyncError {
            return syncError.analyticsCode
        }
        return String(describing: type(of: error))
    }

    private static func requestId(from error: Error) -> String? {
        (error as? PlotAPIError)?.requestId
    }
}

// MARK: - View 表示計測

private struct PlotAnalyticsScreenModifier: ViewModifier {
    let screen: PlotAnalyticsScreen

    func body(content: Content) -> some View {
        content.onAppear {
            PlotAnalytics.trackScreen(screen)
        }
    }
}

extension View {
    func plotAnalyticsScreen(_ screen: PlotAnalyticsScreen) -> some View {
        modifier(PlotAnalyticsScreenModifier(screen: screen))
    }
}

// MARK: - タブ → 画面

extension TabItem {
    var analyticsScreen: PlotAnalyticsScreen {
        switch self {
        case .memo: return .memo
        case .todo: return .todo
        case .chat: return .chat
        case .calendar: return .calendar
        case .settings: return .settings
        }
    }
}

// MARK: - エラーコード（計測用）

extension AuthError {
    fileprivate var analyticsCode: String {
        switch self {
        case .invalidEmail: return "invalid_email"
        case .offline: return "offline"
        case .providerUnavailable: return "provider_unavailable"
        case .appleRelayHint: return "apple_relay_hint"
        case .otpDeliveryFailed: return "otp_delivery_failed"
        case .otpVerificationFailed: return "otp_verification_failed"
        case .logoutFailed: return "logout_failed"
        case .deleteAccountFailed: return "delete_account_failed"
        }
    }
}

extension UserProfileSyncError {
    fileprivate var analyticsCode: String {
        switch self {
        case .offline: return "offline"
        case .pullFailed: return "profile_pull_failed"
        case .pushFailed: return "profile_push_failed"
        }
    }
}

extension PlotAPIError {
    fileprivate var analyticsFallbackCode: String {
        switch self {
        case .missingAccessToken: return "missing_access_token"
        case .invalidURL: return "invalid_url"
        case .transport: return "transport_error"
        case .encoding: return "encoding_error"
        case .decoding: return "decoding_error"
        case .unexpectedResponse(let status, _): return "unexpected_http_\(status)"
        case .api, .unknownAPI: return "api_error"
        }
    }
}
