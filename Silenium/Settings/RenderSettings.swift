import Foundation

// набор настроек по образцу Zalith Launcher 2 (AllSettings.kt: renderer, resolutionRatio 25..300,
// showFPS, fpsDisplayMode number/chart, showMemory, ramAllocation min 256, jvmArgs).
// fps-лимит добавлен свой, его применим при запуске.

enum RendererKind: String, CaseIterable, Identifiable, Codable {
    case gl4es
    case angle
    case zink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gl4es: return "GL4ES 1.14"
        case .angle: return "MetalANGLE (GLES)"
        case .zink: return "Zink (Vulkan через MoltenVK)"
        }
    }
}

enum FpsLimit: Int, CaseIterable, Identifiable, Codable {
    case unlimited = 0
    case fps30 = 30
    case fps60 = 60
    case fps120 = 120

    var id: Int { rawValue }

    var title: String {
        self == .unlimited ? "без лимита" : "\(rawValue)"
    }
}

enum FpsDisplayMode: String, CaseIterable, Identifiable, Codable {
    case number
    case chart

    var id: String { rawValue }

    var title: String {
        self == .number ? "число" : "график"
    }
}

struct RenderSettings: Codable, Equatable {
    var renderer: RendererKind = .gl4es
    var resolutionPercent: Int = 100
    var fpsLimit: FpsLimit = .fps60
    var showFPS: Bool = true
    var fpsDisplay: FpsDisplayMode = .number
    var showMemory: Bool = false
    var ramMB: Int = 2048
    var jvmArgs: String = ""

    static let resolutionRange = 25...300

    /// от 256 МБ до физической памяти устройства
    static var ramRange: ClosedRange<Int> {
        let total = Int(ProcessInfo.processInfo.physicalMemory / 1_048_576)
        return 256...max(256, total)
    }
}
