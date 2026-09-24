import SwiftUI

public struct MenuBarPopoverView: View {
    @Bindable public var store: RouterStore
    @Environment(\.openWindow) private var openWindow

    public init(store: RouterStore) {
        self.store = store
    }

    private var data: RouterData? { store.routerData }
    private var rsrp: Int? { data?.rsrpValue }
    private var sinr: Double? { data?.sinrValue }
    private var rsrpGrade: SignalGrade { SignalGrade.forRsrp(rsrp) }
    private var sinrGrade: SignalGrade { SignalGrade.forSinr(sinr) }

    private var rsrpPercentage: Double {
        guard let v = rsrp else { return 0 }
        return max(0, min(1, Double(v + 120) / 60.0))
    }

    private var formattedTime: String {
        guard let date = store.lastUpdate else { return "--:--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private var routerTitle: String {
        if let hw = data?.hardware_version, !hw.isEmpty {
            return "ZTE \(hw)"
        }
        return "Router Check"
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routerTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(store.status == .connected ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)

                        Text(store.status == .connected ? "Güncel · \(formattedTime)" : store.status.title)
                            .font(.caption2)
                            .foregroundColor(store.status == .connected ? Color.secondary : Color.orange)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await store.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                        .animation(store.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isRefreshing)
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
                .disabled(store.isRefreshing)
                .help("Anlık veriyi yenile")
            }

            if store.status != .connected {
                VStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text("Modem Bağlantısı Yok")
                        .font(.headline)

                    Text(store.status.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Ana Pencereyi Aç") {
                        openMainWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }
                .padding(.vertical, 16)
            } else {
                // Recovery banner if active
                if store.recoveryStep != .idle {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text(store.recoveryMessage.isEmpty ? "Hücre kurtarma işlemi devam ediyor..." : store.recoveryMessage)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Top Signal Bar (Mirrors BatterySOCView in Deye)
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(rsrpGrade.color)

                            Text("Sinyal Gücü (RSRP)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(rsrpGrade.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(rsrpGrade.color)

                            Text(rsrp != nil ? "\(rsrp!) dBm" : "--")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [rsrpGrade.color.opacity(0.8), rsrpGrade.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(rsrpPercentage))))
                                .shadow(color: rsrpGrade.color.opacity(0.3), radius: 3, x: 0, y: 0)
                        }
                    }
                    .frame(height: 7)
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        }
                }

                // 2x2 Grid for Key Metrics (Mirrors EnergyCard grid in Deye)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    let dl = data?.dlSpeedBps
                    let ul = data?.ulSpeedBps
                    let dlMax = store.dlHistory.max()
                    let ulMax = store.ulHistory.max()

                    MetricCard(
                        title: "İndirme",
                        icon: "arrow.down.circle.fill",
                        valueText: Formatters.formatSpeed(bps: dl),
                        subtitle: dlMax != nil && dlMax! > 0 ? "Pik: \(Formatters.formatSpeed(bps: dlMax))" : "Aktif Hız",
                        tintColor: .cyan
                    )

                    MetricCard(
                        title: "Yükleme",
                        icon: "arrow.up.circle.fill",
                        valueText: Formatters.formatSpeed(bps: ul),
                        subtitle: ulMax != nil && ulMax! > 0 ? "Pik: \(Formatters.formatSpeed(bps: ulMax))" : "Aktif Hız",
                        tintColor: .purple
                    )

                    MetricCard(
                        title: "SNR (Kalite)",
                        icon: "chart.bar.fill",
                        valueText: sinr != nil ? String(format: "%.1f dB", sinr!) : "--",
                        subtitle: sinrGrade.rawValue,
                        tintColor: sinrGrade.color
                    )

                    let cell = data?.cell_id ?? ""
                    let earfcn = data?.Z_dl_earfcn ?? ""
                    let net = data?.network_type ?? "LTE"

                    MetricCard(
                        title: "Hücre (Cell ID)",
                        icon: "antenna.radiowaves.left.and.right",
                        valueText: cell.isEmpty ? "--" : cell,
                        subtitle: !earfcn.isEmpty ? "EARFCN: \(earfcn) · \(net)" : net,
                        tintColor: .blue
                    )
                }
            }

            Divider()

            // Footer Actions
            HStack {
                Button("Ana Pencere") {
                    openMainWindow()
                }
                .buttonStyle(.link)
                .font(.caption)

                Text("·").foregroundStyle(.secondary)

                Button(store.isRecovering ? "Kurtarılıyor..." : "⚡ Hücreyi Kurtar") {
                    Task { await store.startCellRecovery() }
                }
                .buttonStyle(.link)
                .font(.caption)
                .disabled(store.isRecovering)

                Spacer()

                Button("Çıkış") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 360)
        .preferredColorScheme(store.colorScheme)
    }

    private func openMainWindow() {
        if WindowManager.shared.mainWindow == nil {
            openWindow(id: "main")
        }
        WindowManager.shared.showMainWindow()
    }
}

private struct MetricCard: View {
    let title: String
    let icon: String
    let valueText: String
    let subtitle: String?
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tintColor)
                    .frame(width: 28, height: 28)
                    .background(tintColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(valueText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(tintColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
    }
}
