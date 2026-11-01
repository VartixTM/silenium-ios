import Foundation
import CryptoKit
import ZIPFoundation

// MARK: - version json (piston-meta)

struct VersionMeta: Decodable {
    struct Artifact: Decodable {
        let path: String?
        let url: URL
        let sha1: String
        let size: Int
    }

    struct OS: Decodable {
        let name: String?
    }

    struct Rule: Decodable {
        let action: String
        let os: OS?
    }

    struct Library: Decodable {
        struct Downloads: Decodable {
            let artifact: Artifact?
            let classifiers: [String: Artifact]?
        }
        let name: String
        let downloads: Downloads?
        let rules: [Rule]?
        /// os -> classifier, например "osx": "natives-osx"
        let natives: [String: String]?

        /// classifier с нативами для mac (natives-osx / natives-macos), nil если у библиотеки нет нативов
        var macNativesClassifier: String? {
            guard let natives else { return nil }
            return (natives["osx"] ?? natives["macos"])?.replacingOccurrences(of: "${arch}", with: "64")
        }

        /// эмулируем mac: правила без os и с os=osx применяем, linux/windows — нет
        var isAllowed: Bool {
            guard let rules else { return true }
            var allowed = false
            for rule in rules where rule.os == nil || rule.os?.name == "osx" {
                allowed = rule.action == "allow"
            }
            return allowed
        }
    }

    struct Downloads: Decodable {
        let client: Artifact
    }

    struct AssetIndexRef: Decodable {
        let id: String
        let url: URL
        let sha1: String
    }

    let id: String
    let mainClass: String
    let downloads: Downloads
    let assetIndex: AssetIndexRef
    let libraries: [Library]
    let javaVersion: JavaVersion?
}

struct JavaVersion: Decodable {
    let majorVersion: Int
}

struct AssetIndex: Decodable {
    struct Object: Decodable {
        let hash: String
        let size: Int
    }
    let objects: [String: Object]
}

// MARK: - paths

enum SileniumPaths {
    static let base: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Silenium", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static var versions: URL { base.appendingPathComponent("versions", isDirectory: true) }
    static var libraries: URL { base.appendingPathComponent("libraries", isDirectory: true) }
    static var assets: URL { base.appendingPathComponent("assets", isDirectory: true) }

    /// нативы на версию: разные версии lwjgl не должны мешать друг другу
    static func natives(for versionID: String) -> URL {
        versions.appendingPathComponent("\(versionID)/natives", isDirectory: true)
    }
}

// MARK: - natives

enum NativesExtractor {
    /// распаковывает natives-jar в папку версии. у каждого jar свой META-INF/MANIFEST.MF,
    /// поэтому каждый распаковываем во временную папку и переносим только библиотеки (с заменой).
    static func extract(jars: [URL], to dir: URL) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: dir)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        for (index, jar) in jars.enumerated() {
            let tmp = dir.deletingLastPathComponent()
                .appendingPathComponent("natives-tmp-\(index)", isDirectory: true)
            try? fm.removeItem(at: tmp)
            try fm.unzipItem(at: jar, to: tmp)
            let items = try fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil)
            for item in items where item.lastPathComponent != "META-INF" {
                let target = dir.appendingPathComponent(item.lastPathComponent)
                if fm.fileExists(atPath: target.path) {
                    try fm.removeItem(at: target)
                }
                try fm.moveItem(at: item, to: target)
            }
            try? fm.removeItem(at: tmp)
        }
    }
}

// MARK: - downloader

enum Downloader {
    /// качает файл, если его нет или sha1 не совпадает. sha1 nil — без проверки.
    static func fetch(_ url: URL, to dest: URL, sha1: String?) async throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path), let sha1, sha1Hex(of: dest) == sha1 {
            return
        }
        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)

        let (tmp, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        if let sha1, sha1Hex(of: tmp) != sha1 {
            throw URLError(.cannotParseResponse)
        }
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: tmp, to: dest)
    }

    static func sha1Hex(of url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - installer

struct InstalledVersion {
    let meta: VersionMeta
    let dir: URL
    var jar: URL { dir.appendingPathComponent("\(meta.id).jar") }
}

@MainActor
final class VersionInstaller: ObservableObject {
    @Published private(set) var status = ""
    @Published private(set) var progress: Double = 0

    /// ставит версию: json, клиент, библиотеки, ассеты. запуска тут нет.
    func install(_ entry: VersionManifest.Entry) async throws -> InstalledVersion {
        status = "манифест версии"
        progress = 0
        let (metaData, _) = try await URLSession.shared.data(from: entry.url)
        let meta = try JSONDecoder().decode(VersionMeta.self, from: metaData)

        let dir = SileniumPaths.versions.appendingPathComponent(meta.id, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try metaData.write(to: dir.appendingPathComponent("\(meta.id).json"))

        status = "клиент"
        let installed = InstalledVersion(meta: meta, dir: dir)
        try await Downloader.fetch(meta.downloads.client.url,
                                   to: installed.jar,
                                   sha1: meta.downloads.client.sha1)

        status = "библиотеки"
        let libs: [(URL, URL, String?)] = meta.libraries
            .filter { $0.isAllowed }
            .compactMap { $0.downloads?.artifact }
            .compactMap { art in
                guard let path = art.path else { return nil }
                return (art.url, SileniumPaths.libraries.appendingPathComponent(path), art.sha1)
            }
        try await downloadAll(libs)

        // нативы (liblwjgl.dylib и прочее) лежат в отдельных classifier-jar, их надо скачать и распаковать
        status = "нативы"
        let nativeJars: [(URL, URL, String?)] = meta.libraries
            .filter { $0.isAllowed }
            .compactMap { lib -> (URL, URL, String?)? in
                guard let key = lib.macNativesClassifier,
                      let art = lib.downloads?.classifiers?[key],
                      let path = art.path else { return nil }
                return (art.url, SileniumPaths.libraries.appendingPathComponent(path), art.sha1)
            }
        try await downloadAll(nativeJars)
        try NativesExtractor.extract(
            jars: nativeJars.map { $0.1 },
            to: SileniumPaths.natives(for: meta.id)
        )

        status = "ассеты"
        let indexFile = SileniumPaths.assets
            .appendingPathComponent("indexes/\(meta.assetIndex.id).json")
        try await Downloader.fetch(meta.assetIndex.url, to: indexFile, sha1: meta.assetIndex.sha1)
        let index = try JSONDecoder().decode(AssetIndex.self, from: Data(contentsOf: indexFile))

        let assets: [(URL, URL, String?)] = index.objects.values.map { obj in
            let prefix = String(obj.hash.prefix(2))
            let url = URL(string: "https://resources.download.minecraft.net/\(prefix)/\(obj.hash)")!
            let dest = SileniumPaths.assets.appendingPathComponent("objects/\(prefix)/\(obj.hash)")
            return (url, dest, obj.hash)
        }
        try await downloadAll(assets)

        status = "готово"
        progress = 1
        return installed
    }

    /// качаем батчами по 12, прогресс по количеству файлов
    private func downloadAll(_ items: [(URL, URL, String?)]) async throws {
        guard !items.isEmpty else { return }
        var done = 0
        let total = Double(items.count)
        for start in stride(from: 0, to: items.count, by: 12) {
            let slice = items[start..<min(start + 12, items.count)]
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (url, dest, sha) in slice {
                    group.addTask {
                        try await Downloader.fetch(url, to: dest, sha1: sha)
                    }
                }
                try await group.waitForAll()
            }
            done += slice.count
            progress = Double(done) / total
        }
    }
}
