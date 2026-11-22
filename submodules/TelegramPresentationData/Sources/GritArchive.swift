import Foundation

/// GRIT ARCHIVE: a purely local, on-device copy of messages that disappeared.
/// Telegram cannot recover deleted messages, so this stores only text that was
/// visible to this device before the deletion arrived. Nothing is uploaded.
public enum GritArchive {
    public static let changedNotification = Notification.Name("GRIT.archiveChanged")
    private static let storageKey = "GRIT.deletedMessages"
    private static let limit = 250

    public static func add(peerId: Int64, text: String, outgoing: Bool) {
        guard !text.isEmpty else {
            return
        }
        var entries = self.entries
        entries.insert([
            "peerId": peerId,
            "text": text,
            "outgoing": outgoing,
            "date": Date().timeIntervalSince1970
        ], at: 0)
        if entries.count > self.limit {
            entries = Array(entries.prefix(self.limit))
        }
        UserDefaults.standard.set(entries, forKey: self.storageKey)
        NotificationCenter.default.post(name: self.changedNotification, object: nil)
    }

    public static var entries: [[String: Any]] {
        guard let raw = UserDefaults.standard.array(forKey: self.storageKey) as? [[String: Any]] else {
            return []
        }
        return raw
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: self.storageKey)
        NotificationCenter.default.post(name: self.changedNotification, object: nil)
    }
}
