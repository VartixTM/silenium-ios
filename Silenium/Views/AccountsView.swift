import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: AccountStore

    @State private var newName = ""
    @State private var elyUser = ""
    @State private var elyPass = ""
    @State private var elyError: String?
    @State private var elyBusy = false

    private var nameIsValid: Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        return (3...16).contains(name.count)
            && name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
    }

    var body: some View {
        ZStack {
            SileniumBackground()
            List {
                Section("офлайн аккаунт") {
                    HStack {
                        TextField("ник (3-16)", text: $newName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit(addOffline)
                        Button("добавить", action: addOffline)
                            .disabled(!nameIsValid)
                    }
                }

                Section("ely.by") {
                    TextField("ник или email", text: $elyUser)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("пароль", text: $elyPass)
                    if let elyError = elyError {
                        Text(elyError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    Button {
                        Task { await loginElyBy() }
                    } label: {
                        if elyBusy {
                            ProgressView()
                        } else {
                            Text("войти")
                        }
                    }
                    .disabled(elyBusy || elyUser.isEmpty || elyPass.isEmpty)
                }

                Section("аккаунты") {
                    ForEach(store.accounts) { acc in
                        Button { store.select(acc.id) } label: {
                            AccountRow(account: acc, selected: acc.id == store.selectedID)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { store.remove(at: $0) }
                }
            }
        }
        .navigationTitle("Аккаунты")
    }

    private func addOffline() {
        guard nameIsValid else { return }
        store.addOffline(name: newName)
        newName = ""
    }

    private func loginElyBy() async {
        elyBusy = true
        elyError = nil
        defer { elyBusy = false }
        do {
            let (account, token) = try await ElyBy.login(username: elyUser, password: elyPass)
            store.addElyBy(account, token: token)
            elyPass = ""
        } catch {
            elyError = error.localizedDescription
        }
    }
}

struct AccountRow: View {
    let account: Account
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            AccountHead(account: account)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.headline)
                Text(account.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Theme.accent : .secondary)
        }
    }
}
