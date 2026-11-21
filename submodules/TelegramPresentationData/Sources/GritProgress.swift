import Foundation

// GRIT progression: purely local, no account-manager or SyncCore schema changes.
// Shared by the auth splash (streak badge) and the chat composer (secret code).
public enum GritProgress {
    private static let streakKey = "GRIT.streak"
    private static let lastOpenKey = "GRIT.lastOpen"
    private static let codeKey = "GRIT.codeUses"

    public static func registerOpen() -> (streak: Int, codes: Int) {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        var streak = UserDefaults.standard.integer(forKey: streakKey)

        if let last = UserDefaults.standard.object(forKey: lastOpenKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: last)
            let days = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if days == 1 {
                streak += 1
            } else if days > 1 || days < 0 {
                streak = 1
            }
        } else {
            streak = 1
        }

        if streak < 1 {
            streak = 1
        }
        UserDefaults.standard.set(now, forKey: lastOpenKey)
        UserDefaults.standard.set(streak, forKey: streakKey)
        return (streak, UserDefaults.standard.integer(forKey: codeKey))
    }

    public static func noteCode() -> Int {
        let count = UserDefaults.standard.integer(forKey: codeKey) + 1
        UserDefaults.standard.set(count, forKey: codeKey)
        return count
    }
}
