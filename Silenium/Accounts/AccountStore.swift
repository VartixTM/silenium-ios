import Foundation

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var selectedID: UUID?

    private let listKey = "silenium.accounts"
    private let selectedKey = "silenium.selected"

    init() {
        if let data = UserDefaults.standard.data(forKey: listKey),
           let list = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = list
        }
        selectedID = UserDefaults.standard.string(forKey: selectedKey)
            .flatMap(UUID.init(uuidString:))
    }

    var selected: Account? {
        accounts.first { $0.id == selectedID }
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

    func select(_ id: UUID) {
        selectedID = id
        UserDefaults.standard.set(id.uuidString, forKey: selectedKey)
    }

    func remove(at offsets: IndexSet) {
        let removedIDs = offsets.map { accounts[$0].id }
        accounts.remove(atOffsets: offsets)
        if let sel = selectedID, removedIDs.contains(sel) {
            selectedID = accounts.first?.id
            UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedKey)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: listKey)
        }
    }
}
