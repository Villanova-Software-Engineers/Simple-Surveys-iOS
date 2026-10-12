import SwiftUI
import Observation

@Observable
public final class SurveyViewModel {
    // State
    public var survey: SurveyConfig
    public var answers: [String: AnyCodableValue] = [:]
    public var capturedImage: CapturedImage?
    public var isSubmitting: Bool = false
    public var isExpired: Bool = false
    public var remainingSeconds: Int = 0
    public var errorMessage: String?
    public var submissionCompleted: Bool = false

    private let notificationSentAt: Date?
    private let startedAt: Date
    private let timeToCompleteMinutes: Int
    private var timerTask: Task<Void, Never>?

    private let repository: SurveyRepositoryProtocol
    private let locationService: LocationServiceProtocol

    public init(
        survey: SurveyConfig,
        notificationSentAt: Date?,
        timeToCompleteMinutes: Int = 5,
        repository: SurveyRepositoryProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.survey = survey
        self.notificationSentAt = notificationSentAt
        self.startedAt = Date()
        self.timeToCompleteMinutes = timeToCompleteMinutes
        self.repository = repository
        self.locationService = locationService

        calculateInitialRemainingTime()
        startCountdownTimer()
    }

    private func calculateInitialRemainingTime() {
        let referenceDate = notificationSentAt ?? startedAt
        let deadline = referenceDate.addingTimeInterval(Double(timeToCompleteMinutes * 60))
        let remaining = Int(deadline.timeIntervalSince(Date()))
        self.remainingSeconds = max(0, remaining)
        if self.remainingSeconds == 0 {
            self.isExpired = true
        }
    }

    private func startCountdownTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while remainingSeconds > 0 && !isExpired && !submissionCompleted {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remainingSeconds -= 1
                if remainingSeconds <= 0 {
                    isExpired = true
                    handleExpiration()
                }
            }
        }
    }

    private func handleExpiration() {
        // Automatically submit expired audit record with empty answers
        Task {
            await submitResponse(isForcedExpired: true)
        }
    }

    public func submitResponse(isForcedExpired: Bool = false) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil

        let location = await locationService.getCurrentLocation()
        let completedAt = Date()

        // Per backend plan: if expired, answers must be autofilled empty []
        let answersPayload: [QuestionAnswer]
        if isForcedExpired || isExpired {
            answersPayload = []
        } else {
            answersPayload = survey.questions.compactMap { q in
                guard let val = answers[q.questionId] else { return nil }
                return QuestionAnswer(questionId: q.questionId, value: val)
            }
        }

        let submission = SurveyResponseSubmission(
            responseId: nil,
            surveyId: survey.surveyId,
            notificationSentAt: notificationSentAt,
            startedAt: startedAt,
            completedAt: completedAt,
            location: location,
            answers: answersPayload
        )

        do {
            _ = try await repository.submitResponse(
                submission: submission,
                imageData: capturedImage?.data
            )
            submissionCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    deinit {
        timerTask?.cancel()
    }
}
