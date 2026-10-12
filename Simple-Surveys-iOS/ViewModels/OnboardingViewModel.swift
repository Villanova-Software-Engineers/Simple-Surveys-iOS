import SwiftUI
import Observation

@Observable
public final class OnboardingViewModel {
    public var isRequesting: Bool = false
    public var errorMessage: String?
    public var hasCompletedOnboarding: Bool = false

    private let permissionManager: PermissionManagerProtocol
    private let repository: SurveyRepositoryProtocol

    public init(permissionManager: PermissionManagerProtocol, repository: SurveyRepositoryProtocol) {
        self.permissionManager = permissionManager
        self.repository = repository
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    public func enablePermissions() async {
        isRequesting = true
        errorMessage = nil

        let allGranted = await permissionManager.requestAllPermissions()
        if allGranted {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            hasCompletedOnboarding = true
        } else {
            errorMessage = "All permissions (Notifications, Location, Camera) are required to participate in this study. Please enable them to continue."
        }
        isRequesting = false
    }
}
