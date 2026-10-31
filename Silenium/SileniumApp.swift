import SwiftUI
import UIKit

/// UIKit-хост вместо SwiftUI App: SwiftUI-граф (AppGraph.shared) нельзя пересоздавать,
/// а JVM на старте трогает окна/сцены. перед запуском игры корень окна снимаем (как Amethyst).
// точка входа в main.m (UIApplicationMain с этим именем); @main убран специально
@objc(SileniumAppDelegate)
final class AppDelegate: UIResponder, UIApplicationDelegate {
    static weak var shared: AppDelegate?
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.shared = self
        // iOS 15: List на UITableView, красим фон через appearance, чтобы пятна были видны
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = UIHostingController(rootView: RootHost())
        w.makeKeyAndVisible()
        window = w
        return true
    }

    /// убирает SwiftUI-дерево из окна; вызывать перед JLI_Launch
    func detachUIForGame() {
        window?.rootViewController = UIViewController()
    }
}

struct RootHost: View {
    @StateObject private var accounts = AccountStore()
    @StateObject private var instances = InstanceStore()
    @StateObject private var settings = SettingsStore()

    var body: some View {
        ContentView()
            .environmentObject(accounts)
            .environmentObject(instances)
            .environmentObject(settings)
            .preferredColorScheme(settings.theme.scheme)
    }
}
