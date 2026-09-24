import Foundation
import CryptoKit

public enum ZTEError: LocalizedError, Sendable {
    case invalidHost(String)
    case invalidURL
    case wrongPassword
    case loginFailed(String)
    case notLoggedIn
    case sessionNotEstablished
    case routerCommandFailed(String)
    case networkError(String)
    case decodingError(String)
    case httpError(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .invalidHost(let host):
            return "Geçersiz Router IP veya adresi: \(host)"
        case .invalidURL:
            return "Geçersiz istek URL'i"
        case .wrongPassword:
            return "Hatalı şifre! Lütfen şifrenizi kontrol edin."
        case .loginFailed(let code):
            return "Giriş başarısız oldu (Hata kodu: \(code))"
        case .notLoggedIn:
            return "Router oturumu açık değil."
        case .sessionNotEstablished:
            return "Oturum doğrulanamadı."
        case .routerCommandFailed(let msg):
            return "Router komutu başarısız: \(msg)"
        case .networkError(let msg):
            return "Ağ hatası: \(msg)"
        case .decodingError(let msg):
            return "Veri okuma hatası: \(msg)"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}

public actor ZTEClient {
    public static let standardCommands = [
        "modem_main_state", "signalbar", "network_type", "network_provider",
        "rssi", "rscp", "lte_rsrp", "lte_rsrq", "sinr", "cell_id", "Z_dl_earfcn",
        "realtime_tx_bytes", "realtime_rx_bytes", "realtime_tx_thrpt", "realtime_rx_thrpt",
        "monthly_rx_bytes", "monthly_tx_bytes", "monthly_time", "imei", "msisdn",
        "cr_version", "wa_version", "hardware_version", "lan_ipaddr", "mac_address",
        "wan_ipaddr", "ppp_status", "wifi_access_sta_num", "sms_unread_num",
        "host_name_web", "mac_addr_web", "ip_addr_web", "lan_netmask",
        "dhcpEnabled", "guest_dhcpEnabled", "net_select"
    ]

    private var host: String
    private var session: URLSession
    private let cookieStorage: HTTPCookieStorage

    public init(host: String = "192.168.0.1") {
        self.host = host
        let storage = HTTPCookieStorage.shared
        self.cookieStorage = storage
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = storage
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 5.0
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config)
    }

    public func updateHost(_ newHost: String) {
        let trimmed = newHost.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.host != trimmed {
            self.host = trimmed
            resetSession()
        }
    }

