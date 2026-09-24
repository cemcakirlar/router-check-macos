import SwiftUI

public struct SpeedCardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var dlSpeed: Double? { store.routerData?.dlSpeedBps }
    private var ulSpeed: Double? { store.routerData?.ulSpeedBps }
    private var sessionBytes: Int64? { store.routerData?.sessionTotalBytes }

    private var dlParts: (value: String, unit: String) {
        Formatters.formatSpeedParts(bps: dlSpeed)
    }

    private var ulParts: (value: String, unit: String) {
        Formatters.formatSpeedParts(bps: ulSpeed)
    }

    private var dlPercentage: Double {
        guard let speed = dlSpeed, speed > 0 else { return 0 }
        let peak = max(store.dlHistory.max() ?? 0, 50_000_000)
        return min(1.0, speed / peak)
    }

    private var ulPercentage: Double {
        guard let speed = ulSpeed, speed > 0 else { return 0 }
        let peak = max(store.ulHistory.max() ?? 0, 20_000_000)
        return min(1.0, speed / peak)
    }

    private var dlStats: (min: String, avg: String, max: String) {
        guard !store.dlHistory.isEmpty else { return ("--", "--", "--") }
        let minVal = store.dlHistory.min() ?? 0
        let maxVal = store.dlHistory.max() ?? 0
        let avgVal = store.dlHistory.reduce(0, +) / Double(store.dlHistory.count)
        return (Formatters.formatSpeed(bps: minVal), Formatters.formatSpeed(bps: avgVal), Formatters.formatSpeed(bps: maxVal))
    }

    private var ulStats: (min: String, avg: String, max: String) {
        guard !store.ulHistory.isEmpty else { return ("--", "--", "--") }
        let minVal = store.ulHistory.min() ?? 0
        let maxVal = store.ulHistory.max() ?? 0
        let avgVal = store.ulHistory.reduce(0, +) / Double(store.ulHistory.count)
        return (Formatters.formatSpeed(bps: minVal), Formatters.formatSpeed(bps: avgVal), Formatters.formatSpeed(bps: maxVal))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Anlık Hızlar", systemImage: "bolt.horizontal.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let session = sessionBytes {
                    Text("Oturum: \(Formatters.formatBytes(session))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .top, spacing: 18) {
                // Download
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.cyan)
                        Text("İndirme (Download)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(dlSpeed != nil ? dlParts.value : "--")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        Text(dlSpeed != nil ? dlParts.unit : "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    SignalMeterView(percentage: dlPercentage, color: .cyan)

                    SparklineView(
                        points: store.dlHistory,
                        strokeColor: .cyan,
                        fillColor: Color.cyan.opacity(0.15)
                    )

                    VStack(spacing: 4) {
                        statRow(label: "MIN", val: dlStats.min)
                        statRow(label: "AVG", val: dlStats.avg)
                        statRow(label: "MAX", val: dlStats.max)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Upload
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.purple)
                        Text("Yükleme (Upload)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(ulSpeed != nil ? ulParts.value : "--")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text(ulSpeed != nil ? ulParts.unit : "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    SignalMeterView(percentage: ulPercentage, color: .purple)

                    SparklineView(
                        points: store.ulHistory,
                        strokeColor: .purple,
                        fillColor: Color.purple.opacity(0.15)
                    )

                    VStack(spacing: 4) {
                        statRow(label: "MIN", val: ulStats.min)
                        statRow(label: "AVG", val: ulStats.avg)
                        statRow(label: "MAX", val: ulStats.max)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            // Session DL & UL Footer
            HStack {
                HStack(spacing: 6) {
                    Text("Oturum DL:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.formatBytes(store.routerData?.sessionRxBytes ?? 0))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("Oturum UL:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.formatBytes(store.routerData?.sessionTxBytes ?? 0))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func statRow(label: String, val: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text(val)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
