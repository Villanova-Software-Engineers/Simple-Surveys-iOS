import SwiftUI

@main
struct SimpleSurveysApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var onboardingViewModel: OnboardingViewModel
    @State private var homeViewModel: HomeViewModel

    private let apiClient: APIClientProtocol
    private let repository: SurveyRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let cameraService: CameraServiceProtocol
    private let permissionManager: PermissionManagerProtocol

    init() {
        let client = APIClient(baseURL: AppConfiguration.apiBaseURL)
        let repo = SurveyRepository(apiClient: client)
        let loc = LocationService()
        let cam = CameraService()
        let perms = PermissionManager(locationService: loc, cameraService: cam)

        self.apiClient = client
        self.repository = repo
        self.locationService = loc
        self.cameraService = cam
        self.permissionManager = perms

        _onboardingViewModel = State(initialValue: OnboardingViewModel(permissionManager: perms, repository: repo))
        _homeViewModel = State(initialValue: HomeViewModel(repository: repo, permissionManager: perms))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboardingViewModel.hasCompletedOnboarding {
                    OnboardingView(viewModel: onboardingViewModel)
                } else {
                    HomeView(
                        viewModel: homeViewModel,
                        repository: repository,
                        locationService: locationService
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSurveyFromNotification)) { notification in
                if let userInfo = notification.userInfo,
                   let surveyId = userInfo["survey_id"] as? String {
                    let sentAt = userInfo["notification_sent_at"] as? Date
                    Task {
                        await homeViewModel.handleIncomingSurveyPrompt(surveyId: surveyId, sentAt: sentAt)
                    }
                }
            }
        }
    }
}