    public func resetSession() {
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                if cookie.domain.contains(host) {
                    cookieStorage.deleteCookie(cookie)
                }
            }
        }
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 5.0
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config)
    }

    private var epochMs: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("http://\(host)/index.html", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")
        request.setValue("tr,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
    }

    // MARK: - Generic Request Maker

    private func makeRequest(
        path: String,
        method: String = "GET",
        formData: [String: String]? = nil
    ) async throws -> (Data, String) {
        guard let url = URL(string: "http://\(host)/goform\(path)") else {
            throw ZTEError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        applyHeaders(to: &request)

        if let formData = formData, method == "POST" {
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            let bodyString = formData.map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")
            request.httpBody = Data(bodyString.utf8)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ZTEError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ZTEError.networkError("Geçersiz sunucu yanıtı")
        }

        let bodyString = String(decoding: data, as: UTF8.self)

        guard (200...299).contains(httpResponse.statusCode) else {
            let snippet = String(bodyString.prefix(200))
            throw ZTEError.httpError(statusCode: httpResponse.statusCode, body: snippet)
        }

        return (data, bodyString)
    }

    // MARK: - Authentication & Status

    public func verifyLoginStatus() async -> Bool {
        let path = "/goform_get_cmd_process?isTest=false&multi_data=1&cmd=hardware_version&_=\(epochMs)"
        do {
            let (data, body) = try await makeRequest(path: path)
            if body.lowercased().contains("<html") { return false }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hw = json["hardware_version"] as? String,
               !hw.isEmpty {
                return true
            }
        } catch {
            return false
        }
        return false
    }

    public func login(password: String) async throws {
        resetSession()

        let base64Password = Data(password.utf8).base64EncodedString()
        let payload: [String: String] = [
            "isTest": "false",
            "goformId": "LOGIN_MULTI_USER",
            "user": "admin",
            "password": base64Password
        ]

        let (data, body) = try await makeRequest(path: "/goform_set_cmd_process", method: "POST", formData: payload)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            resetSession()
            throw ZTEError.decodingError("Router yanıtı JSON olarak okunamadı: \(body)")
        }

        let resultCode: String? = {
            if let str = json["result"] as? String { return str }
            if let num = json["result"] as? Int { return String(num) }
            return nil
        }()

        guard let code = resultCode else {
            resetSession()
            throw ZTEError.loginFailed("Eksik yanıt kodu")
        }

        if code == "1" {
            resetSession()
            throw ZTEError.wrongPassword
        }

        if code != "0" {
            resetSession()
            throw ZTEError.loginFailed(code)
        }

        let isVerified = await verifyLoginStatus()
        guard isVerified else {
            resetSession()
            throw ZTEError.sessionNotEstablished
        }

        // Verify telemetry fields are accessible
        let testPath = "/goform_get_cmd_process?isTest=false&multi_data=1&cmd=hardware_version,network_provider&_=\(epochMs)"
        let (testData, _) = try await makeRequest(path: testPath)
        if let testJson = try? JSONSerialization.jsonObject(with: testData) as? [String: Any] {
            let hw = testJson["hardware_version"] as? String ?? ""
            let prov = testJson["network_provider"] as? String ?? ""
            if hw.isEmpty && prov.isEmpty {
                resetSession()
                throw ZTEError.sessionNotEstablished
            }
        }
    }

    public func logout() async throws {
        let ad = (try? await fetchADToken()) ?? ""
        var payload: [String: String] = [
            "isTest": "false",
            "goformId": "LOGOUT"
        ]
        if !ad.isEmpty {
            payload["AD"] = ad
        }

        _ = try? await makeRequest(path: "/goform_set_cmd_process", method: "POST", formData: payload)
        resetSession()
    }

    // MARK: - Telemetry & Data Fetching

    public func fetchRouterData(commands: [String] = ZTEClient.standardCommands) async throws -> RouterData {
        let joined = commands.joined(separator: ",")
        let path = "/goform_get_cmd_process?isTest=false&multi_data=1&cmd=\(joined)&_=\(epochMs)"

        let (data, body) = try await makeRequest(path: path)

        if body.lowercased().contains("<html") {
            throw ZTEError.notLoggedIn
        }

        do {
            let routerData = try JSONDecoder().decode(RouterData.self, from: data)
            return routerData
        } catch {
            throw ZTEError.decodingError("Telemetri verisi çözülemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Security Token (AD) & Actions

    private func md5Hex(_ input: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func fetchADToken() async throws -> String {
        let path = "/goform_get_cmd_process?isTest=false&multi_data=1&cmd=wa_inner_version,cr_version,RD&_=\(epochMs)"
        let (data, _) = try await makeRequest(path: path)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let waInner = json["wa_inner_version"] as? String,
              let crVersion = json["cr_version"] as? String,
              let rd = json["RD"] as? String else {
            throw ZTEError.routerCommandFailed("AD token bileşenleri (wa_inner_version, cr_version, RD) alınamadı")
        }

        let firstConcat = "\(waInner)\(crVersion)"
        let firstMD5 = md5Hex(firstConcat)
        let secondConcat = "\(firstMD5)\(rd)"
        return md5Hex(secondConcat)
    }

    public func disconnectNetwork() async throws {
        let ad = try await fetchADToken()
        let payload: [String: String] = [
            "isTest": "false",
            "notCallback": "true",
            "goformId": "DISCONNECT_NETWORK",
            "AD": ad
        ]
        let (data, _) = try await makeRequest(path: "/goform_set_cmd_process", method: "POST", formData: payload)
        try verifyCommandSuccess(data: data)
    }

    public func connectNetwork() async throws {
        let ad = try await fetchADToken()
        let payload: [String: String] = [
            "isTest": "false",
            "notCallback": "true",
            "goformId": "CONNECT_NETWORK",
            "AD": ad
        ]
        let (data, _) = try await makeRequest(path: "/goform_set_cmd_process", method: "POST", formData: payload)
        try verifyCommandSuccess(data: data)
    }

    public func setBearerPreference(_ preference: String) async throws {
        guard ["Only_LTE", "Only_WCDMA", "NETWORK_auto"].contains(preference) else {
            throw ZTEError.routerCommandFailed("Geçersiz taşıyıcı tercihi: \(preference)")
        }
        let ad = try await fetchADToken()
        let payload: [String: String] = [
            "isTest": "false",
            "goformId": "SET_BEARER_PREFERENCE",
            "BearerPreference": preference,
            "AD": ad
        ]
        let (data, _) = try await makeRequest(path: "/goform_set_cmd_process", method: "POST", formData: payload)
        try verifyCommandSuccess(data: data)
    }

    private func verifyCommandSuccess(data: Data) throws {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ZTEError.routerCommandFailed("Yanıt okunamadı")
        }
        let code = (json["result"] as? String ?? "\(json["result"] ?? "")").lowercased()
        if !["0", "ok", "success"].contains(code) {
            throw ZTEError.routerCommandFailed("Hata kodu: \(code)")
        }
    }
}
