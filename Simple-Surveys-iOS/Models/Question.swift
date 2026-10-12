import Foundation

// MARK: - Polymorphic Question Model
public struct Question: Codable, Identifiable, Sendable {
    public var id: String { questionId }
    public let questionId: String
    public let prompt: String
    public let type: QuestionType
    public let isRequired: Bool
    public let validationRules: ValidationRules?

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case prompt
        case type
        case isRequired = "is_required"
        case validationRules = "validation_rules"
    }

    public init(
        questionId: String,
        prompt: String,
        type: QuestionType,
        isRequired: Bool = true,
        validationRules: ValidationRules? = nil
    ) {
        self.questionId = questionId
        self.prompt = prompt
        self.type = type
        self.isRequired = isRequired
        self.validationRules = validationRules
    }
}

public enum QuestionType: String, Codable, Sendable {
    case ratingScale = "rating_scale"
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case text = "text"
    case numeric = "numeric"
}

public struct ValidationRules: Codable, Sendable {
    public let minValue: Double?
    public let maxValue: Double?
    public let step: Double?
    public let minLabel: String?
    public let maxLabel: String?
    public let options: [String]?
    public let minSelections: Int?
    public let maxSelections: Int?
    public let minLength: Int?
    public let maxLength: Int?
    public let placeholder: String?
    public let allowDecimals: Bool?

    enum CodingKeys: String, CodingKey {
        case minValue = "min_value"
        case maxValue = "max_value"
        case step
        case minLabel = "min_label"
        case maxLabel = "max_label"
        case options
        case minSelections = "min_selections"
        case maxSelections = "max_selections"
        case minLength = "min_length"
        case maxLength = "max_length"
        case placeholder
        case allowDecimals = "allow_decimals"
    }

    public init(
        minValue: Double? = nil,
        maxValue: Double? = nil,
        step: Double? = nil,
        minLabel: String? = nil,
        maxLabel: String? = nil,
        options: [String]? = nil,
        minSelections: Int? = nil,
        maxSelections: Int? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        placeholder: String? = nil,
        allowDecimals: Bool? = nil
    ) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.options = options
        self.minSelections = minSelections
        self.maxSelections = maxSelections
        self.minLength = minLength
        self.maxLength = maxLength
        self.placeholder = placeholder
        self.allowDecimals = allowDecimals
    }
}
