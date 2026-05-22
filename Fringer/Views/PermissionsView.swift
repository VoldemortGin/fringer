import SwiftUI

struct PermissionsView: View {
    let permissionsManager: PermissionsManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Fringer Needs Permissions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("To manage your menu bar items, Fringer needs the following permission:")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                PermissionRow(
                    title: "Screen Recording",
                    description: "Required to detect and capture menu bar item icons",
                    isGranted: permissionsManager.screenRecordingGranted,
                    action: { permissionsManager.requestScreenRecording() }
                )
            }

            if permissionsManager.allPermissionsGranted {
                Text("All permissions granted! You're all set.")
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
            }
        }
        .padding(32)
        .frame(width: 450)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isGranted ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isGranted {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isGranted ? Color.green.opacity(0.05) : Color.secondary.opacity(0.05))
        )
    }
}
