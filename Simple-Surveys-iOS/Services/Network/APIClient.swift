import Foundation

public final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }

    public func get<T: Decodable>(_ path: String) async throws -> T {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let requestURL = baseURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    public func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let requestURL = baseURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    public func uploadMultipart<T: Decodable>(
        _ path: String,
        jsonData: Data,
        imageBytes: Data?,
        imageFilename: String?
    ) async throws -> T {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let requestURL = baseURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body = Data()

        // 1. Append JSON data field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"data\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n".data(using: .utf8)!)

        // 2. Append image file field if present
        if let imageBytes = imageBytes {
            let filename = imageFilename ?? "surroundings.jpg"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageBytes)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try jsonDecoder.decode(T.self, from: data)
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let serverErrorMsg = String(data: data, encoding: .utf8) ?? "Unknown Server Error"
            throw NetworkError.serverError(code: http.statusCode, message: serverErrorMsg)
        }
    }
}

public enum NetworkError: LocalizedError {
    case serverError(code: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        }
    }
}
