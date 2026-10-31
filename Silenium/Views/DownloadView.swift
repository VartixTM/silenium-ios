import SwiftUI

/// скачивание: список версий -> (push) выбор загрузчика -> создание экземпляра
struct DownloadView: View {
    var body: some View {
        VersionBrowser()
            .navigationTitle("скачать")
    }
}

struct LoaderSheet: View {
    let entry: VersionManifest.Entry

    @EnvironmentObject private var instances: InstanceStore
    @Environment(\.presentationMode) private var presentation
    @StateObject private var installer = VersionInstaller()

    @State private var loader: Instance.Loader = .vanilla
    @State private var fabricAPI = true
    @State private var errorText: String?
    @State private var busy = false

    var body: some View {
        ZStack {
            SileniumBackground()
            VStack(alignment: .leading, spacing: 14) {
                Text("выбери загрузчик")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Instance.Loader.allCases) { l in
                    Button { loader = l } label: {
                        loaderRow(l)
                    }
                    .buttonStyle(.plain)
                }

                if loader == .fabric {
                    Toggle("скачать Fabric API", isOn: $fabricAPI)
                        .glassCard()
                }

                if loader != .vanilla {
                    Text("установка \(loader.rawValue) ещё не готова: экземпляр создастся, лоадер поставим отдельным шагом.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if busy {
                    ProgressView(value: installer.progress)
                        .tint(Theme.accent)
                    Text(installer.status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let errorText = errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                Button {
                    Task { await create() }
                } label: {
                    Text("создать экземпляр")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accentDeep)
                        )
                }
                .buttonStyle(.plain)
                .disabled(busy)
            }
            .padding()
        }
        .navigationTitle(entry.id)
    }

    private func loaderRow(_ l: Instance.Loader) -> some View {
        HStack {
            Text(l.rawValue).font(.headline)
            Spacer()
            Image(systemName: loader == l ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(loader == l ? Theme.accent : .secondary)
        }
        .glassCard(selected: loader == l)
    }

    private func create() async {
        busy = true
        errorText = nil
        defer { busy = false }
        do {
            _ = try await installer.install(entry)
            let inst = try instances.create(versionID: entry.id, loader: loader, fabricAPI: fabricAPI)
            instances.select(inst.id)
            presentation.wrappedValue.dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
