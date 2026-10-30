import Foundation
import CryptoKit

struct Account: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case offline = "offline"
        case elyby = "ely.by"
    }

    let id: UUID
    let name: String
    let kind: Kind
    var accessToken: String = "0"
}

enum OfflineAccount {
    // та же схема, что у сервера: uuid v3 от "OfflinePlayer:<name>"
    static func uuid(for name: String) -> UUID {
        var b = Array(Insecure.MD5.hash(data: Data("OfflinePlayer:\(name)".utf8)))
        b[6] = (b[6] & 0x0f) | 0x30
        b[8] = (b[8] & 0x3f) | 0x80
        let h = b.map { String(format: "%02x", $0) }.joined()
        let s = "\(h.prefix(8))-\(h.dropFirst(8).prefix(4))-\(h.dropFirst(12).prefix(4))-\(h.dropFirst(16).prefix(4))-\(h.dropFirst(20))"
        return UUID(uuidString: s)!
    }

    static func make(name: String) -> Account {
        Account(id: uuid(for: name), name: name, kind: .offline)
    }
}
