import SwiftUI

public struct TimerBadgeView: View {
    public let remainingSeconds: Int

    public init(remainingSeconds: Int) {
        self.remainingSeconds = remainingSeconds
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(timeString(from: remainingSeconds))
                .monospacedDigit()
                .bold()
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(remainingSeconds < 60 ? Color.red.opacity(0.15) : AppTheme.lightBlue.opacity(0.15))
        .foregroundColor(remainingSeconds < 60 ? .red : AppTheme.navy)
        .clipShape(Capsule())
    }

    private func timeString(from secs: Int) -> String {
        let mins = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", mins, s)
    }
}
