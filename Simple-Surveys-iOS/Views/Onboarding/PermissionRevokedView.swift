import SwiftUI

public struct PermissionRevokedView: View {
    public let onRecheck: () -> Void

    public init(onRecheck: @escaping () -> Void) {
        self.onRecheck = onRecheck
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.gold)

            Text("Permissions Required")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)

            Text("One or more required permissions (Push Notifications, Location, or Camera) were revoked in Settings. Please restore all permissions to continue participating in today's surveys.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Button("Open iOS Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.navy)
            .controlSize(.large)

            Button("Check Status Again") {
                onRecheck()
            }
            .font(.subheadline)
            .foregroundColor(AppTheme.lightBlue)
        }
        .padding()
    }
}
