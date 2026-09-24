import SwiftUI

public struct CellRecoveryBannerView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var accentColor: Color {
        switch store.recoveryStep {
        case .completed:
            return Color(red: 0.18, green: 0.84, blue: 0.45)
        case .failed:
            return Color(red: 0.96, green: 0.26, blue: 0.35)
        default:
            return Color.orange
        }
    }

    private var statusIcon: String {
        switch store.recoveryStep {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        default:
            return "bolt.badge.automatic.fill"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: statusIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.recoveryStep.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    Text(store.recoveryMessage.isEmpty ? "İşlem devam ediyor..." : store.recoveryMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if store.isRecovering {
                    Button(role: .destructive) {
                        store.abortCellRecovery()
                    } label: {
                        Text("İptal Et")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        store.dismissRecovery()
                    } label: {
                        Text("Kapat")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.7), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(store.recoveryProgress))
                        .animation(.easeInOut(duration: 0.3), value: store.recoveryProgress)
                }
            }
            .frame(height: 5)

            // Step pills
            HStack(spacing: 6) {
                stepBadge(title: "1. Bağlantı Kes", isActive: store.recoveryProgress >= 0.1, isDone: store.recoveryProgress >= 0.3)
                stepBadge(title: "2. 3G Modu", isActive: store.recoveryProgress >= 0.35, isDone: store.recoveryProgress >= 0.6)
                stepBadge(title: "3. 4G/Oto", isActive: store.recoveryProgress >= 0.65, isDone: store.recoveryProgress >= 0.85)
                stepBadge(title: "4. Bağlan", isActive: store.recoveryProgress >= 0.9, isDone: store.recoveryProgress >= 1.0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.1), radius: 6, x: 0, y: 2)
    }

    private func stepBadge(title: String, isActive: Bool, isDone: Bool) -> some View {
        HStack(spacing: 3) {
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
            }
            Text(title)
                .font(.system(size: 9, weight: isActive ? .semibold : .regular))
                .foregroundColor(isDone ? .primary : (isActive ? accentColor : .secondary.opacity(0.6)))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? accentColor.opacity(0.12) : Color.primary.opacity(0.04))
        )
        .frame(maxWidth: .infinity)
    }
}
