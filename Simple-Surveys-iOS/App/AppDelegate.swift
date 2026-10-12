import UIKit
import UserNotifications

public extension Notification.Name {
    static let openSurveyFromNotification = Notification.Name("openSurveyFromNotification")
}

public final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let apiClient: APIClientProtocol = APIClient(baseURL: AppConfiguration.apiBaseURL)

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // Post anonymous token to backend
        Task {
            let payload = DeviceRegistration(
                deviceToken: tokenString,
                platform: .ios,
                timezone: TimeZone.current.identifier,
                registeredAt: Date()
            )
            let _: DeviceRegistrationResponse? = try? await apiClient.post("/api/notifications/devices", body: payload)
        }
    }

    // Handle incoming notification when user taps banner
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let surveyId = userInfo["survey_id"] as? String else { return }

        let sentAtString = userInfo["notification_sent_at"] as? String
        let isoFormatter = ISO8601DateFormatter()
        let sentAtDate = sentAtString.flatMap { isoFormatter.date(from: $0) }

        // Route app to survey screen with temporal marker
        NotificationCenter.default.post(
            name: .openSurveyFromNotification,
            object: nil,
            userInfo: [
                "survey_id": surveyId,
                "notification_sent_at": sentAtDate as Any
            ]
        )
    }
}
