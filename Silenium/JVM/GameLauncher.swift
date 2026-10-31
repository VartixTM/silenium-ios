import Foundation

/// запуск игры: читает json версии, собирает аргументы, поднимает JVM в отдельном потоке.
enum GameLauncher {
    enum LaunchError: LocalizedError {
        case versionNotInstalled(String)
        case runtimeMissing(Int)

        var errorDescription: String? {
            switch self {
            case .versionNotInstalled(let v):
                return "версия \(v) не установлена, скачай её ещё раз"
            case .runtimeMissing(let major):
                return "в приложении нет java \(major): сборка не положила рантайм"
            }
        }
    }

    /// запускает игру и возвращается сразу. JVM работает в своём потоке, при выходе процесс завершается.
    static func start(instance: Instance,
                      account: Account,
                      accessToken: String?,
                      render: RenderSettings) throws {
        let metaURL = SileniumPaths.versions
            .appendingPathComponent("\(instance.versionID)/\(instance.versionID).json")
        guard let data = try? Data(contentsOf: metaURL) else {
            throw LaunchError.versionNotInstalled(instance.versionID)
        }
        let meta = try JSONDecoder().decode(VersionMeta.self, from: data)

        let major = meta.javaVersion?.majorVersion ?? 8
        let home = javaHome(major: major)
        guard FileManager.default.fileExists(atPath: home.path) else {
            throw LaunchError.runtimeMissing(major)
        }

        let args = LaunchCommand.arguments(meta: meta,
                                           instance: instance,
                                           account: account,
                                           accessToken: accessToken,
                                           render: render)

        let thread = Thread {
            let code = SileniumJVM.launch(withJavaHome: home.path, arguments: args)
            NSLog("[silenium] JLI_Launch вернул \(code)")
        }
        // minecraft любит глубокий стек, по умолчанию у потока на iOS мало
        thread.stackSize = 16 << 20
        thread.start()
    }

    /// рантайм лежит в бандле: Silenium.app/java/<major>, кладёт его CI
    static func javaHome(major: Int) -> URL {
        Bundle.main.bundleURL.appendingPathComponent("java/\(major)", isDirectory: true)
    }
}
