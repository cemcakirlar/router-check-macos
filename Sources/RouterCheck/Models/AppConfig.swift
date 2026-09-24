import Foundation

public struct AppConfig: Codable, Sendable, Equatable {
    public var router_ip: String
    public var router_password: String
    /// Auto refresh interval in minutes (integer)
    public var auto_refresh_interval: Int
    public var auto_refresh_on_startup: Bool
    public var main_window_on_startup: String
    public var theme_mode: String

    public init(
        router_ip: String = "192.168.0.1",
        router_password: String = "",
        auto_refresh_interval: Int = 1,
        auto_refresh_on_startup: Bool = true,
        main_window_on_startup: String = "visible",
        theme_mode: String = "system"
    ) {
        self.router_ip = router_ip
        self.router_password = router_password
        self.auto_refresh_interval = max(auto_refresh_interval, 1)
        self.auto_refresh_on_startup = auto_refresh_on_startup
        self.main_window_on_startup = main_window_on_startup
        self.theme_mode = theme_mode
    }

    public static let `default` = AppConfig()

    public var refreshIntervalMinutes: Int {
        max(auto_refresh_interval, 1)
    }

    public var refreshIntervalSeconds: Double {
        Double(refreshIntervalMinutes) * 60.0
    }

    private static var configURL: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("RouterCheck", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("config.json")
    }

    public static func load() -> AppConfig {
        let url = configURL
        guard let data = try? Data(contentsOf: url),
              var config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        // Auto-migrate legacy millisecond values (e.g. 2000 ms) to minutes
        if config.auto_refresh_interval > 60 {
            config.auto_refresh_interval = max(config.auto_refresh_interval / 60000, 1)
            config.save()
        }
        return config
    }

    public func save() {
        let url = Self.configURL
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
