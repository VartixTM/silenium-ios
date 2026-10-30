import Foundation

struct VersionManifest: Decodable {
    struct Latest: Decodable {
        let release: String
        let snapshot: String
    }

    struct Entry: Decodable, Identifiable {
        let id: String
        let type: String
        let url: URL
    }

    let latest: Latest
    let versions: [Entry]
}

enum MojangAPI {
    static let manifestURL = URL(string: "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")!

    static func fetchManifest() async throws -> VersionManifest {
        let (data, response) = try await URLSession.shared.data(from: manifestURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(VersionManifest.self, from: data)
    }

    static func releases(_ m: VersionManifest) -> [VersionManifest.Entry] {
        m.versions.filter { $0.type == "release" }
    }

    static func snapshots(_ m: VersionManifest) -> [VersionManifest.Entry] {
        m.versions.filter { $0.type == "snapshot" }
    }
}
