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
        if store.isRecovering {
            return "⚡ Kurtarılıyor..."
        }
        guard store.status == .connected, let data = store.routerData else {
            switch store.status {
            case .connecting, .loggingIn:
                return "🟡 Bağlanıyor..."
            case .error:
                return "🔴 Hata"
            case .offline, .connected:
                return "🔴 Çevrimdışı"
            }
        }
        let net = (data.network_type?.isEmpty == false) ? data.network_type! : "4G"
        let snr: String
        if let sinrVal = data.sinrValue {
            snr = String(format: "%.1f dB", sinrVal)
        } else {
            snr = "-- dB"
        }
        let cid = (data.cell_id?.isEmpty == false) ? data.cell_id! : "--"
        return "📶 \(net) | 📊 SNR: \(snr) | 🗼 CID: \(cid)"
    }

    var body: some Scene {
        Window("Router Check", id: "main") {
            DashboardView(store: store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 880, height: 720)
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
            MenuBarPopoverView(store: store)
        } label: {
            Text(menuBarLabel)
        }
        .menuBarExtraStyle(.window)
    }
}
