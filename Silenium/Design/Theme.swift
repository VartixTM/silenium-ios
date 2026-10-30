import SwiftUI

enum Theme {
    static let accent = Color(red: 0.36, green: 0.85, blue: 0.58)
    static let accentDeep = Color(red: 0.14, green: 0.46, blue: 0.80)
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.10)
}

struct SileniumBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Theme.bg
            Circle()
                .fill(Theme.accent.opacity(0.20))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: drift ? -120 : 110, y: drift ? -280 : -190)
            Circle()
                .fill(Theme.accentDeep.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: drift ? 140 : -100, y: drift ? 280 : 210)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }
}

struct GlassCard: ViewModifier {
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Theme.accent : Color.white.opacity(0.08),
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

struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
