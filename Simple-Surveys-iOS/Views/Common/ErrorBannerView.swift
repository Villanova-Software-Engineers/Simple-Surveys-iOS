import SwiftUI

public struct ErrorBannerView: View {
    public let message: String
    public let onRetry: (() -> Void)?

    public init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
                .lineLimit(2)

            Spacer()

            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .font(.footnote.bold())
                    .foregroundColor(AppTheme.navy)
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
