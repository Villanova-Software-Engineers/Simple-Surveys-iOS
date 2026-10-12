import Foundation

public enum DevicePlatform: String, Codable, Sendable {
    case ios = "ios"
    case android = "android"
}

public struct DeviceRegistration: Codable, Sendable {
    public let deviceToken: String
    public let platform: DevicePlatform
    public let timezone: String
    public let registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case platform
        case timezone
        case registeredAt = "registered_at"
    }

    public init(
        deviceToken: String,
        platform: DevicePlatform = .ios,
        timezone: String,
        registeredAt: Date = Date()
    ) {
        self.deviceToken = deviceToken
        self.platform = platform
        self.timezone = timezone
        self.registeredAt = registeredAt
    }
}

public struct DeviceRegistrationResponse: Codable, Sendable {
    public let status: String
    public let deviceToken: String

    enum CodingKeys: String, CodingKey {
        case status
        case deviceToken = "device_token"
    }

    public init(status: String, deviceToken: String) {
        self.status = status
        self.deviceToken = deviceToken
    }
}
