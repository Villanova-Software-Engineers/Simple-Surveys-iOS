import SwiftUI

public struct ExpiredSurveyView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.gold)

            Text("Survey Window Expired")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("This experience sampling prompt was not completed within the allotted time. An audit record has been recorded.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
