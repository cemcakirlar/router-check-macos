import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowManager.shared.showMainWindow()
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowManager.shared.isTerminating = true
        return .terminateNow
    }
}

@main
struct RouterCheckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = RouterStore()

    private var menuBarLabel: String {
        guard store.status == .connected, let data = store.routerData else {
            return "Offline"
        }
        let net = data.network_type ?? "4G"
        let rsrp = data.rsrpValue.map { "\($0)dBm" } ?? ""
        let sinr = data.sinrValue.map { String(format: "%.0fdB", $0) } ?? ""
        return "\(net) | \(rsrp) | \(sinr)"
    }

    var body: some Scene {
        Window("Router Check", id: "main") {
            DashboardView(store: store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 860, height: 600)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Router Check Hakkında") {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Router Check",
                            NSApplication.AboutPanelOptionKey.version: "\(version) (Build \(build))"
                        ]
                    )
                }
            }
        }

        MenuBarExtra {
            MenuBarContentView(store: store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text(menuBarLabel)
            }
        }
    }
}

struct MenuBarContentView: View {
    @Bindable var store: RouterStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("📡 Router: \(store.config.router_ip)")
            .font(.headline)
        Text("\(store.status == .connected ? "🟢" : "🔴") Durum: \(store.status.title)")

        if let data = store.routerData {
            Divider()
            Text("📶 Şebeke: \(data.network_type ?? "--") (\(data.network_provider ?? "--"))")
            if let rsrp = data.rsrpValue {
                Text("📡 RSRP: \(rsrp) dBm (\(SignalGrade.forRsrp(rsrp).rawValue))")
            }
            if let sinr = data.sinrValue {
                Text("📊 SINR: \(String(format: "%.1f", sinr)) dB (\(SignalGrade.forSinr(sinr).rawValue))")
            }
            if let cell = data.cell_id, !cell.isEmpty {
                Text("🏷️ Cell ID: \(cell)")
            }
            if let dl = data.dlSpeedBps, let ul = data.ulSpeedBps {
                Text("⚡ Hız: \(Formatters.formatSpeed(bps: dl)) ↓ | \(Formatters.formatSpeed(bps: ul)) ↑")
            }
        }

        Divider()

        Button(store.isWindowVisible ? "👁️ Pencereyi Gizle" : "🪟 Pencereyi Göster") {
            if store.isWindowVisible {
                WindowManager.shared.hideMainWindow()
            } else {
                openWindow(id: "main")
                WindowManager.shared.showMainWindow()
            }
        }

        Divider()

        Button(store.autoRefresh ? "⏸️ Yoklamayı Durdur" : "▶️ Yoklamayı Başlat") {
            store.toggleAutoRefresh()
        }

        Button("🔄 Şimdi Yenile") {
            Task { await store.refresh() }
        }

        Button("⚡ Hücreyi Kurtar") {
            openWindow(id: "main")
            WindowManager.shared.showMainWindow()
            Task { await store.startCellRecovery() }
        }

        Divider()

        Button("⚙️ Ayarlar...") {
            openWindow(id: "main")
            WindowManager.shared.showMainWindow()
            store.isSettingsPresented = true
        }

        Button("🚪 Çıkış") {
            WindowManager.shared.isTerminating = true
            NSApplication.shared.terminate(nil)
        }
    }
}
