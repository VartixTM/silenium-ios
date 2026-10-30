import SwiftUI

struct VersionListView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case release = "Релизы"
        case snapshot = "Снапшоты"
        var id: String { rawValue }
    }

    @State private var kind: Kind = .release
    @State private var manifest: VersionManifest?
    @State private var errorText: String?

    var body: some View {
        NavigationView {
            ZStack {
                SileniumBackground()
                VStack(spacing: 12) {
                    kindPicker
                    content
                }
            }
            .navigationTitle("Версии")
            .task { await load() }
            .refreshable { await load() }
        }
        .navigationViewStyle(.stack)
    }

    private var kindPicker: some View {
        Picker("Тип", selection: $kind.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
            ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        if let m = manifest {
            let list = kind == .release ? MojangAPI.releases(m) : MojangAPI.snapshots(m)
            let latestID = kind == .release ? m.latest.release : m.latest.snapshot
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(list) { entry in
                        VersionRow(entry: entry, isLatest: entry.id == latestID)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: kind)
            }
        } else if let errorText {
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
            let fresh = try await MojangAPI.fetchManifest()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                manifest = fresh
            }
            errorText = nil
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
                .background(Circle().fill(Color.white.opacity(0.06)))
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
        }
        .glassCard()
    }
}
