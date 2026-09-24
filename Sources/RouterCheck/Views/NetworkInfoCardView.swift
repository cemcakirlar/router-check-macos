import SwiftUI

public struct NetworkInfoCardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    private var data: RouterData? { store.routerData }

    private var pppStatusText: String {
        guard let s = data?.ppp_status, !s.isEmpty else { return "--" }
        if data?.isPppConnected == true { return "Bağlı (Connected)" }
        if data?.isPppDisconnected == true { return "Bağlantı Kesildi" }
        return s.capitalized
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Ağ & LAN", systemImage: "network")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()

                if let sta = data?.wifi_access_sta_num, !sta.isEmpty {
                    Text("\(sta) İstemci")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            // WAN connection stats row (mirrors Monthly stats row in SystemInfoCardView)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("WAN IP Adresi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(data?.wan_ipaddr ?? "--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    HStack(spacing: 5) {
                        Circle()
                            .fill(data?.isPppConnected == true ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                        Text(pppStatusText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if data?.isPppConnected == true {
                        Button {
                            Task { await store.disconnectPPP() }
                        } label: {
                            Label("PPP Bağlantısını Kes", systemImage: "bolt.slash.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            Task { await store.connectPPP() }
                        } label: {
                            Label("PPP Bağlan", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Divider()

            // LAN details grid (mirrors System details grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                infoRow(label: "LAN IP", value: data?.formattedLanIp ?? "--")
                infoRow(label: "Netmask", value: data?.lan_netmask ?? "--")
                infoRow(
                    label: "DHCP",
                    value: data?.dhcpEnabled == "1" ? "Açık" : (data?.dhcpEnabled == "0" ? "Kapalı" : "--")
                )
                infoRow(
                    label: "WiFi İstemciler",
                    value: data?.wifi_access_sta_num ?? "--"
                )
                infoRow(label: "WiFi MAC", value: data?.mac_address ?? "--")
                infoRow(label: "İstemci IP", value: data?.ip_addr_web ?? "--")
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
