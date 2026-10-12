import SwiftUI

public struct LoadingView: View {
    public let message: String

    public init(message: String = "Loading...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppTheme.navy)
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(AppTheme.pureWhite)
        .cornerRadius(12)
        .shadow(color: AppTheme.navy.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
