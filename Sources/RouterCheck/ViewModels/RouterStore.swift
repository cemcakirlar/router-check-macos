import SwiftUI
import Observation

public enum RecoveryStep: String, Sendable, Equatable {
    case idle
    case disconnecting = "Bağlantı Kesiliyor"
    case verifyingDisconnect = "Bağlantı Kesilmesi Doğrulanıyor"
    case switchingTo3G = "3G Moduna Geçiliyor"
    case verifying3G = "3G Şebekesi Bekleniyor"
    case switchingToAuto = "Otomatik 4G Moduna Dönülüyor"
    case verifying4G = "4G/LTE Şebekesi Bekleniyor"
    case connecting = "Yeniden Bağlanılıyor"
    case verifyingConnect = "İnternet Bağlantısı Doğrulanıyor"
    case completed = "Hücre Kurtarma Tamamlandı"
    case failed = "Hücre Kurtarma Başarısız"

    public var isTerminal: Bool {
        self == .idle || self == .completed || self == .failed
    }
}

public enum ConnectionStatus: Equatable, Sendable {
    case offline
    case connecting
    case loggingIn
    case connected
    case error(String)

    public var title: String {
        switch self {
        case .offline: return "Çevrimdışı"
        case .connecting: return "Bağlanıyor..."
        case .loggingIn: return "Giriş Yapılıyor..."
        case .connected: return "Bağlı"
        case .error(let msg): return "Hata: \(msg)"
        }
    }

    public var color: Color {
        switch self {
        case .offline: return .secondary
        case .connecting, .loggingIn: return .orange
        case .connected: return Color(red: 0.18, green: 0.84, blue: 0.45)
        case .error: return Color(red: 0.96, green: 0.26, blue: 0.35)
        }
    }
}

@Observable
@MainActor
public final class RouterStore {
    public var config: AppConfig
    public var routerData: RouterData?
    public var status: ConnectionStatus = .offline
    public var isRefreshing: Bool = false
    public var autoRefresh: Bool = true
    public var lastUpdate: Date?
    public var errorMessage: String?

    // Sparklines history (max 50 items)
    public var rsrpHistory: [Double] = []
    public var sinrHistory: [Double] = []
    public var dlHistory: [Double] = []
    public var ulHistory: [Double] = []

    // Settings sheet
    public var isSettingsPresented: Bool = false

    // Cell Recovery state
    public var recoveryStep: RecoveryStep = .idle
    public var recoveryMessage: String = ""
    public var recoveryProgress: Double = 0.0
    private var abortRecoveryRequested: Bool = false

    public var isRecovering: Bool {
        !recoveryStep.isTerminal
    }

    private let client: ZTEClient
    private var pollingTask: Task<Void, Never>?

    public var colorScheme: ColorScheme? {
        switch config.theme_mode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    public static func applyThemeMode(_ mode: String) {
        DispatchQueue.main.async {
            let app = NSApplication.shared
            switch mode {
            case "light":
                app.appearance = NSAppearance(named: .aqua)
            case "dark":
                app.appearance = NSAppearance(named: .darkAqua)
            default:
                app.appearance = nil
            }
        }
    }

    // Window visibility state
    public var isWindowVisible: Bool = true

    public static func showMainWindow() {
        WindowManager.shared.showMainWindow()
    }

    public static func hideMainWindow() {
        WindowManager.shared.hideMainWindow()
    }

    public func toggleMainWindow() {
        WindowManager.shared.toggleMainWindow()
    }

    public init() {
        let loadedConfig = AppConfig.load()
        self.config = loadedConfig
        self.autoRefresh = loadedConfig.auto_refresh_on_startup
        self.isWindowVisible = (loadedConfig.main_window_on_startup != "hidden")
        self.client = ZTEClient(host: loadedConfig.router_ip)

        WindowManager.shared.store = self

        Self.applyThemeMode(loadedConfig.theme_mode)

        if loadedConfig.auto_refresh_on_startup {
            startPolling()
        }
    }

    // MARK: - Polling Management

    public func startPolling() {
        stopPolling()
        autoRefresh = true
        pollingTask = Task { [weak self] in
            guard let self = self else { return }
            // Immediately perform a refresh upon starting or resuming polling
            await self.refresh()

            while !Task.isCancelled {
                let interval = self.config.refreshIntervalSeconds
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await self.refresh()
            }
        }
    }

    public func stopPolling() {
        autoRefresh = false
        pollingTask?.cancel()
        pollingTask = nil
    }

    public func toggleAutoRefresh() {
        if autoRefresh {
            stopPolling()
        } else {
            startPolling()
        }
    }

    // MARK: - Refresh & Telemetry Fetching

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        do {
            if case .offline = status {
                status = .connecting
            }

            var data: RouterData
            do {
                data = try await client.fetchRouterData()
            } catch ZTEError.notLoggedIn {
                // Needs authentication
                status = .loggingIn
                try await client.login(password: config.router_password)
                data = try await client.fetchRouterData()
            }

            // Verify if authentication was required (e.g. empty network_provider on MF286R)
            if data.network_provider == nil || data.network_provider?.isEmpty == true {
                status = .loggingIn
                try await client.login(password: config.router_password)
                data = try await client.fetchRouterData()
            }

            self.routerData = data
            self.status = .connected
            self.lastUpdate = Date()
            self.errorMessage = nil

            // Append Sparklines
            if let rsrp = data.rsrpValue {
                rsrpHistory.append(Double(rsrp))
                if rsrpHistory.count > 50 { rsrpHistory.removeFirst() }
            }
            if let sinr = data.sinrValue {
                sinrHistory.append(sinr)
                if sinrHistory.count > 50 { sinrHistory.removeFirst() }
            }
            if let dl = data.dlSpeedBps {
                dlHistory.append(dl)
                if dlHistory.count > 50 { dlHistory.removeFirst() }
            }
            if let ul = data.ulSpeedBps {
                ulHistory.append(ul)
                if ulHistory.count > 50 { ulHistory.removeFirst() }
            }

        } catch {
            let desc = error.localizedDescription
            self.status = .error(desc)
            self.errorMessage = desc
        }

        self.isRefreshing = false
    }

