import SwiftUI

public struct SurveyCompletedView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.lightBlue)

            Text("Check-In Submitted")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("Thank you! Your survey response has been saved anonymously.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
