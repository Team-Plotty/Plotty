import Foundation

protocol AIProvider: Sendable {
    func complete(prompt: String) async throws -> String
}
