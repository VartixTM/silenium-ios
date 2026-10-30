import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VersionListView()
                .tabItem { Label("Версии", systemImage: "square.stack.3d.up.fill") }
            AccountsView()
                .tabItem { Label("Аккаунты", systemImage: "person.crop.circle.fill") }
            AboutView()
                .tabItem { Label("О лаунчере", systemImage: "info.circle.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }
}
