import SwiftUI

public struct PhotoPreviewCard: View {
    public let image: UIImage?
    public let onTapCapture: () -> Void
    public let onTapRemove: () -> Void

    public init(
        image: UIImage?,
        onTapCapture: @escaping () -> Void,
        onTapRemove: @escaping () -> Void
    ) {
        self.image = image
        self.onTapCapture = onTapCapture
        self.onTapRemove = onTapRemove
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(AppTheme.navy)
                Text("Surroundings Photo (Optional)")
                    .font(.headline)
                    .foregroundColor(AppTheme.navy)
                Spacer()
            }

            if let image = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(10)

                    Button(action: onTapRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                            .padding(8)
                    }
                }
            } else {
                Button(action: onTapCapture) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.headline)
                        Text("Capture Surroundings Photo")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(AppTheme.navy)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundColor(AppTheme.lightBlue)
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
        .shadow(color: AppTheme.navy.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
