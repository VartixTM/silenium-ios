import SwiftUI

@main
struct SileniumApp: App {
    @StateObject private var accounts = AccountStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accounts)
        }
    }
}
