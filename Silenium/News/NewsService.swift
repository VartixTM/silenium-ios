import Foundation

// лента новостей лаунчера Mojang. формат не проверял отсюда, поля необязательные, чтобы декодер не падал.
struct NewsItem: Decodable, Identifiable {
    struct Img: Decodable {
        let url: String?
    }

    let title: String
    let text: String?
    let readMoreLink: String?
    let image: Img?

    var id: String { readMoreLink ?? title }

    var link: URL? {
        readMoreLink.flatMap(URL.init(string:))
    }

    var imageURL: URL? {
        guard let u = image?.url else { return nil }
        if u.hasPrefix("http") { return URL(string: u) }
        return URL(string: "https://launchercontent.mojang.com/" + u)
    }
}

private struct NewsFeed: Decodable {
    let entries: [NewsItem]
}

enum NewsService {
    static let feedURL = URL(string: "https://launchercontent.mojang.com/v2/news.json")!

    static func fetch() async throws -> [NewsItem] {
        let (data, response) = try await URLSession.shared.data(from: feedURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(NewsFeed.self, from: data).entries
    }
}
