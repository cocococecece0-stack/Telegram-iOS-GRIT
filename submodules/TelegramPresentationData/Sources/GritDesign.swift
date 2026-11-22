import Foundation
import SwiftSignalKit
import TelegramUIPreferences
import TelegramCore

/// GRIT OS v6 — a system-wide design language.
///
/// A mode is not just an accent colour: it is a complete palette that every
/// GRIT surface (HUB cards, chat aura, profile holo, code effects and app
/// theme presets) reads from. Everything is local and synchronous — no account
/// or SyncCore changes are involved.
public enum GritDesignMode: String, CaseIterable {
    case void
    case acid
    case holo
    case crt

    public var name: String {
        switch self {
            case .void: return "VOID"
            case .acid: return "ACID"
            case .holo: return "HOLO"
            case .crt: return "CRT"
        }
    }

    public var tagline: String {
        switch self {
            case .void: return "BLACK / ACID / SILENCE"
            case .acid: return "TOXIC / LOUD / ALIVE"
            case .holo: return "IRIDESCENT / GLASS / SOFT"
            case .crt: return "PHOSPHOR / TERMINAL / 1984"
        }
    }

    public var symbol: String {
        switch self {
            case .void: return "◈"
            case .acid: return "✦"
            case .holo: return "◇"
            case .crt: return "▣"
        }
    }

    /// Primary accent, as an RGB hex value.
    public var accent: UInt32 {
        switch self {
            case .void: return 0x9eff00
            case .acid: return 0xb6ff00
            case .holo: return 0xb388ff
            case .crt: return 0x39ff6a
        }
    }

    /// Secondary accent used for gradients and glows.
    public var accentAlt: UInt32 {
        switch self {
            case .void: return 0x00e676
            case .acid: return 0xff2fb9
            case .holo: return 0x5ce1ff
            case .crt: return 0x00ffc8
        }
    }

    public var background: UInt32 {
        switch self {
            case .void: return 0x000000
            case .acid: return 0x050608
            case .holo: return 0x0b0a14
            case .crt: return 0x020a04
        }
    }

    public var surface: UInt32 {
        switch self {
            case .void: return 0x0a0d0a
            case .acid: return 0x11131a
            case .holo: return 0x171426
            case .crt: return 0x06170c
        }
    }

    public var border: UInt32 {
        switch self {
            case .void: return 0x1e2b16
            case .acid: return 0x2a3138
            case .holo: return 0x2b2742
            case .crt: return 0x123a1e
        }
    }

    public var textSecondary: UInt32 {
        switch self {
            case .void: return 0x8fa386
            case .acid: return 0x9aa2ad
            case .holo: return 0xa9a2c4
            case .crt: return 0x6fbf87
        }
    }

    /// Whether the mode should render CRT scanlines and mono-spaced labels.
    public var isTerminal: Bool {
        return self == .crt
    }

    /// Bundled alternate app icon for this design language.
    public var iconName: String {
        switch self {
            case .void: return "GRITVOID"
            case .acid: return "GRIT"
            case .holo: return "GRITHOLO"
            case .crt: return "GRITCRT"
        }
    }

    /// Stable accent-preset index used when writing the global Telegram theme.
    public var presetIndex: Int32 {
        switch self {
            case .void: return 111
            case .acid: return 112
            case .holo: return 113
            case .crt: return 114
        }
    }

    /// Gradient stops for outgoing message bubbles.
    public var bubbleColors: [UInt32] {
        switch self {
            case .void: return [0x1b5e20, 0x00e676, 0x9eff00]
            case .acid: return [0x2b0b2e, 0xff2fb9, 0xb6ff00]
            case .holo: return [0x120a1f, 0x6a00ff, 0xb388ff]
            case .crt: return [0x022c12, 0x00c853, 0x39ff6a]
        }
    }
}

public enum GritDesign {
    public static let changedNotification = Notification.Name("GRIT.designChanged")

    private static let modeKey = "GRIT.v6.designMode"

    public static var mode: GritDesignMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: modeKey),
                  let value = GritDesignMode(rawValue: raw) else {
                return .void
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: modeKey)
            NotificationCenter.default.post(name: changedNotification, object: newValue)
            NotificationCenter.default.post(name: GritSettings.changedNotification, object: nil)
        }
    }

    /// Convenience for views that only need the primary colour.
    public static var accent: UInt32 {
        return mode.accent
    }

    public static var accentAlt: UInt32 {
        return mode.accentAlt
    }

    /// Install mode-specific accent + bubble colours into the real global
    /// Telegram theme settings. This is the piece that makes GRIT OS affect
    /// the whole app instead of only the mod's own screens.
    public static func applyGlobalTheme(_ mode: GritDesignMode, accountManager: AccountManager<TelegramAccountManagerTypes>) {
        self.mode = mode
        let reference: PresentationThemeReference = .builtin(.night)
        let themeIndex = reference.index
        let preset = PresentationThemeAccentColor(
            index: mode.presetIndex,
            baseColor: .preset,
            accentColor: mode.accent,
            bubbleColors: mode.bubbleColors
        )
        let _ = updatePresentationThemeSettingsInteractively(accountManager: accountManager, { current in
            var themeSpecificAccentColors = current.themeSpecificAccentColors
            themeSpecificAccentColors[themeIndex] = preset
            return current
                .withUpdatedTheme(reference)
                .withUpdatedThemeSpecificAccentColors(themeSpecificAccentColors)
        }).start()
    }
}
