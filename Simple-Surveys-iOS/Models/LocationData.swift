import Foundation

public struct LocationData: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let accuracyMeters: Double?
    public let altitudeMeters: Double?

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case accuracyMeters = "accuracy_meters"
        case altitudeMeters = "altitude_meters"
    }

    public init(
        latitude: Double,
        longitude: Double,
        accuracyMeters: Double? = nil,
        altitudeMeters: Double? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracyMeters = accuracyMeters
        self.altitudeMeters = altitudeMeters
    }
}
