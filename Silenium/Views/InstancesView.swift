import SwiftUI

struct InstancesView: View {
    @EnvironmentObject private var instances: InstanceStore

    var body: some View {
        ZStack {
            SileniumBackground()
            ScrollView {
                LazyVStack(spacing: 10) {
                    if instances.instances.isEmpty {
                        Text("экземпляров пока нет. создай через кнопку сверху справа.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                    }
                    ForEach(instances.instances) { inst in
                        Button { instances.select(inst.id) } label: {
                            InstanceRow(inst: inst, selected: inst.id == instances.selectedID)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { instances.remove(inst) } label: {
                                Label("удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Экземпляры")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("создать", destination: DownloadView())
            }
        }
    }
}

private struct InstanceRow: View {
    let inst: Instance
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.fill")
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(inst.name).font(.headline)
                Text("\(inst.loader.rawValue) · моды и миры только здесь")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Theme.accent : .secondary)
        }
        .glassCard(selected: selected)
    }
}
