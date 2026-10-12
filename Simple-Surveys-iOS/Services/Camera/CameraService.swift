import UIKit
import AVFoundation

public final class CameraService: CameraServiceProtocol {
    public init() {}

    public var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    public func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized { return true }
        if status == .notDetermined {
            return await AVCaptureDevice.requestAccess(for: .video)
        }
        return false
    }

    public func compressImage(_ image: UIImage) -> CapturedImage? {
        // Normalize orientation & downscale if needed
        let maxDimension: CGFloat = 1920
        let size = image.size
        var targetSize = size

        if size.width > maxDimension || size.height > maxDimension {
            let ratio = min(maxDimension / size.width, maxDimension / size.height)
            targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = scaledImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return CapturedImage(data: jpegData, previewImage: scaledImage)
    }
}
