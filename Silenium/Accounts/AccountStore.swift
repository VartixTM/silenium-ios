import Foundation

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var selectedID: UUID?

    private let listKey = "silenium.accounts"
    private let selectedKey = "silenium.selected"

    init() {
        if let list = JSONStorage.load([Account].self, from: SileniumPaths.accountsFile) {
            accounts = list
        }
        selectedID = UserDefaults.standard.string(forKey: selectedKey).flatMap(UUID.init(uuidString:))
    }

    var selected: Account? {
        accounts.first { $0.id == selectedID }
    }

    /// токен ely.by живёт в keychain, в UserDefaults его нет
    func token(for account: Account) -> String? {
        Keychain.get(tokenKey(account.id))
    }

    func addOffline(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard (3...16).contains(trimmed.count),
              !accounts.contains(where: { $0.name == trimmed && $0.kind == .offline })
        else { return }

        let acc = OfflineAccount.make(name: trimmed)
        accounts.append(acc)
        save()
        if selectedID == nil { select(acc.id) }
    }

    func addElyBy(_ account: Account, token: String) {
        Keychain.set(token, for: tokenKey(account.id))
        if let i = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[i] = account
        } else {
            accounts.append(account)
        }
        save()
        select(account.id)
    }

    func select(_ id: UUID) {
        selectedID = id
        persistSelected()
    }

    func remove(at offsets: IndexSet) {
        for i in offsets where accounts[i].kind == .elyby {
            Keychain.delete(tokenKey(accounts[i].id))
        }
        let removedIDs = offsets.map { accounts[$0].id }
        accounts.remove(atOffsets: offsets)
        if let sel = selectedID, removedIDs.contains(sel) {
            selectedID = accounts.first?.id
            persistSelected()
        }
        save()
    }

    private func tokenKey(_ id: UUID) -> String {
        "ely.token.\(id.uuidString)"
    }

    private func persistSelected() {
        if let id = selectedID {
            UserDefaults.standard.set(id.uuidString, forKey: selectedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedKey)
        }
    }

    private func save() {
        JSONStorage.save(accounts, to: SileniumPaths.accountsFile)
    }
}
