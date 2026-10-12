import Foundation

// MARK: - Ingress Submission Payload (Client -> Server)
public struct SurveyResponseSubmission: Codable, Sendable {
    public let responseId: String?
    public let surveyId: String
    public let notificationSentAt: Date?
    public let startedAt: Date
    public let completedAt: Date
    public let location: LocationData?
    public let answers: [QuestionAnswer]

    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case surveyId = "survey_id"
        case notificationSentAt = "notification_sent_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case location
        case answers
    }

    public init(
        responseId: String? = nil,
        surveyId: String,
        notificationSentAt: Date? = nil,
        startedAt: Date,
        completedAt: Date,
        location: LocationData? = nil,
        answers: [QuestionAnswer]
    ) {
        self.responseId = responseId
        self.surveyId = surveyId
        self.notificationSentAt = notificationSentAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.location = location
        self.answers = answers
    }
}

public struct QuestionAnswer: Codable, Sendable {
    public let questionId: String
    public let value: AnyCodableValue

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case value
    }

    public init(questionId: String, value: AnyCodableValue) {
        self.questionId = questionId
        self.value = value
    }
}

// MARK: - Server Response Receipt
public struct SurveySubmissionReceipt: Codable, Sendable {
    public let responseId: String
    public let surveyId: String
    public let status: String           // "COMPLETED" or "EXPIRED"
    public let message: String?
    public let imageStored: Bool
    public let imageFilename: String?
    public let receivedAt: Date

    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case surveyId = "survey_id"
        case status
        case message
        case imageStored = "image_stored"
        case imageFilename = "image_filename"
        case receivedAt = "received_at"
    }

    public init(
        responseId: String,
        surveyId: String,
        status: String,
        message: String? = nil,
        imageStored: Bool = false,
        imageFilename: String? = nil,
        receivedAt: Date = Date()
    ) {
        self.responseId = responseId
        self.surveyId = surveyId
        self.status = status
        self.message = message
        self.imageStored = imageStored
        self.imageFilename = imageFilename
        self.receivedAt = receivedAt
    }
}
