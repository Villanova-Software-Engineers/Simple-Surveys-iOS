import SwiftUI
import Observation

@Observable
public final class HomeViewModel {
    public var activeSurvey: SurveyConfig?
    public var notificationSentAt: Date?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var arePermissionsValid: Bool = true

    private let repository: SurveyRepositoryProtocol
    private let permissionManager: PermissionManagerProtocol

    public init(
        repository: SurveyRepositoryProtocol,
        permissionManager: PermissionManagerProtocol
    ) {
        self.repository = repository
        self.permissionManager = permissionManager
    }

    public func checkPermissions() async {
        let valid = await permissionManager.checkPermissionStatus()
        await MainActor.run {
            self.arePermissionsValid = valid
        }
    }

    public func handleIncomingSurveyPrompt(surveyId: String, sentAt: Date?) async {
        isLoading = true
        errorMessage = nil
        self.notificationSentAt = sentAt

        do {
            let survey = try await repository.fetchScheduledSurvey(id: surveyId)
            await MainActor.run {
                self.activeSurvey = survey
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load scheduled survey: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    public func clearActiveSurvey() {
        self.activeSurvey = nil
        self.notificationSentAt = nil
    }
}
