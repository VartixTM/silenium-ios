import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: AccountStore
    @State private var newName = ""

    private var nameIsValid: Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        return (3...16).contains(name.count)
            && name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
    }

    var body: some View {
        ZStack {
            SileniumBackground()
            List {
                Section {
                    addRow
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("аккаунты") {
                    ForEach(store.accounts) { acc in
                        AccountRow(account: acc, selected: acc.id == store.selectedID)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    store.select(acc.id)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { store.remove(at: $0) }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.accounts)
        }
        .navigationTitle("Аккаунты")
    }

    private var addRow: some View {
        HStack(spacing: 10) {
            TextField("ник (3-16)", text: $newName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(PressScale())
            .disabled(!nameIsValid)
            .foregroundStyle(nameIsValid ? Theme.accent : .secondary)
        }
        .glassCard()
        .animation(.easeOut(duration: 0.2), value: nameIsValid)
    }

    private func add() {
        guard nameIsValid else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            store.addOffline(name: newName)
        }
        newName = ""
    }
}

struct AccountRow: View {
    let account: Account
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: account.headURL) { image in
                image.interpolation(.none).resizable().scaledToFit()
            } placeholder: {
                Text(String(account.name.prefix(1)).uppercased())
                    .font(.title3.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .frame(width: 44, height: 44)
            .background(Theme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.headline)
                Text(account.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(selected ? Theme.accent : .secondary)
                .scaleEffect(selected ? 1.1 : 1)
        }
        .glassCard(selected: selected)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }
}
