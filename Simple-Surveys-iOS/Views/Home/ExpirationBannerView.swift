import SwiftUI

public struct ExpirationBannerView: View {
    public let remainingSeconds: Int

    public init(remainingSeconds: Int) {
        self.remainingSeconds = remainingSeconds
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundColor(AppTheme.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Survey Prompt Active")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.navy)

                Text("Time to complete remaining: \(timeString(from: remainingSeconds))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.gold)
        }
        .padding()
        .background(AppTheme.gold.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private func timeString(from secs: Int) -> String {
        let mins = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", mins, s)
    }
}
