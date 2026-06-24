import Foundation

// MARK: - Edge API エラーコード（edge/src/contracts/errors.ts と同期）

enum PlotAPIErrorCode: String, Decodable, Sendable, CaseIterable {
    case validationError = "VALIDATION_ERROR"
    case unauthorized = "UNAUTHORIZED"
    case forbidden = "FORBIDDEN"
    case notFound = "NOT_FOUND"
    case conflict = "CONFLICT"
    case groqTimeout = "GROQ_TIMEOUT"
    case groqUnavailable = "GROQ_UNAVAILABLE"
    case rateLimited = "RATE_LIMITED"
    case internalError = "INTERNAL_ERROR"

    /// Edge 側 `errorMessageByCode` と同義のフォールバック（レスポンス message が空のとき）
    var defaultUserMessage: String {
        switch self {
        case .validationError:
            return "入力内容を確認して再度お試しください"
        case .unauthorized:
            return "ログイン状態を確認してください"
        case .forbidden:
            return "この操作を実行する権限がありません"
        case .notFound:
            return "対象データが見つかりませんでした"
        case .conflict:
            return "同時更新が発生しました。再取得してお試しください"
        case .groqTimeout:
            return "通信状況を確認して再度お試しください"
        case .groqUnavailable:
            return "AIサービスが混み合っています。少し待って再試行してください"
        case .rateLimited:
            return "リクエストが多すぎます。時間をおいて再試行してください"
        case .internalError:
            return "予期しないエラーが発生しました"
        }
    }
}

// MARK: - Edge エラーレスポンス JSON

struct PlotAPIErrorPayload: Decodable, Sendable {
    struct Body: Decodable, Sendable {
        let code: String
        let message: String
        let requestId: String?

        enum CodingKeys: String, CodingKey {
            case code
            case message
            case requestId = "request_id"
        }
    }

    let error: Body
}

// MARK: - PlotAPIClient が throw するエラー

enum PlotAPIError: Error, Sendable {
    case missingAccessToken
    case invalidURL
    case transport(URLError)
    case encoding(Error)
    case decoding(DecodingError)
    case api(code: PlotAPIErrorCode, message: String, requestId: String?, httpStatus: Int)
    case unknownAPI(code: String, message: String, requestId: String?, httpStatus: Int)
    case unexpectedResponse(httpStatus: Int, bodyPreview: String?)
}

extension PlotAPIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "ログイン状態を確認してください"
        case .invalidURL:
            return "API の URL が不正です"
        case .transport(let urlError):
            return urlError.localizedDescription
        case .encoding:
            return "リクエストの作成に失敗しました"
        case .decoding:
            return "サーバー応答の解析に失敗しました"
        case .api(_, let message, let requestId, _):
            return PlotAPIError.userFacingMessage(message: message, requestId: requestId)
        case .unknownAPI(_, let message, let requestId, _):
            return PlotAPIError.userFacingMessage(message: message, requestId: requestId)
        case .unexpectedResponse(let status, _):
            return "サーバーから予期しない応答がありました（HTTP \(status)）"
        }
    }

    /// ログ・サポート用の参照 ID（E5 計測連携用）
    var requestId: String? {
        switch self {
        case .api(_, _, let requestId, _), .unknownAPI(_, _, let requestId, _):
            return requestId
        default:
            return nil
        }
    }

    private static func userFacingMessage(message: String, requestId: String?) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "エラーが発生しました"
        }
        guard let requestId, !requestId.isEmpty else {
            return trimmed
        }
        return "\(trimmed)\n参照ID: \(requestId)"
    }

    var apiErrorCode: PlotAPIErrorCode? {
        if case .api(let code, _, _, _) = self { return code }
        return nil
    }

    var isGroqTimeout: Bool {
        apiErrorCode == .groqTimeout
    }
}
