import Foundation

public enum APIEndpoint {
    case registerDevice
    case getSurvey(id: String)
    case submitResponse
    
    public var path: String {
        switch self {
        case .registerDevice:
            return "/api/notifications/devices"
        case .getSurvey(let id):
            return "/api/surveys/\(id)"
        case .submitResponse:
            return "/api/responses"
        }
    }
}
