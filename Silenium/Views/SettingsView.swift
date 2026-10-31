import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ZStack {
            SileniumBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("оформление") {
                        Picker("Тема", selection: $settings.theme) {
                            ForEach(SettingsStore.AppTheme.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    section("язык") {
                        Picker("Язык", selection: $settings.language) {
                            ForEach(SettingsStore.Language.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        if settings.language == .en {
                            Text("английский интерфейс ещё в работе, пока всё на русском.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    section("авторы") {
                        AuthorsSection()
                    }

                    Text("Silenium 1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding()
            }
        }
        .navigationTitle("Настройки")
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .glassCard()
        }
    }
}
