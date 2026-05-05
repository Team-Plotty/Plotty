import Foundation

struct GroqProvider: AIProvider {
    func complete(prompt: String) async throws -> String {
        throw URLError(.notConnectedToInternet)
    }
}
