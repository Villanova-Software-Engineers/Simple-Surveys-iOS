import SwiftUI

public struct OnboardingView: View {
    @Bindable public var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Header Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.navy.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.navy)
                }

                // Welcome Title
                VStack(spacing: 8) {
                    Text("Simple Surveys")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppTheme.navy)

                    Text("Experience Sampling Study")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.gold)
                        .textCase(.uppercase)
                }

                // Onboarding Explanation Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Study Participation Requirements")
                        .font(.headline)
                        .foregroundColor(AppTheme.navy)

                    Text("To participate in this study, Simple Surveys needs permission to send scheduled prompts, verify survey locations, and capture surroundings photos.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)

                    Divider()

                    // Permissions list items
                    permissionRow(icon: "bell.badge.fill", title: "Push Notifications", detail: "Alerts you during active survey sampling windows.")
                    permissionRow(icon: "location.fill", title: "GPS Location", detail: "Attaches approximate coordinates at the moment of submission.")
                    permissionRow(icon: "camera.fill", title: "Camera Access", detail: "Allows you to capture an image of your immediate surroundings.")
                }
                .padding(24)
                .background(AppTheme.pureWhite)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.gold.opacity(0.3), lineWidth: 1))
                .shadow(color: AppTheme.navy.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Enable Permissions Button
                Button(action: {
                    Task { await viewModel.enablePermissions() }
                }) {
                    HStack {
                        if viewModel.isRequesting {
                            ProgressView().tint(AppTheme.pureWhite)
                        } else {
                            Text("Enable Permissions")
                                .font(.headline.bold())
                                .foregroundColor(AppTheme.pureWhite)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.headline)
                                .foregroundColor(AppTheme.lightBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.navy)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.lightBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.navy)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
