import SwiftUI

/// авторы: группа и разработчик. встраивается в настройки.
struct AuthorsSection: View {
    var body: some View {
        VStack(spacing: 10) {
            authorRow(title: "группа", name: "VartixTM", detail: "команда, которая делает silenium", icon: "person.3.fill")
            authorRow(title: "разработчик", name: "AngelKlear", detail: "con1xx", icon: "hammer.fill")
        }
    }

    private func authorRow(title: String, name: String, detail: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.06)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(name).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
