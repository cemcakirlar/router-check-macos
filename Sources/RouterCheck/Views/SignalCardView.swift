import SwiftUI

public struct SignalCardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var rsrp: Int? { store.routerData?.rsrpValue }
    private var sinr: Double? { store.routerData?.sinrValue }
    private var cellId: String { store.routerData?.cell_id ?? "" }
    private var earfcn: String { store.routerData?.Z_dl_earfcn ?? "" }

    private var rsrpGrade: SignalGrade { SignalGrade.forRsrp(rsrp) }
    private var sinrGrade: SignalGrade { SignalGrade.forSinr(sinr) }

    private var rsrpPercentage: Double {
        guard let v = rsrp else { return 0 }
        return Double(v + 120) / 60.0
    }

    private var sinrPercentage: Double {
        guard let v = sinr else { return 0 }
        return v / 20.0
    }

    private var rsrpStats: (min: String, avg: String, max: String) {
        guard !store.rsrpHistory.isEmpty else { return ("--", "--", "--") }
        let minVal = store.rsrpHistory.min() ?? 0
        let maxVal = store.rsrpHistory.max() ?? 0
        let avgVal = store.rsrpHistory.reduce(0, +) / Double(store.rsrpHistory.count)
        return (String(format: "%.0f dBm", minVal), String(format: "%.0f dBm", avgVal), String(format: "%.0f dBm", maxVal))
    }

    private var sinrStats: (min: String, avg: String, max: String) {
        guard !store.sinrHistory.isEmpty else { return ("--", "--", "--") }
        let minVal = store.sinrHistory.min() ?? 0
        let maxVal = store.sinrHistory.max() ?? 0
        let avgVal = store.sinrHistory.reduce(0, +) / Double(store.sinrHistory.count)
        return (String(format: "%.1f dB", minVal), String(format: "%.1f dB", avgVal), String(format: "%.1f dB", maxVal))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Şebeke & Sinyal", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let netType = store.routerData?.network_type, !netType.isEmpty {
                    Text(netType)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.15))
                        .foregroundColor(.cyan)
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .top, spacing: 18) {
                // RSRP Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("RSRP (Sinyal Gücü)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(rsrp != nil ? "\(rsrp!)" : "--")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("dBm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(rsrpGrade.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(rsrpGrade.color)
                    }

                    SignalMeterView(percentage: rsrpPercentage, color: rsrpGrade.color)

                    SparklineView(points: store.rsrpHistory, strokeColor: rsrpGrade.color)

                    VStack(spacing: 4) {
                        statRow(label: "MIN", val: rsrpStats.min)
                        statRow(label: "AVG", val: rsrpStats.avg)
                        statRow(label: "MAX", val: rsrpStats.max)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)

                Divider()

                // SINR Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("SINR (Sinyal Kalitesi)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(sinr != nil ? String(format: "%.1f", sinr!) : "--")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("dB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(sinrGrade.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(sinrGrade.color)
                    }

                    SignalMeterView(percentage: sinrPercentage, color: sinrGrade.color)

                    SparklineView(points: store.sinrHistory, strokeColor: sinrGrade.color)

                    VStack(spacing: 4) {
                        statRow(label: "MIN", val: sinrStats.min)
                        statRow(label: "AVG", val: sinrStats.avg)
                        statRow(label: "MAX", val: sinrStats.max)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            // Cell ID & EARFCN Footer
            HStack {
                HStack(spacing: 6) {
                    Text("Cell ID:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cellId.isEmpty ? "--" : cellId)
                        .font(.caption)
                        .fontWeight(.semibold)
                    if !cellId.isEmpty {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cellId, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("EARFCN:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(earfcn.isEmpty ? "--" : earfcn)
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
