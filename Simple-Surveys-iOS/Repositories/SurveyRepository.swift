import Foundation

public final class SurveyRepository: SurveyRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let jsonEncoder: JSONEncoder

    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    /// Fetches the specific survey configuration scheduled at the given time (e.g., prompted via notification)
    public func fetchScheduledSurvey(id: String) async throws -> SurveyConfig {
        return try await apiClient.get("/api/surveys/\(id)")
    }

    /// Submits a completed or expired survey response with optional surroundings photo
    public func submitResponse(
        submission: SurveyResponseSubmission,
        imageData: Data?
    ) async throws -> SurveySubmissionReceipt {
        if let imageData = imageData {
            let jsonData = try jsonEncoder.encode(submission)
            return try await apiClient.uploadMultipart(
                "/api/responses",
                jsonData: jsonData,
                imageBytes: imageData,
                imageFilename: "surroundings.jpg"
            )
        } else {
            return try await apiClient.post("/api/responses", body: submission)
        }
    }

    /// Registers the anonymous APNs device token to receive daily scheduled survey notifications
    public func registerDevice(token: String, timezone: String) async throws -> DeviceRegistrationResponse {
        let payload = DeviceRegistration(
            deviceToken: token,
            platform: .ios,
            timezone: timezone,
            registeredAt: Date()
        )
        return try await apiClient.post("/api/notifications/devices", body: payload)
    }
}
