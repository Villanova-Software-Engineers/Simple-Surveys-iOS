import Foundation
import UserNotifications
import UIKit

public final class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationService()

    public var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    public override init() {
        super.init()
    }

    public func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted: Bool = await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { res, _ in
                continuation.resume(returning: res)
            }
        }
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted
    }
}
