import Foundation
import UserNotifications
import UIKit

public final class PermissionManager: PermissionManagerProtocol, @unchecked Sendable {
    private let locationService: LocationServiceProtocol
    private let cameraService: CameraServiceProtocol

    public init(locationService: LocationServiceProtocol, cameraService: CameraServiceProtocol) {
        self.locationService = locationService
        self.cameraService = cameraService
    }

    public var areAllPermissionsGranted: Bool {
        // Synchronous fast check for location & camera; notification checked asynchronously
        locationService.isAuthorized && cameraService.isAuthorized
    }

    public func checkPermissionStatus() async -> Bool {
        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        let notifAuthorized = (notifSettings.authorizationStatus == .authorized || notifSettings.authorizationStatus == .provisional)
        return notifAuthorized && locationService.isAuthorized && cameraService.isAuthorized
    }

    public func requestAllPermissions() async -> Bool {
        // 1. Push Notifications
        let notifGranted: Bool = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        if notifGranted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        // 2. CoreLocation GPS
        let locGranted = await locationService.requestAuthorization()

        // 3. Camera Capture
        let camGranted = await cameraService.requestAuthorization()

        return notifGranted && locGranted && camGranted
    }
}
