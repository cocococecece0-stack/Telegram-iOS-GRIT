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
}

public enum GritSettings {
    public static let changedNotification = Notification.Name("GRIT.settingsChanged")

    private static func key(_ feature: GritFeature) -> String {
        return "GRIT.enable." + feature.rawValue
    }

    public static func isEnabled(_ feature: GritFeature) -> Bool {
        if let value = UserDefaults.standard.object(forKey: key(feature)) as? Bool {
            return value
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
}
