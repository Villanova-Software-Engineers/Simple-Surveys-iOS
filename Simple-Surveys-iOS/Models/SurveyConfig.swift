import Foundation

// MARK: - Survey Configuration
public struct SurveyConfig: Codable, Identifiable, Sendable {
    public var id: String { surveyId }
    public let surveyId: String
    public let title: String
    public let description: String?
    public let notificationPrompt: NotificationPrompt?
    public let weight: Double
    public let isActive: Bool
    public let questions: [Question]

    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
        case title
        case description
        case notificationPrompt = "notification_prompt"
        case weight
        case isActive = "is_active"
        case questions
    }

    public init(
        surveyId: String,
        title: String,
        description: String? = nil,
        notificationPrompt: NotificationPrompt? = nil,
        weight: Double = 1.0,
        isActive: Bool = true,
        questions: [Question] = []
    ) {
        self.surveyId = surveyId
        self.title = title
        self.description = description
        self.notificationPrompt = notificationPrompt
        self.weight = weight
        self.isActive = isActive
        self.questions = questions
    }
}

public struct NotificationPrompt: Codable, Sendable {
    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
