import Foundation
import CoreLocation

public protocol LocationServiceProtocol: AnyObject, Sendable {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func getCurrentLocation() async -> LocationData?
}
