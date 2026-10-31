import Foundation
import AuthenticationServices
import UIKit

/// ely.by: вход через браузер (oauth2 authorization code) и legacy логин/пароль (yggdrasil).
enum ElyBy {
    // FILL: зарегистрируй своё приложение на account.ely.by и впиши сюда client_id и client_secret.
    // redirect_uri должен совпадать с тем, что указано в регистрации (silenium://oauth/ely).
    static let oauthClientID = "FILL_CLIENT_ID"
    static let oauthClientSecret = "FILL_CLIENT_SECRET"
    static let oauthCallbackScheme = "silenium"
    static let oauthRedirectURI = "silenium://oauth/ely"

    struct AuthError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    // MARK: oauth2 (браузер)

    @MainActor
    private static var webSession: ASWebAuthenticationSession?

    static func oauthLogin() async throws -> (Account, String) {
        guard oauthClientID != "FILL_CLIENT_ID" else {
            throw AuthError(message: "не вписан client_id ely.by (Accounts/ElyBy.swift)")
        }

        let state = UUID().uuidString
        var comps = URLComponents(string: "https://account.ely.by/oauth2/v1")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: oauthClientID),
            URLQueryItem(name: "redirect_uri", value: oauthRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "account_info offline_access minecraft_server_session"),
            URLQueryItem(name: "prompt", value: "select_account"),
            URLQueryItem(name: "state", value: state)
        ]

        let callback = try await runWebAuth(url: comps.url!)
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func item(_ name: String) -> String? { items.first { $0.name == name }?.value }

        if let error = item("error") {
            throw AuthError(message: item("error_message") ?? error)
        }
        guard item("state") == state, let code = item("code") else {
            throw AuthError(message: "ответ ely.by не сошёлся (state)")
        }

        let token = try await exchange(code: code)
        let info = try await userInfo(token: token.accessToken)
        guard let uuid = uuid(fromHex: info.uuid) else {
            throw AuthError(message: "ely.by вернул неверный uuid")
        }
        return (Account(id: uuid, name: info.username, kind: .elyby), token.accessToken)
    }

    @MainActor
    private static func runWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: oauthCallbackScheme) { callback, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callback = callback {
                    continuation.resume(returning: callback)
                } else {
                    continuation.resume(throwing: AuthError(message: "пустой ответ от ely.by"))
                }
            }
            session.presentationContextProvider = WebAuthAnchor.shared
            webSession = session
            session.start()
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
    }

    private struct UserInfo: Decodable {
        let uuid: String
        let username: String
    }

    private static func exchange(code: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://account.ely.by/api/oauth2/v1/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "client_id", value: oauthClientID),
            URLQueryItem(name: "client_secret", value: oauthClientSecret),
            URLQueryItem(name: "redirect_uri", value: oauthRedirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code)
        ]
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError(message: "обмен кода на токен не прошёл")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TokenResponse.self, from: data)
    }

    private static func userInfo(token: String) async throws -> UserInfo {
        var request = URLRequest(url: URL(string: "https://account.ely.by/api/account/v1/info")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError(message: "не удалось получить профиль ely.by")
        }
        return try JSONDecoder().decode(UserInfo.self, from: data)
    }

    // MARK: legacy (логин и пароль)

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
        var request = URLRequest(url: URL(string: "https://authserver.ely.by/auth/authenticate")!)
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

    /// id приходит без дефисов (32 символа), uuid нужен с дефисами; дефисы допускаются
    static func uuid(fromHex value: String) -> UUID? {
        let s = value.replacingOccurrences(of: "-", with: "")
        guard s.count == 32 else { return nil }
        return UUID(uuidString: "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20))")
    }
}

/// окно, над которым открывается браузер входа
final class WebAuthAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthAnchor()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}
