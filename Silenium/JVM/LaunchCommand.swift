import Foundation

/// аргументы для JLI_Launch: "java" подставит сам JLI, сюда идут опции jvm, класс и аргументы игры.
enum LaunchCommand {
    static func arguments(meta: VersionMeta,
                          instance: Instance,
                          account: Account,
                          accessToken: String?,
                          render: RenderSettings) -> [String] {
        var args: [String] = []

        args.append("-Xmx\(render.ramMB)M")
        args.append("-Djava.library.path=\(SileniumPaths.base.appendingPathComponent("natives").path)")
        args += render.jvmArgs
            .split(separator: " ")
            .map(String.init)
            .filter { $0.hasPrefix("-") }

        args += ["-cp", classpath(for: meta)]
        args.append(meta.mainClass)

        args += [
            "--username", account.name,
            "--version", meta.id,
            "--gameDir", InstanceStore.gameDir(for: instance).path,
            "--assetsDir", SileniumPaths.assets.path,
            "--assetIndex", meta.assetIndex.id,
            "--uuid", account.id.uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            "--accessToken", accessToken ?? "0",
            "--userType", account.kind == .elyby ? "mojang" : "legacy",
            "--versionType", "release"
        ]
        return args
    }

    /// библиотеки, которые разрешены для нашей платформы, плюс клиентский jar
    static func classpath(for meta: VersionMeta) -> String {
        var paths: [String] = []
        for lib in meta.libraries where lib.isAllowed {
            if let path = lib.downloads?.artifact?.path {
                paths.append(SileniumPaths.libraries.appendingPathComponent(path).path)
            }
        }
        paths.append(SileniumPaths.versions.appendingPathComponent("\(meta.id)/\(meta.id).jar").path)
        return paths.joined(separator: ":")
    }
}
