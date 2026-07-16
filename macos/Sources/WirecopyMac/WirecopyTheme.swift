import AppKit
import CoreText
import SwiftUI

enum WirecopyTheme {
    static var canvas: Color {
        adaptive(light: srgb(1.000000, 0.969053, 0.929263),
                 dark: srgb(0.089743, 0.059826, 0.103365))
    }

    static var canvasSoft: Color {
        adaptive(light: srgb(0.988736, 0.940881, 0.904984),
                 dark: srgb(0.126207, 0.095018, 0.140585))
    }

    static var ink: Color {
        adaptive(light: srgb(0.156868, 0.090301, 0.184283),
                 dark: srgb(0.925432, 0.890481, 0.846213))
    }

    static var inkMuted: Color {
        adaptive(light: srgb(0.431618, 0.337910, 0.435513),
                 dark: srgb(0.682335, 0.623144, 0.684091))
    }

    static var rule: Color {
        adaptive(light: srgb(0.847486, 0.792317, 0.863249),
                 dark: srgb(0.266083, 0.220719, 0.280403))
    }

    static var peach: Color {
        adaptive(light: srgb(0.955945, 0.642861, 0.509813),
                 dark: srgb(0.922389, 0.642620, 0.523072))
    }

    static var lilac: Color {
        adaptive(light: srgb(0.934131, 0.893999, 0.950179),
                 dark: srgb(0.186926, 0.139343, 0.206284))
    }

    static var mint: Color {
        adaptive(light: srgb(0.748179, 0.910131, 0.811421),
                 dark: srgb(0.077608, 0.222026, 0.146771))
    }

    static var success: Color {
        adaptive(light: srgb(0.111019, 0.356262, 0.206094),
                 dark: srgb(0.418824, 0.724165, 0.515518))
    }

    static var danger: Color {
        adaptive(light: srgb(0.592292, 0.147899, 0.134127),
                 dark: srgb(0.957134, 0.484342, 0.439472))
    }

    static var dangerTint: Color {
        adaptive(light: srgb(1.000000, 0.917901, 0.903966),
                 dark: srgb(0.245000, 0.105000, 0.110000))
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        registerFontsIfNeeded()
        return .custom("Newsreader16pt-Regular", fixedSize: size).weight(weight)
    }

    static func body(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        registerFontsIfNeeded()
        return .custom("Geist-Regular", fixedSize: size).weight(weight)
    }

    private static let fontRegistration: Void = {
        let packagedBundle = Bundle.main.resourceURL
            .map { $0.appendingPathComponent("Wirecopy_WirecopyMac.bundle") }
            .flatMap(Bundle.init(url:))
        let resourceBundle = packagedBundle ?? Bundle.module

        ["Newsreader-Variable", "Geist-Variable"].forEach { name in
            guard let url = resourceBundle.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font: \(name)")
                return
            }

            var error: Unmanaged<CFError>?
            let didRegister = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !didRegister, let error {
                let code = CFErrorGetCode(error.takeRetainedValue())
                guard code != CTFontManagerError.alreadyRegistered.rawValue else { return }
                assertionFailure("Could not register bundled font \(name) (CoreText error \(code))")
            }
        }
    }()

    private static func registerFontsIfNeeded() {
        _ = fontRegistration
    }

    private static func srgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

struct WirecopyRule: View {
    var body: some View {
        Rectangle()
            .fill(WirecopyTheme.rule)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

struct WirecopySectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(WirecopyTheme.body(9, weight: .semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(WirecopyTheme.inkMuted)
    }
}

struct WirecopyKeycap: View {
    let value: String

    var body: some View {
        Text(value)
            .font(WirecopyTheme.body(11, weight: .medium))
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 2)
            .foregroundStyle(WirecopyTheme.ink)
            .background(WirecopyTheme.canvasSoft, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(WirecopyTheme.rule, lineWidth: 0.5)
            }
    }
}

struct WirecopyPanelModifier: ViewModifier {
    let fill: Color

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WirecopyTheme.rule, lineWidth: 0.5)
            }
    }
}

extension View {
    func wirecopyPanel(_ fill: Color = WirecopyTheme.canvasSoft) -> some View {
        modifier(WirecopyPanelModifier(fill: fill))
    }
}
