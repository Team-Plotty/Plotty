import Foundation

// MARK: - HTTP メソッド

enum PlotAPIHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Edge API クライアント（C1）

/// Plotty Edge Functions（`plotty-api`）への JSON API 呼び出し。
/// - Bearer: Supabase access token
/// - エラー: `PlotAPIError`（`request_id` 付き Edge エラーを mapping）
actor PlotAPIClient {
    static let shared = PlotAPIClient()

    private let config: SupabaseConfig.Values
    private let tokenProvider: any PlotAPIAccessTokenProviding
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        config: SupabaseConfig.Values? = nil,
        tokenProvider: (any PlotAPIAccessTokenProviding)? = nil,
        session: URLSession = .shared
    ) {
        self.config = (try? config) ?? (try? SupabaseConfig.load()) ?? Self.fallbackConfig()
        self.tokenProvider = tokenProvider ?? SupabasePlotAPIAccessTokenProvider()
        self.session = session

        self.decoder = PlotAPICodec.makeJSONDecoder()
        self.encoder = PlotAPICodec.makeJSONEncoder()
    }

    /// `api/v1/...` 形式の相対パスへ JSON リクエストし、レスポンス body をデコードする。
    func request<Response: Decodable>(
        method: PlotAPIHTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> Response {
        let data = try await performRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body
        )
        do {
            return try decoder.decode(Response.self, from: data)
        } catch let error as DecodingError {
            throw PlotAPIError.decoding(error)
        }
    }

    /// レスポンス body を期待しない API 用（将来の 204 等）。
    func requestVoid(
        method: PlotAPIHTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) async throws {
        _ = try await performRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            body: body
        )
    }

    // MARK: - Private

    private func performRequest(
        method: PlotAPIHTTPMethod,
        path: String,
        queryItems: [URLQueryItem]?,
        body: (any Encodable)?
    ) async throws -> Data {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await tokenProvider.accessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw PlotAPIError.encoding(error)
            }
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw PlotAPIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw PlotAPIError.unexpectedResponse(httpStatus: -1, bodyPreview: nil)
        }

        guard (200 ... 299).contains(http.statusCode) else {
            throw parseAPIError(httpStatus: http.statusCode, data: data)
        }

        return data
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]?) throws -> URL {
        var components = URLComponents(
            url: config.edgeAPIURL(relativePath: path),
            resolvingAgainstBaseURL: false
        )
        if components == nil {
            throw PlotAPIError.invalidURL
        }
        if let queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw PlotAPIError.invalidURL
        }
        return url
    }

    private func parseAPIError(httpStatus: Int, data: Data) -> PlotAPIError {
        if let payload = try? decoder.decode(PlotAPIErrorPayload.self, from: data) {
            let body = payload.error
            if let code = PlotAPIErrorCode(rawValue: body.code) {
                let message = body.message.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolved = message.isEmpty ? code.defaultUserMessage : message
                return .api(
                    code: code,
                    message: resolved,
                    requestId: body.requestId,
                    httpStatus: httpStatus
                )
            }
            return .unknownAPI(
                code: body.code,
                message: body.message,
                requestId: body.requestId,
                httpStatus: httpStatus
            )
        }

        let preview = String(data: data.prefix(240), encoding: .utf8)
        return .unexpectedResponse(httpStatus: httpStatus, bodyPreview: preview)
    }

    /// Preview / ユニットテスト向け。plist 未設定時はクラッシュさせない。
    private static func fallbackConfig() -> SupabaseConfig.Values {
        guard let url = URL(string: "https://example.invalid/functions/v1/plotty-api") else {
            preconditionFailure("fallback Edge API URL")
        }
        return SupabaseConfig.Values(
            supabaseURL: url,
            anonKey: "fallback",
            edgeAPIBaseURL: url
        )
    }
}

// MARK: - Encodable 型消去

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
