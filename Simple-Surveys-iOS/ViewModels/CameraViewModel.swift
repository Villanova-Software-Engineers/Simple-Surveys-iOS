import SwiftUI
import Observation

@Observable
public final class CameraViewModel {
    public var capturedImage: CapturedImage?
    public var errorMessage: String?
    public var isCameraAuthorized: Bool = false

    private let cameraService: CameraServiceProtocol

    public init(cameraService: CameraServiceProtocol = CameraService()) {
        self.cameraService = cameraService
        self.isCameraAuthorized = cameraService.isAuthorized
    }

    public func checkAuthorization() async {
        isCameraAuthorized = cameraService.isAuthorized
    }

    public func handleCapturedImage(_ image: UIImage) {
        if let compressed = cameraService.compressImage(image) {
            self.capturedImage = compressed
            self.errorMessage = nil
        } else {
            self.errorMessage = "Failed to process photo."
        }
    }

    public func clearPhoto() {
        self.capturedImage = nil
    }
}
