import Foundation

public struct RouterData: Codable, Sendable {
    public var lte_rsrp: String?
    public var sinr: String?
    public var cell_id: String?
    public var Z_dl_earfcn: String?
    public var monthly_rx_bytes: String?
    public var monthly_tx_bytes: String?
    public var monthly_time: String?
    public var network_provider: String?
    public var network_type: String?
    public var realtime_rx_thrpt: String?
    public var realtime_tx_thrpt: String?
    public var wan_ipaddr: String?
    public var ppp_status: String?
    public var lan_ipaddr: String?
    public var lan_netmask: String?
    public var dhcpEnabled: String?
    public var mac_address: String?
    public var imei: String?
    public var cr_version: String?
    public var hardware_version: String?
    public var msisdn: String?
    public var sms_unread_num: String?
    public var wifi_access_sta_num: String?
    public var net_select: String?
    public var ip_addr_web: String?
    public var wa_version: String?
    public var realtime_rx_bytes: String?
    public var realtime_tx_bytes: String?
    public var result: String?

    public init(
        lte_rsrp: String? = nil,
        sinr: String? = nil,
        cell_id: String? = nil,
        Z_dl_earfcn: String? = nil,
        monthly_rx_bytes: String? = nil,
        monthly_tx_bytes: String? = nil,
        monthly_time: String? = nil,
        network_provider: String? = nil,
        network_type: String? = nil,
        realtime_rx_thrpt: String? = nil,
        realtime_tx_thrpt: String? = nil,
        wan_ipaddr: String? = nil,
        ppp_status: String? = nil,
        lan_ipaddr: String? = nil,
        lan_netmask: String? = nil,
        dhcpEnabled: String? = nil,
        mac_address: String? = nil,
        imei: String? = nil,
        cr_version: String? = nil,
        hardware_version: String? = nil,
        msisdn: String? = nil,
        sms_unread_num: String? = nil,
        wifi_access_sta_num: String? = nil,
        net_select: String? = nil,
        ip_addr_web: String? = nil,
        wa_version: String? = nil,
        realtime_rx_bytes: String? = nil,
        realtime_tx_bytes: String? = nil,
        result: String? = nil
    ) {
        self.lte_rsrp = lte_rsrp
        self.sinr = sinr
        self.cell_id = cell_id
        self.Z_dl_earfcn = Z_dl_earfcn
        self.monthly_rx_bytes = monthly_rx_bytes
        self.monthly_tx_bytes = monthly_tx_bytes
        self.monthly_time = monthly_time
        self.network_provider = network_provider
        self.network_type = network_type
        self.realtime_rx_thrpt = realtime_rx_thrpt
        self.realtime_tx_thrpt = realtime_tx_thrpt
        self.wan_ipaddr = wan_ipaddr
        self.ppp_status = ppp_status
        self.lan_ipaddr = lan_ipaddr
        self.lan_netmask = lan_netmask
        self.dhcpEnabled = dhcpEnabled
        self.mac_address = mac_address
        self.imei = imei
        self.cr_version = cr_version
        self.hardware_version = hardware_version
        self.msisdn = msisdn
        self.sms_unread_num = sms_unread_num
        self.wifi_access_sta_num = wifi_access_sta_num
        self.net_select = net_select
        self.ip_addr_web = ip_addr_web
        self.wa_version = wa_version
        self.realtime_rx_bytes = realtime_rx_bytes
        self.realtime_tx_bytes = realtime_tx_bytes
        self.result = result
    }

    public var rsrpValue: Int? {
        guard let s = lte_rsrp, let val = Int(s) else { return nil }
        return val
    }

    public var sinrValue: Double? {
        guard let s = sinr, let val = Double(s) else { return nil }
        return val
    }

    /// Speed in bits per second (bytes/sec * 8)
    public var dlSpeedBps: Double? {
        guard let s = realtime_rx_thrpt, let val = Double(s) else { return nil }
        return val * 8
    }

    /// Speed in bits per second (bytes/sec * 8)
    public var ulSpeedBps: Double? {
        guard let s = realtime_tx_thrpt, let val = Double(s) else { return nil }
        return val * 8
    }

    public var sessionTotalBytes: Int64? {
        let rx = Int64(realtime_rx_bytes ?? "") ?? 0
        let tx = Int64(realtime_tx_bytes ?? "") ?? 0
        let total = rx + tx
        return total > 0 ? total : nil
    }

    public var monthlyTotalBytes: Int64? {
        let rx = Int64(monthly_rx_bytes ?? "") ?? 0
        let tx = Int64(monthly_tx_bytes ?? "") ?? 0
        let total = rx + tx
        return total > 0 ? total : nil
    }

    public var isPppConnected: Bool {
        guard let status = ppp_status?.lowercased() else { return false }
        return status.contains("connected") && !status.contains("disconnected")
    }

    public var isPppDisconnected: Bool {
        guard let status = ppp_status?.lowercased() else { return false }
        return status.contains("disconnected")
    }

    public var formattedLanIp: String {
        if let lan = lan_ipaddr, !lan.isEmpty { return lan }
        if let web = ip_addr_web, !web.isEmpty { return web }
        return "--"
    }
}
