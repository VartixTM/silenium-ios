import Foundation

/// вход ely.by через yggdrasil (authserver.ely.by).
/// 2FA пока не поддерживается: там нужен формат "пароль:код".
enum ElyBy {
    static let authURL = URL(string: "https://authserver.ely.by/auth/authenticate")!

    struct AuthError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private struct ErrorBody: Decodable {
        let errorMessage: String?
    }

    private struct AuthResponse: Decodable {
        struct Profile: Decodable {
            let id: String
            let name: String
        }
        let accessToken: String
        let selectedProfile: Profile?
    }

    static func login(username: String, password: String) async throws -> (Account, String) {
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "agent": ["name": "Minecraft", "version": 1],
            "username": username,
            "password": password,
            "clientToken": UUID().uuidString,
            "requestUser": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.errorMessage
            throw AuthError(message: message ?? "ошибка входа (\(status))")
        }

        let result = try JSONDecoder().decode(AuthResponse.self, from: data)
        guard let profile = result.selectedProfile,
              let uuid = uuid(fromHex: profile.id) else {
            throw AuthError(message: "у аккаунта нет профиля майнкрафта")
        }
        return (Account(id: uuid, name: profile.name, kind: .elyby), result.accessToken)
    }

    /// ely.by отдаёт id без дефисов, uuid нужен с дефисами
    static func uuid(fromHex hex: String) -> UUID? {
        guard hex.count == 32 else { return nil }
        let s = hex
        return UUID(uuidString: "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20))")
    }
}
