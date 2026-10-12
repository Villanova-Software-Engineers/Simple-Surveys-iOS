import Foundation

public enum AppConfiguration {
    /// Base URL for the Simple Surveys backend API
    public static var apiBaseURL: URL {
        #if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:8000")!
        #else
        return URL(string: "http://127.0.0.1:8000")!
        #endif
    }
    
    /// Default network request timeout
    public static let requestTimeout: TimeInterval = 30.0
    
    /// Default survey expiration time in minutes if not specified
    public static let defaultTimeToCompleteMinutes: Int = 5
    
    /// Max image dimension for camera uploads
    public static let maxImageDimension: CGFloat = 1920.0
    
    /// JPEG compression quality for camera uploads
    public static let imageCompressionQuality: CGFloat = 0.8
}
