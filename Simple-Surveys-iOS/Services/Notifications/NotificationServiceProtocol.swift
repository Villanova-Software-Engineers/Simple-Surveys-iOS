import Foundation

public protocol NotificationServiceProtocol: AnyObject, Sendable {
    var isAuthorized: Bool { get async }
    func requestAuthorization() async -> Bool
}
