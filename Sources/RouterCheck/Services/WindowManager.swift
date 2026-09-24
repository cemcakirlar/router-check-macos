import SwiftUI
import AppKit

@MainActor
public final class WindowManager: NSObject, NSWindowDelegate, @unchecked Sendable {
    public static let shared = WindowManager()

    public weak var mainWindow: NSWindow?
    public weak var store: RouterStore?
    public var isTerminating: Bool = false
    private var hasAppliedStartupVisibility: Bool = false

    private override init() {
        super.init()
    }

    public func register(window: NSWindow, store: RouterStore) {
        self.mainWindow = window
        self.store = store
        window.delegate = self
        window.isReleasedWhenClosed = false

        if !hasAppliedStartupVisibility {
            hasAppliedStartupVisibility = true
            if store.config.main_window_on_startup == "hidden" {
                window.orderOut(nil)
                store.isWindowVisible = false
                DispatchQueue.main.async {
                    window.orderOut(nil)
                    store.isWindowVisible = false
                }
            } else {
                store.isWindowVisible = true
            }
        }
    }

    public func showMainWindow() {
        if let window = mainWindow {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            for window in NSApplication.shared.windows where window.className != "NSStatusBarWindow" {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        store?.isWindowVisible = true
    }

    public func hideMainWindow() {
        if let window = mainWindow {
            window.orderOut(nil)
        } else {
            for window in NSApplication.shared.windows where window.className != "NSStatusBarWindow" {
                window.orderOut(nil)
            }
        }
        store?.isWindowVisible = false
    }

    public func toggleMainWindow() {
        if store?.isWindowVisible == true {
            hideMainWindow()
        } else {
            showMainWindow()
        }
    }

    // MARK: - NSWindowDelegate

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isTerminating {
            return true
        }
        // Intercept close button to hide instead of destroying the window
        sender.orderOut(nil)
        store?.isWindowVisible = false
        return false
    }

    public func windowDidMiniaturize(_ notification: Notification) {
        store?.isWindowVisible = false
    }

    public func windowDidDeminiaturize(_ notification: Notification) {
        store?.isWindowVisible = true
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        store?.isWindowVisible = true
    }
}

public struct WindowAccessor: NSViewRepresentable {
    private let callback: (NSWindow) -> Void

    public init(callback: @escaping (NSWindow) -> Void) {
        self.callback = callback
    }

    public func makeNSView(context: Context) -> NSView {
        let view = WindowObserverView()
        view.callback = callback
        if let window = view.window {
            callback(window)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            callback(window)
        }
    }
}

private final class WindowObserverView: NSView {
    var callback: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            callback?(window)
        }
    }
}
