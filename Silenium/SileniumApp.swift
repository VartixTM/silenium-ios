import SwiftUI
import UIKit

@main
struct SileniumApp: App {
    @StateObject private var accounts = AccountStore()
    @StateObject private var instances = InstanceStore()
    @StateObject private var settings = SettingsStore()

    init() {
        // iOS 15: List на UITableView, красим фон через appearance, чтобы пятна были видны
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accounts)
                .environmentObject(instances)
                .environmentObject(settings)
                .preferredColorScheme(settings.theme.scheme)
        }
    }
}
