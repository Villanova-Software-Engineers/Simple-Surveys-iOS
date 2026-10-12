import Foundation

public protocol PermissionManagerProtocol: AnyObject, Sendable {
    var areAllPermissionsGranted: Bool { get }
    func checkPermissionStatus() async -> Bool
    func requestAllPermissions() async -> Bool
}
