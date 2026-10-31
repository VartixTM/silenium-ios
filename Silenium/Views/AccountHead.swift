import SwiftUI
import UIKit

/// голова игрока. offline — mc-heads по нику, ely.by — лицо из скина skinsystem.ely.by
struct AccountHead: View {
    let account: Account
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: account.id) { await load() }
    }

    private func load() async {
        let url: URL?
        switch account.kind {
        case .offline:
            url = URL(string: "https://mc-heads.net/head/\(account.name)/120")
        case .elyby:
            url = URL(string: "https://skinsystem.ely.by/skins/\(account.name).png")
        }
        guard let url = url else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let src = UIImage(data: data) else { return }
            image = account.kind == .elyby ? face(from: src) : src
        } catch {
            // нет сети или ника — остаётся иконка-заглушка
        }
    }

    /// лицо 8x8 (8,8) + шапка (40,8) из текстуры скина
    private func face(from skin: UIImage) -> UIImage? {
        guard let cg = skin.cgImage else { return nil }
        let s = CGFloat(cg.width) / 64
        guard let base = cg.cropping(to: CGRect(x: 8 * s, y: 8 * s, width: 8 * s, height: 8 * s)) else {
            return nil
        }
        let hat = cg.cropping(to: CGRect(x: 40 * s, y: 8 * s, width: 8 * s, height: 8 * s))
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIImage(cgImage: base).draw(in: CGRect(origin: .zero, size: size))
            if let hatPart = hat {
                UIImage(cgImage: hatPart).draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