    // MARK: - Authentication Actions

    public func login() async {
        status = .loggingIn
        do {
            try await client.login(password: config.router_password)
            await refresh()
        } catch {
            status = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    public func logout() async {
        do {
            try await client.logout()
            self.routerData = nil
            self.status = .offline
            self.rsrpHistory.removeAll()
            self.sinrHistory.removeAll()
            self.dlHistory.removeAll()
            self.ulHistory.removeAll()
            self.lastUpdate = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Network Control Actions

    public func disconnectPPP() async {
        do {
            try await client.disconnectNetwork()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func connectPPP() async {
        do {
            try await client.connectNetwork()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func setBearerPreference(_ preference: String) async {
        do {
            try await client.setBearerPreference(preference)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cell Recovery Workflow

    public func startCellRecovery() async {
        guard !isRecovering else { return }
        abortRecoveryRequested = false
        let wasAutoRefresh = autoRefresh
        if autoRefresh {
            stopPolling()
        }

        var bearerChanged = false

        do {
            if status != .connected {
                recoveryStep = .disconnecting
                recoveryProgress = 0.05
                recoveryMessage = "Router oturumu doğrulanıyor..."
                await refresh()
                if status != .connected {
                    throw ZTEError.notLoggedIn
                }
            }

            // Adım 1: Bağlantı Kesiliyor
            recoveryStep = .disconnecting
            recoveryProgress = 0.1
            recoveryMessage = "İnternet bağlantısı kesiliyor..."
            try await client.disconnectNetwork()
            if abortRecoveryRequested { throw CancellationError() }

            // Adım 2: Bağlantı Kesilmesi Doğrulanıyor
            recoveryStep = .verifyingDisconnect
            recoveryProgress = 0.2
            var disconnected = false
            for i in 1...20 {
                if abortRecoveryRequested { throw CancellationError() }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let data = try? await client.fetchRouterData(commands: ["ppp_status"])
                recoveryMessage = "Bağlantının kesildiği doğrulanıyor (\(i)/20)..."
                if data?.isPppDisconnected == true {
                    disconnected = true
                    break
                }
            }
            guard disconnected else {
                throw ZTEError.routerCommandFailed("Bağlantı kesme zaman aşımına uğradı")
            }

            // Adım 3: 3G Bandına Alınıyor
            recoveryStep = .switchingTo3G
            recoveryProgress = 0.35
            recoveryMessage = "Taşıyıcı 3G (Only_WCDMA) moduna alınıyor..."
            try await client.setBearerPreference("Only_WCDMA")
            bearerChanged = true
            if abortRecoveryRequested { throw CancellationError() }
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Adım 4: 3G Şebekesi Kaydı Bekleniyor
            recoveryStep = .verifying3G
            recoveryProgress = 0.5
            var registered3G = false
            for i in 1...20 {
                if abortRecoveryRequested { throw CancellationError() }
                let data = try? await client.fetchRouterData(commands: ["network_type"])
                let net = (data?.network_type ?? "").lowercased()
                recoveryMessage = "3G şebekesine kayıt bekleniyor (\(i)/20) [\(data?.network_type ?? "Yok")]..."
                if net.contains("wcdma") || net.contains("umts") || net.contains("hsdpa") ||
                   net.contains("hsupa") || net.contains("hspa") || net.contains("3g") {
                    registered3G = true
                    break
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            guard registered3G else {
                throw ZTEError.routerCommandFailed("3G şebekesine kayıt zaman aşımına uğradı")
            }

            // Adım 5: Otomatik / 4G Moduna Dönülüyor
            recoveryStep = .switchingToAuto
            recoveryProgress = 0.65
            recoveryMessage = "Taşıyıcı Otomatik (NETWORK_auto) moduna alınıyor..."
            try await client.setBearerPreference("NETWORK_auto")
            if abortRecoveryRequested { throw CancellationError() }
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Adım 6: 4G/LTE Şebekesi Kaydı Bekleniyor
            recoveryStep = .verifying4G
            recoveryProgress = 0.8
            var registered4G = false
            for i in 1...25 {
                if abortRecoveryRequested { throw CancellationError() }
                let data = try? await client.fetchRouterData(commands: ["network_type"])
                let net = (data?.network_type ?? "").lowercased()
                recoveryMessage = "4G/LTE şebekesine kayıt bekleniyor (\(i)/25) [\(data?.network_type ?? "Yok")]..."
                if net.contains("lte") || net.contains("4g") || net.contains("5g") ||
                   net.contains("lte_a") || net.contains("lte-a") || net.contains("lte+") {
                    registered4G = true
                    break
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            guard registered4G else {
                throw ZTEError.routerCommandFailed("4G/LTE şebekesine kayıt zaman aşımına uğradı")
            }

            // Adım 7: Yeniden Bağlanılıyor
            recoveryStep = .connecting
            recoveryProgress = 0.9
            recoveryMessage = "İnternet bağlantısı yeniden kuruluyor..."
            try await client.connectNetwork()
            if abortRecoveryRequested { throw CancellationError() }
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            // Adım 8: İnternet Bağlantısı Doğrulanıyor
            recoveryStep = .verifyingConnect
            recoveryProgress = 0.95
            var connected = false
            for i in 1...20 {
                if abortRecoveryRequested { throw CancellationError() }
                let data = try? await client.fetchRouterData(commands: ["ppp_status"])
                recoveryMessage = "İnternet bağlantısı doğrulanıyor (\(i)/20)..."
                if data?.isPppConnected == true {
                    connected = true
                    break
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard connected else {
                throw ZTEError.routerCommandFailed("İnternet bağlantısı kurulamadı")
            }

            recoveryStep = .completed
            recoveryProgress = 1.0
            recoveryMessage = "Hücre kurtarma başarıyla tamamlandı!"

            // 4 saniye sonra otomatik sıfırla
            Task {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if self.recoveryStep == .completed {
                    self.recoveryStep = .idle
                }
            }

        } catch {
            if abortRecoveryRequested || error is CancellationError {
                recoveryMessage = "Hücre kurtarma kullanıcı tarafından iptal edildi."
                if bearerChanged {
                    recoveryMessage = "Eski moda geri dönülüyor (NETWORK_auto)..."
                    try? await client.setBearerPreference("NETWORK_auto")
                    try? await client.connectNetwork()
                }
                recoveryStep = .idle
            } else {
                recoveryStep = .failed
                recoveryMessage = "Hata: \(error.localizedDescription)"
            }
        }

        if wasAutoRefresh {
            startPolling()
        } else {
            await refresh()
        }
    }

    public func abortCellRecovery() {
        abortRecoveryRequested = true
        recoveryMessage = "İptal ediliyor..."
    }

    public func dismissRecovery() {
        recoveryStep = .idle
        recoveryMessage = ""
    }

    // MARK: - Config Updating

    public func updateConfig(
        ip: String,
        password: String,
        intervalMinutes: Int,
        autoRefreshOnStartup: Bool,
        mainWindowOnStartup: String,
        themeMode: String
    ) {
        let trimmedIp = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let hostChanged = (config.router_ip != trimmedIp)
        let intervalChanged = (config.auto_refresh_interval != max(intervalMinutes, 1))

        config.router_ip = trimmedIp
        config.router_password = password
        config.auto_refresh_interval = max(intervalMinutes, 1)
        config.auto_refresh_on_startup = autoRefreshOnStartup
        config.main_window_on_startup = mainWindowOnStartup
        config.theme_mode = themeMode
        config.save()

        Self.applyThemeMode(themeMode)

        Task {
            if hostChanged {
                await client.updateHost(trimmedIp)
                await client.resetSession()
            }
            if intervalChanged && autoRefresh {
                startPolling()
            }
        }
    }
}
