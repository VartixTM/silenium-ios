import SwiftUI

/// список версий (релизы / снапшоты). строка ведёт на выбор загрузчика (push, с кнопкой «назад»).
struct VersionBrowser: View {
    enum Kind: String, CaseIterable, Identifiable {
        case release = "Релизы"
        case snapshot = "Снапшоты"
        var id: String { rawValue }
    }

    @State private var kind: Kind = .release
    @State private var manifest: VersionManifest?
    @State private var errorText: String?

    var body: some View {
        ZStack {
            SileniumBackground()
            VStack(spacing: 12) {
                Picker("Тип", selection: $kind) {
                    ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                content
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let m = manifest {
            let list = kind == .release ? MojangAPI.releases(m) : MojangAPI.snapshots(m)
            let latestID = kind == .release ? m.latest.release : m.latest.snapshot
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(list) { entry in
                        NavigationLink(destination: LoaderSheet(entry: entry)) {
                            VersionRow(entry: entry, isLatest: entry.id == latestID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        } else if let errorText = errorText {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("не загрузилось").font(.headline)
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("повторить") { Task { await load() } }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                Spacer()
            }
        } else {
            VStack {
                Spacer()
                ProgressView().controlSize(.large)
                Text("качаю манифест")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                Spacer()
            }
        }
    }

    private func load() async {
        do {
            manifest = try await MojangAPI.fetchManifest()
            errorText = nil
        } catch is CancellationError {
            return
        } catch let e as URLError where e.code == .cancelled {
            return
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct VersionRow: View {
    let entry: VersionManifest.Entry
    let isLatest: Bool

    private var isRelease: Bool { entry.type == "release" }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRelease ? "cube.fill" : "hammer.fill")
                .foregroundStyle(isRelease ? Theme.accent : Theme.accentDeep)
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.id).font(.headline)
                Text(entry.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isLatest {
                Text("latest")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.accent.opacity(0.2)))
                    .foregroundStyle(Theme.accent)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}
