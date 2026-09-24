import SwiftUI

public struct SettingsSheetView: View {
    @Bindable public var store: RouterStore
    @Environment(\.dismiss) private var dismiss

    @State private var routerIp: String = ""
    @State private var routerPassword: String = ""
    @State private var refreshIntervalMinutes: Int = 1
    @State private var autoRefreshOnStartup: Bool = true
    @State private var mainWindowOnStartup: String = "visible"
    @State private var themeMode: String = "system"

    public init(store: RouterStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Router ve Uygulama Ayarları", systemImage: "gearshape.fill")
                    .font(.headline)
                Spacer()
                Button {
                    // Revert live theme change if cancelled
                    RouterStore.applyThemeMode(store.config.theme_mode)
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            Divider()

            Form {
                Section("Router Bağlantısı") {
                    TextField("Router IP / Host", text: $routerIp)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Router Şifresi", text: $routerPassword)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Yoklama & Yenileme Aralığı") {
                    LabeledContent("Aralık:") {
                        HStack(spacing: 8) {
                            TextField("", value: $refreshIntervalMinutes, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                .labelsHidden()

                            Stepper("", value: $refreshIntervalMinutes, in: 1...1440)
                                .labelsHidden()

                            Text("dakika")
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }

                    LabeledContent("Hızlı Seçim:") {
                        HStack(spacing: 6) {
                            ForEach([1, 2, 5, 10, 15, 30], id: \.self) { mins in
                                Button("\(mins) dk") {
                                    refreshIntervalMinutes = mins
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(refreshIntervalMinutes == mins ? .accentColor : .secondary)
                            }
                            Spacer()
                        }
                    }

                    Toggle("Başlangıçta otomatik yoklamayı başlat", isOn: $autoRefreshOnStartup)
                }

                Section("Görünüm & Başlangıç Davranışı") {
                    Picker("Görünüm Teması", selection: $themeMode) {
                        Text("Sistem").tag("system")
                        Text("Koyu").tag("dark")
                        Text("Açık").tag("light")
                    }
                    .onChange(of: themeMode) { _, newTheme in
                        RouterStore.applyThemeMode(newTheme)
                    }

                    Picker("Başlangıçta Pencere", selection: $mainWindowOnStartup) {
                        Text("Görünür (Pencereyi Aç)").tag("visible")
                        Text("Gizli (Yalnızca Menü Çubuğunda Çalış)").tag("hidden")
                    }
                    .help("Gizli seçildiğinde uygulama açıldığında pencere görünmez, sadece menü çubuğundan yönetilir.")
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("İptal") {
                    RouterStore.applyThemeMode(store.config.theme_mode)
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Kaydet") {
                    store.updateConfig(
                        ip: routerIp,
                        password: routerPassword,
                        intervalMinutes: max(refreshIntervalMinutes, 1),
                        autoRefreshOnStartup: autoRefreshOnStartup,
                        mainWindowOnStartup: mainWindowOnStartup,
                        themeMode: themeMode
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 460)
        .onAppear {
            routerIp = store.config.router_ip
            routerPassword = store.config.router_password
            refreshIntervalMinutes = store.config.refreshIntervalMinutes
            autoRefreshOnStartup = store.config.auto_refresh_on_startup
            mainWindowOnStartup = store.config.main_window_on_startup
            themeMode = store.config.theme_mode
        }
    }
}
