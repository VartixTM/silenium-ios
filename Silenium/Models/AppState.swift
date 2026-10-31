import Foundation
import SwiftUI

// MARK: - instance (экземпляр с изолированной папкой)

struct Instance: Codable, Identifiable, Hashable {
    enum Loader: String, Codable, CaseIterable, Identifiable {
        case vanilla = "Vanilla"
        case forge = "Forge"
        case fabric = "Fabric"
        case quilt = "Quilt"

        var id: String { rawValue }
    }

    let id: UUID
    var name: String
    let versionID: String
    let loader: Loader
    var fabricAPI: Bool
}

@MainActor
final class InstanceStore: ObservableObject {
    @Published private(set) var instances: [Instance] = []
    @Published private(set) var selectedID: UUID?

    private let listKey = "silenium.instances"
    private let selectedKey = "silenium.selectedInstance"

    init() {
        if let data = UserDefaults.standard.data(forKey: listKey),
           let list = try? JSONDecoder().decode([Instance].self, from: data) {
            instances = list
        }
        selectedID = UserDefaults.standard.string(forKey: selectedKey).flatMap(UUID.init(uuidString:))
    }

    var selected: Instance? {
        instances.first { $0.id == selectedID }
    }

    /// своя папка игры на экземпляр: mods, saves, resourcepacks, datapacks, config
    static func gameDir(for instance: Instance) -> URL {
        SileniumPaths.base.appendingPathComponent("instances/\(instance.id.uuidString)", isDirectory: true)
    }

    @discardableResult
    func create(versionID: String, loader: Instance.Loader, fabricAPI: Bool) throws -> Instance {
        let name = loader == .vanilla ? versionID : "\(versionID) \(loader.rawValue)"
        let inst = Instance(id: UUID(), name: name, versionID: versionID, loader: loader, fabricAPI: fabricAPI)
        let dir = Self.gameDir(for: inst)
        for sub in ["mods", "saves", "resourcepacks", "datapacks", "config"] {
            try FileManager.default.createDirectory(
                at: dir.appendingPathComponent(sub, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
        instances.append(inst)
        save()
        if selectedID == nil { select(inst.id) }
        return inst
    }

    func select(_ id: UUID) {
        selectedID = id
        UserDefaults.standard.set(id.uuidString, forKey: selectedKey)
    }

    func remove(_ inst: Instance) {
        try? FileManager.default.removeItem(at: Self.gameDir(for: inst))
        instances.removeAll { $0.id == inst.id }
        if selectedID == inst.id {
            selectedID = instances.first?.id
        }
        if let id = selectedID {
            UserDefaults.standard.set(id.uuidString, forKey: selectedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedKey)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(instances) {
            UserDefaults.standard.set(data, forKey: listKey)
        }
    }
}

// MARK: - settings

@MainActor
final class SettingsStore: ObservableObject {
    enum AppTheme: String, CaseIterable, Identifiable {
        case system, dark, light

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "системная"
            case .dark: return "тёмная"
            case .light: return "светлая"
            }
        }

        var scheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .dark: return .dark
            case .light: return .light
            }
        }
    }

    enum Language: String, CaseIterable, Identifiable {
        case ru, en

        var id: String { rawValue }
        var title: String { self == .ru ? "русский" : "english" }
    }

    private let themeKey = "silenium.theme"
    private let languageKey = "silenium.language"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: themeKey) }
    }

    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: languageKey) }
    }

    @Published var render: RenderSettings {
        didSet {
            if let data = try? JSONEncoder().encode(render) {
                UserDefaults.standard.set(data, forKey: "silenium.render")
            }
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "silenium.render"),
           let saved = try? JSONDecoder().decode(RenderSettings.self, from: data) {
            render = saved
        } else {
            render = RenderSettings()
        }
        theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: themeKey) ?? "") ?? .dark
        language = Language(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .ru
    }
}
