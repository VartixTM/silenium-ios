import SwiftUI

enum Theme {
    static let accent = Color(red: 0.36, green: 0.85, blue: 0.58)
    static let accentDeep = Color(red: 0.14, green: 0.46, blue: 0.80)
    static let purple = Color(red: 0.37, green: 0.33, blue: 0.56)
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.10)
}

/// фон статичный, без анимаций. в светлой теме — системный серый
struct SileniumBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        (scheme == .dark ? Theme.bg : Color(.systemGroupedBackground))
            .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Theme.accent : Color.primary.opacity(0.08),
                                    lineWidth: selected ? 1.5 : 1)
                    )
            )
    }
}

extension View {
    func glassCard(selected: Bool = false) -> some View {
        modifier(GlassCard(selected: selected))
    }
}

/// обычный стиль кнопки без анимации нажатия
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
