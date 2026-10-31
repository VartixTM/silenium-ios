import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var accounts: AccountStore
    @EnvironmentObject private var instances: InstanceStore
    @EnvironmentObject private var settings: SettingsStore

    @State private var news: [NewsItem] = []
    @State private var newsError: String?
    @State private var showLaunchInfo = false
    @State private var launchMessage = ""

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
        .navigationBarHidden(true)
        .task { await loadNews() }
        .alert("запуск", isPresented: $showLaunchInfo) {
            Button("ок", role: .cancel) {}
        } message: {
            Text(launchMessage)
        }
    }

    // MARK: верхняя панель

    private var topBar: some View {
        HStack(spacing: 4) {
            Text("Silenium")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Spacer()
            NavigationLink(destination: FilesPlaceholderView()) { topIcon("folder.fill") }
            NavigationLink(destination: AccountsView()) { topIcon("person.2.fill") }
            NavigationLink(destination: DownloadView()) { topIcon("arrow.down.circle.fill") }
            NavigationLink(destination: SettingsView()) { topIcon("gearshape.fill") }
        }
    }

    private func topIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.title2)
            .frame(width: 44, height: 44)
            .foregroundColor(.primary)
    }

    // MARK: новости

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
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: правая панель

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("версия")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            NavigationLink(destination: AccountsView()) { accountCard }
            NavigationLink(destination: InstancesView()) { instanceCard }
            Spacer(minLength: 0)
            launchButton
        }
    }

    private var accountCard: some View {
        HStack(spacing: 12) {
            if let acc = accounts.selected {
                AccountHead(account: acc)
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

    private var instanceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                if let inst = instances.selected {
                    Text(inst.name).font(.headline)
                    Text(inst.loader.rawValue).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("нет экземпляра").font(.headline)
                    Text("выбрать или создать").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(selected: instances.selected != nil)
    }

    @ViewBuilder
    private var launchButton: some View {
        if instances.selected == nil {
            NavigationLink(destination: DownloadView()) {
                launchLabel("создать экземпляр")
            }
        } else {
            Button { launch() } label: {
                launchLabel("запустить")
            }
        }
    }

    private func launchLabel(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.purple)
            )
    }

    // MARK: запуск

    private func launch() {
        guard let inst = instances.selected else { return }
        guard let account = accounts.selected else {
            launchMessage = "сначала выбери аккаунт"
            showLaunchInfo = true
            return
        }
        do {
            try GameLauncher.start(instance: inst,
                                   account: account,
                                   accessToken: accounts.token(for: account),
                                   render: settings.render)
            launchMessage = "JVM запущена, лог смотри в консоли устройства."
        } catch {
            launchMessage = error.localizedDescription
        }
        showLaunchInfo = true
    }

    // MARK: данные

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
                    Color.gray.opacity(0.15)
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
