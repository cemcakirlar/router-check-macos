import SwiftUI

public struct SpeedCardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var dlSpeed: Double? { store.routerData?.dlSpeedBps }
    private var ulSpeed: Double? { store.routerData?.ulSpeedBps }
    private var sessionBytes: Int64? { store.routerData?.sessionTotalBytes }

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
                        .foregroundColor(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 18) {
                // Download
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.cyan)
                        Text("İndirme (Download)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(Formatters.formatSpeed(bps: dlSpeed))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)

                    SparklineView(
                        points: store.dlHistory,
                        strokeColor: .cyan,
                        fillColor: Color.cyan.opacity(0.15)
                    )

                    HStack {
                        statItem(label: "Min", val: dlStats.min)
                        Spacer()
                        statItem(label: "Ort", val: dlStats.avg)
                        Spacer()
                        statItem(label: "Maks", val: dlStats.max)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Upload
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.purple)
                        Text("Yükleme (Upload)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(Formatters.formatSpeed(bps: ulSpeed))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)

                    SparklineView(
                        points: store.ulHistory,
                        strokeColor: .purple,
                        fillColor: Color.purple.opacity(0.15)
                    )

                    HStack {
                        statItem(label: "Min", val: ulStats.min)
                        Spacer()
                        statItem(label: "Ort", val: ulStats.avg)
                        Spacer()
                        statItem(label: "Maks", val: ulStats.max)
                    }
                }
                .frame(maxWidth: .infinity)
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

    private func statItem(label: String, val: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(val)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
    }
}
