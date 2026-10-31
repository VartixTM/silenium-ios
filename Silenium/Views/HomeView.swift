import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var accounts: AccountStore
    @EnvironmentObject private var instances: InstanceStore

    @State private var news: [NewsItem] = []
    @State private var newsError: String?
    @State private var sheet: HomeSheet?
    @State private var showLaunchInfo = false

    enum HomeSheet: String, Identifiable {
        case accounts, instances, download, settings, files
        var id: String { rawValue }
    }

    private let purple = Color(red: 0.37, green: 0.33, blue: 0.56)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SileniumBackground()
                VStack(alignment: .leading, spacing: 14) {
                    topBar
                    HStack(alignment: .top, spacing: 16) {
                        newsColumn
                        sidePanel
                            .frame(width: min(geo.size.width * 0.36, 340))
                    }
                }
                .padding(20)
            }
        }
        .task { await loadNews() }
        .sheet(item: $sheet) { s in sheetContent(s) }
        .alert("запуск пока недоступен", isPresented: $showLaunchInfo) {
            Button("ок", role: .cancel) {}
        } message: {
            Text("нужна JVM, её встраиваем следующим этапом. пока ставим версии и создаём экземпляры.")
        }
    }

    // MARK: top bar

    private var topBar: some View {
        HStack(spacing: 4) {
            Text("Silenium")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Spacer()
            iconButton("folder.fill") { sheet = .files }
            iconButton("person.2.fill") { sheet = .accounts }
            iconButton("arrow.down.circle.fill") { sheet = .download }
            iconButton("gearshape.fill") { sheet = .settings }
        }
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PressScale())
        .foregroundStyle(.primary)
    }

    // MARK: news

    private var newsColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("новости майнкрафта")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if news.isEmpty {
                Text(newsError ?? "загружаю новости...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(news) { item in
                            NewsCard(item: item)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: news.count)
    }

    // MARK: side panel (аккаунт, экземпляр, запуск)

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("версия")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            accountCard
            instanceCard
            Spacer(minLength: 0)
            launchButton
        }
    }

    private var accountCard: some View {
        Button { sheet = .accounts } label: {
            HStack(spacing: 12) {
                if let acc = accounts.selected {
                    AsyncImage(url: acc.headURL) { image in
                        image.interpolation(.none).resizable().scaledToFit()
                    } placeholder: {
                        Color.clear
                    }
                    .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(acc.name).font(.headline)
                        Text(acc.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                    Text("добавить аккаунт").font(.headline)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(PressScale())
    }

    private var instanceCard: some View {
        Button { sheet = .instances } label: {
            HStack(spacing: 12) {
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    if let inst = instances.selected {
                        Text(inst.name).font(.headline)
                        Text("\(inst.loader.rawValue) · изолированная папка")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("нет экземпляра").font(.headline)
                        Text("нажми, чтобы выбрать или создать")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(selected: instances.selected != nil)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: instances.selectedID)
        }
        .buttonStyle(PressScale())
    }

    private var launchButton: some View {
        Button {
            if instances.selected == nil {
                sheet = .download
            } else {
                showLaunchInfo = true
            }
        } label: {
            Text(instances.selected == nil ? "создать экземпляр" : "запустить")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(purple)
                )
        }
        .buttonStyle(PressScale())
    }

    // MARK: sheets

    @ViewBuilder
    private func sheetContent(_ s: HomeSheet) -> some View {
        switch s {
        case .accounts:
            NavigationView { AccountsView() }.navigationViewStyle(.stack)
        case .instances:
            NavigationView { InstancesView() }.navigationViewStyle(.stack)
        case .download:
            NavigationView { DownloadView() }.navigationViewStyle(.stack)
        case .settings:
            NavigationView { SettingsView() }.navigationViewStyle(.stack)
        case .files:
            NavigationView { FilesPlaceholderView() }.navigationViewStyle(.stack)
        }
    }

    // MARK: data

    private func loadNews() async {
        guard news.isEmpty else { return }
        do {
            news = try await NewsService.fetch()
            newsError = nil
        } catch is CancellationError {
            return
        } catch let e as URLError where e.code == .cancelled {
            return
        } catch {
            newsError = "новости не загрузились"
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        Link(destination: item.link ?? URL(string: "https://www.minecraft.net")!) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: item.imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.05)
                }
                .frame(width: 220, height: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(item.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let text = item.text {
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 220, alignment: .leading)
            .glassCard()
        }
    }
}

private struct FilesPlaceholderView: View {
    var body: some View {
        ZStack {
            SileniumBackground()
            VStack(spacing: 10) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text("файловый менеджер").font(.headline)
                Text("будет на этапе с экземплярами и модами")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Файлы")
    }
}
