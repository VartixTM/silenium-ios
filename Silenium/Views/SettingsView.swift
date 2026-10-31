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

                    section("рендер") {
                        Picker("рендерер", selection: $settings.render.renderer) {
                            ForEach(RendererKind.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu)

                        Text("разрешение: \(settings.render.resolutionPercent)%")
                            .font(.subheadline)
                        Slider(value: sliderBinding(\.resolutionPercent),
                               in: Double(RenderSettings.resolutionRange.lowerBound)...Double(RenderSettings.resolutionRange.upperBound),
                               step: 5)

                        Picker("лимит fps", selection: $settings.render.fpsLimit) {
                            ForEach(FpsLimit.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        Toggle("показывать fps", isOn: $settings.render.showFPS)
                        Picker("вид fps", selection: $settings.render.fpsDisplay) {
                            ForEach(FpsDisplayMode.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Toggle("показывать память", isOn: $settings.render.showMemory)
                    }

                    section("память и jvm") {
                        Text("выделено: \(settings.render.ramMB) МБ")
                            .font(.subheadline)
                        Slider(value: sliderBinding(\.ramMB),
                               in: Double(RenderSettings.ramRange.lowerBound)...Double(RenderSettings.ramRange.upperBound),
                               step: 256)
                        Text("всего на устройстве: \(RenderSettings.ramRange.upperBound) МБ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("доп. аргументы jvm", text: $settings.render.jvmArgs)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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

    private func sliderBinding(_ keyPath: WritableKeyPath<RenderSettings, Int>) -> Binding<Double> {
        Binding(
            get: { Double(settings.render[keyPath: keyPath]) },
            set: { settings.render[keyPath: keyPath] = Int($0) }
        )
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
