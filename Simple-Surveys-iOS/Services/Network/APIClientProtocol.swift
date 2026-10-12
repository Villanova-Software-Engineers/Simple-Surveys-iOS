import Foundation

public protocol APIClientProtocol: Sendable {
    func get<T: Decodable>(_ path: String) async throws -> T
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func uploadMultipart<T: Decodable>(
        _ path: String,
        jsonData: Data,
        imageBytes: Data?,
        imageFilename: String?
    ) async throws -> T
}
