import SwiftUI

public struct SystemInfoCardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var data: RouterData? { store.routerData }

    private var monthlyTotal: Int64? { data?.monthlyTotalBytes }
    private var monthlyRx: Int64? { Int64(data?.monthly_rx_bytes ?? "") }
    private var monthlyTx: Int64? { Int64(data?.monthly_tx_bytes ?? "") }
    private var monthlyTime: Int64? { Int64(data?.monthly_time ?? "") }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Aylık Kullanım & Cihaz", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let provider = data?.network_provider, !provider.isEmpty {
                    Text(provider)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            // Monthly stats row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Aylık Toplam Veri")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Formatters.formatBytes(monthlyTotal))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    if let time = monthlyTime {
                        Text("Süre: \(Formatters.formatDuration(seconds: time))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("DL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Formatters.formatBytes(monthlyRx))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    HStack(spacing: 6) {
                        Text("UL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Formatters.formatBytes(monthlyTx))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }

            Divider()

            // System details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow(label: "Cihaz / HW", value: data?.hardware_version ?? "--")
                infoRow(label: "Yazılım / FW", value: data?.cr_version ?? (data?.wa_version ?? "--"))
                infoRow(label: "IMEI", value: data?.imei ?? "--")
                infoRow(label: "MSISDN", value: data?.msisdn ?? "--")
                infoRow(label: "Okunmamış SMS", value: data?.sms_unread_num ?? "0")
                infoRow(label: "Seçili Şebeke", value: data?.net_select ?? "--")
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

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}
