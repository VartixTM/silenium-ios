import SwiftUI
import UIKit

@main
struct SileniumApp: App {
    @StateObject private var accounts = AccountStore()

    init() {
        // iOS 15: scrollContentBackground недоступен, List на UITableView — красим через appearance,
        // чтобы фон-пятна были видны за списками
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accounts)
        }
    }
}
