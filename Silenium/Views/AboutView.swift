import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            ZStack {
                SileniumBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        creditCard(
                            title: "группа",
                            name: "VartixTM",
                            detail: "команда, которая делает silenium",
                            systemImage: "person.3.fill"
                        )
                        creditCard(
                            title: "разработчик",
                            name: "AngelKlear",
                            detail: "con1xx",
                            systemImage: "hammer.fill"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("О лаунчере")
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Silenium")
                .font(.title2.bold())
            Text("версия 1.0")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func creditCard(title: String, name: String, detail: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.06)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.headline)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .glassCard()
    }
}
