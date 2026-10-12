import UIKit
import AVFoundation

public struct CapturedImage: Sendable {
    public let data: Data
    public let previewImage: UIImage
    
    public init(data: Data, previewImage: UIImage) {
        self.data = data
        self.previewImage = previewImage
    }
}

public protocol CameraServiceProtocol: Sendable {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func compressImage(_ image: UIImage) -> CapturedImage?
}
