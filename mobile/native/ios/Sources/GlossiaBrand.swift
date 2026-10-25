import SwiftUI

// Bundled semantic colors are only an offline/older-server fallback. Validated
// server tokens arrive through the view environment without recreating models.
struct GlossiaBrand {
    let canvas, subtle, surface, ink, muted, accent, onAccent, tint, border: Color
    var accentSoft: Color { accent.opacity(0.13) }
    let radius: CGFloat
    let buttonRadius: CGFloat
    static let space: CGFloat = 16
    static let gutter: CGFloat = 24

    init(theme: GlossiaTheme? = nil, scheme: ColorScheme = .light) {
        let palette = scheme == .dark ? theme?.dark : theme?.light
        func token(_ hex: String?, light: UInt32, dark: UInt32) -> Color {
            guard let hex, let value = UInt32(hex.dropFirst(), radix: 16) else { return Self.color(light: light, dark: dark) }
            return Self.color(light: value, dark: value)
        }
        canvas = token(palette?.background, light: 0xFAF8F5, dark: 0x1C1917)
        subtle = token(palette?.subtle, light: 0xF2EFE9, dark: 0x2A2621)
        surface = token(palette?.surface, light: 0xFFFFFF, dark: 0x2A2621)
        ink = token(palette?.text, light: 0x1C1917, dark: 0xFAF8F5)
        muted = token(palette?.secondaryText, light: 0x5C564E, dark: 0xD1CDC5)
        accent = token(palette?.accent, light: 0x6D3CC4, dark: 0xD0BCFF)
        onAccent = token(palette?.onAccent, light: 0xFFFFFF, dark: 0x381E72)
        tint = token(palette?.tint, light: 0x6D3CC4, dark: 0xD0BCFF)
        border = token(palette?.border, light: 0xE4E0D9, dark: 0x3D3833)
        radius = theme?.cardRadius ?? 12
        buttonRadius = theme?.buttonRadius ?? 8
    }

    private static func color(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

typealias GlossiaRequest = @MainActor ([String: Any]) async throws -> [String: Any]

struct GlossiaErrorView: View {
    let message: String
    let retry: () -> Void
    @Environment(\.glossiaTokens) private var tokens

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "exclamationmark.circle")
                .foregroundStyle(tokens.muted).font(.callout)
            Button("Retry", action: retry)
        }.padding(.vertical, 8)
    }
}
