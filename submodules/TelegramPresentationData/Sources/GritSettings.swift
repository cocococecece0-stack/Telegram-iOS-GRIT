import Foundation

/// GRIT feature switches. Persisted locally in UserDefaults so the toggles work
/// without any account-manager / SyncCore schema changes.
public enum GritFeature: String {
    case crt
    case pulse
    case sound
    case glitch
    case thump
    case secret
    case antiScreenshot
    case neon
    case streak
    case ghost
    case vanish
    case archive
    case profileGlow
    case chatGrid
    case stealth
    case liquidGlass
    case holoProfile
    case giftFx
}

public enum GritSettings {
    public static let changedNotification = Notification.Name("GRIT.settingsChanged")
    public static let codeFxNotification = Notification.Name("GRIT.codeFx")

    private static func key(_ feature: GritFeature) -> String {
        return "GRIT.enable." + feature.rawValue
    }

    public static func isEnabled(_ feature: GritFeature) -> Bool {
        if let value = UserDefaults.standard.object(forKey: key(feature)) as? Bool {
            return value
        }
        // Ghost mode is opt-in: never change delivery behaviour silently.
        if feature == .ghost || feature == .vanish || feature == .archive || feature == .stealth {
            return false
        }
        return true
    }

    public static func setEnabled(_ value: Bool, for feature: GritFeature) {
        UserDefaults.standard.set(value, forKey: key(feature))
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }

    public static func toggle(_ feature: GritFeature) -> Bool {
        let value = !isEnabled(feature)
        setEnabled(value, for: feature)
        return value
    }

    public static var crtEnabled: Bool { isEnabled(.crt) }
    public static var pulseEnabled: Bool { isEnabled(.pulse) }
    public static var soundEnabled: Bool { isEnabled(.sound) }
    public static var glitchEnabled: Bool { isEnabled(.glitch) }
    public static var thumpEnabled: Bool { isEnabled(.thump) }
    public static var secretEnabled: Bool { isEnabled(.secret) }
    public static var antiScreenshotEnabled: Bool { isEnabled(.antiScreenshot) }
    public static var neonEnabled: Bool { isEnabled(.neon) }
    public static var streakEnabled: Bool { isEnabled(.streak) }
    public static var ghostEnabled: Bool { isEnabled(.ghost) }
    public static var vanishEnabled: Bool { isEnabled(.vanish) }
    public static var archiveEnabled: Bool { isEnabled(.archive) }
    public static var profileGlowEnabled: Bool { isEnabled(.profileGlow) }
    public static var chatGridEnabled: Bool { isEnabled(.chatGrid) }
    public static var stealthEnabled: Bool { isEnabled(.stealth) }
    public static var liquidGlassEnabled: Bool { isEnabled(.liquidGlass) }
    public static var holoProfileEnabled: Bool { isEnabled(.holoProfile) }
    public static var giftFxEnabled: Bool { isEnabled(.giftFx) }

    private static let vanishSecondsKey = "GRIT.vanishSeconds"

    /// Self-destruct delay for messages sent while GRIT VANISH is enabled.
    public static var vanishSeconds: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: vanishSecondsKey)
            return value > 0 ? value : 30
        }
        set {
            UserDefaults.standard.set(newValue, forKey: vanishSecondsKey)
            NotificationCenter.default.post(name: changedNotification, object: nil)
        }
    }
}
