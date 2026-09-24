import SwiftUI

public struct HeaderView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var formattedTime: String {
        guard let date = store.lastUpdate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // App Branding
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("ROUTER CHECK")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tracking(1.0)
                    Text("Live Diagnostic Dashboard")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(store.status.color)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(store.status.color.opacity(0.4), lineWidth: 2)
                            .scaleEffect(store.status == .connected ? 1.4 : 1.0)
                    )
                Text(store.status.title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )

            // Cell Recovery Button (Prominently next to status)
            Button {
                Task { await store.startCellRecovery() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: store.isRecovering ? "arrow.triangle.2.circlepath" : "bolt.badge.automatic.fill")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(store.isRecovering ? 360 : 0))
                        .animation(store.isRecovering ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isRecovering)
                    Text(store.isRecovering ? "Kurtarılıyor..." : "⚡ Hücreyi Kurtar")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(store.isRecovering)
            .help("Hücre ve bant kaydını sıfırlamak için 3G -> 4G geçişini başlatır")

            // Auto-refresh & Manual refresh controls
            HStack(spacing: 6) {
                if !formattedTime.isEmpty {
                    Text(formattedTime)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Button {
                    store.toggleAutoRefresh()
                } label: {
                    Label(
                        store.autoRefresh ? "Durdur" : "Başlat",
                        systemImage: store.autoRefresh ? "pause.fill" : "play.fill"
                    )
                    .font(.caption2)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(store.autoRefresh ? .orange : .green)
                .help(store.autoRefresh ? "Otomatik yoklamayı durdur" : "Otomatik yoklamayı başlat")

                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                        .animation(
                            store.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: store.isRefreshing
                        )
                }
                .buttonStyle(.bordered)
                .disabled(store.isRefreshing)
                .help("Şimdi Yenile")
            }
            .padding(4)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Actions (Settings & Login/Logout)
            HStack(spacing: 6) {
                Button {
                    store.isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help("Ayarlar")

                if store.status == .connected {
                    Button {
                        Task { await store.logout() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                    .help("Çıkış Yap")
                } else {
                    Button {
                        Task { await store.login() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Giriş Yap")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
    }
}
