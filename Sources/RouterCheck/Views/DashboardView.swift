import SwiftUI

public struct DashboardView: View {
    @Bindable public var store: RouterStore

    public init(store: RouterStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store)

            Divider()

            if let error = store.errorMessage, store.status != .connected {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button("Tekrar Dene") {
                        Task { await store.refresh() }
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.12))
            }

            if store.recoveryStep != .idle {
                CellRecoveryBannerView(store: store)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Top Row: Signal & Speeds
                    HStack(alignment: .top, spacing: 16) {
                        SignalCardView(store: store)
                        SpeedCardView(store: store)
                    }

                    // Bottom Row: Network & System
                    HStack(alignment: .top, spacing: 16) {
                        NetworkInfoCardView(store: store)
                        SystemInfoCardView(store: store)
                    }
                }
                .padding(16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(minWidth: 860, idealWidth: 880, minHeight: 580, idealHeight: 585)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(
            WindowAccessor { window in
                WindowManager.shared.register(window: window, store: store)
            }
        )
        .preferredColorScheme(store.colorScheme)
        .animation(.easeInOut(duration: 0.25), value: store.recoveryStep)
        .sheet(isPresented: $store.isSettingsPresented) {
            SettingsSheetView(store: store)
        }
    }
}
