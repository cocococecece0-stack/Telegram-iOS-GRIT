import Foundation
import UIKit

/// GRIT v5 — fully local "vault". Gifts, stars and identity live only on this
/// device. Nothing here is sent to Telegram: it is a visual, offline collectible
/// layer on top of the client.
public struct GritGift: Codable, Equatable {
    public var id: String
    public var name: String
    public var rarity: String
    public var tint: UInt32
    public var imageName: String?
    public var stars: Int
    public var createdAt: Double
    
    public init(id: String = UUID().uuidString, name: String, rarity: String, tint: UInt32, imageName: String? = nil, stars: Int, createdAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.tint = tint
        self.imageName = imageName
        self.stars = stars
        self.createdAt = createdAt
    }
    
    public var symbol: String {
        switch self.rarity {
        case "MYTHIC": return "✦"
        case "LEGENDARY": return "✧"
        case "EPIC": return "◆"
        case "RARE": return "◇"
        default: return "•"
        }
    }
}

public struct GritIdentity: Codable, Equatable {
    public var alias: String
    public var title: String
    public var level: Int
    public var xp: Int
    public var nftSeed: UInt32
    
    public init(alias: String = "GRIT USER", title: String = "GHOST TRAINEE", level: Int = 1, xp: Int = 0, nftSeed: UInt32 = 0x9eff00) {
        self.alias = alias
        self.title = title
        self.level = level
        self.xp = xp
        self.nftSeed = nftSeed
    }
}

public enum GritVault {
    public static let changedNotification = Notification.Name("GRIT.vaultChanged")
    public static let giftSentNotification = Notification.Name("GRIT.giftSent")
    
    private static let giftsKey = "GRIT.v5.gifts"
    private static let starsKey = "GRIT.v5.stars"
    private static let identityKey = "GRIT.v5.identity"
    private static let sentKey = "GRIT.v5.sentGifts"
    
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    // MARK: - Gifts
    
    public static var gifts: [GritGift] {
        get {
            guard let data = UserDefaults.standard.data(forKey: giftsKey),
                  let value = try? decoder.decode([GritGift].self, from: data) else {
                return []
            }
            return value
        }
        set {
            if let data = try? encoder.encode(newValue) {
                UserDefaults.standard.set(data, forKey: giftsKey)
            }
            NotificationCenter.default.post(name: changedNotification, object: nil)
        }
    }
    
    public static func addGift(_ gift: GritGift) {
        var current = gifts
        current.insert(gift, at: 0)
        gifts = current
        addXP(40)
    }
    
    public static func removeGift(id: String) {
        gifts = gifts.filter { $0.id != id }
    }
    
    public static func seedIfEmpty() {
        guard gifts.isEmpty else {
            return
        }
        gifts = [
            GritGift(name: "ACID ROSE", rarity: "LEGENDARY", tint: 0x9eff00, stars: 150),
            GritGift(name: "VOID DIAMOND", rarity: "MYTHIC", tint: 0xb388ff, stars: 500),
            GritGift(name: "GHOST CORE", rarity: "EPIC", tint: 0x00e676, stars: 90),
            GritGift(name: "FILTH COIN", rarity: "RARE", tint: 0xffb300, stars: 35)
        ]
    }
    
    // MARK: - Gift images
    
    private static var giftDirectory: URL? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let base = urls.first else {
            return nil
        }
        let directory = base.appendingPathComponent("GRITGifts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }
    
    @discardableResult
    public static func saveImage(_ image: UIImage, name: String) -> String? {
        guard let directory = giftDirectory,
              let data = image.pngData() else {
            return nil
        }
        let fileName = "\(name).png"
        let url = directory.appendingPathComponent(fileName)
        try? data.write(to: url, options: .atomic)
        return fileName
    }
    
    public static func loadImage(named name: String?) -> UIImage? {
        guard let name, let directory = giftDirectory else {
            return nil
        }
        return UIImage(contentsOfFile: directory.appendingPathComponent(name).path)
    }
    
    // MARK: - Stars
    
    public static var stars: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: starsKey)
            return value > 0 ? value : 500
        }
        set {
            UserDefaults.standard.set(newValue, forKey: starsKey)
            NotificationCenter.default.post(name: changedNotification, object: nil)
        }
    }
    
    @discardableResult
    public static func addStars(_ amount: Int) -> Bool {
        guard amount > 0 else {
            return false
        }
        stars += amount
        return true
    }
    
    @discardableResult
    public static func spendStars(_ amount: Int) -> Bool {
        guard amount > 0, stars >= amount else {
            return false
        }
        stars -= amount
        return true
    }
    
    // MARK: - Identity
    
    public static var identity: GritIdentity {
        get {
            guard let data = UserDefaults.standard.data(forKey: identityKey),
                  let value = try? decoder.decode(GritIdentity.self, from: data) else {
                return GritIdentity()
            }
            return value
        }
        set {
            if let data = try? encoder.encode(newValue) {
                UserDefaults.standard.set(data, forKey: identityKey)
            }
            NotificationCenter.default.post(name: changedNotification, object: nil)
        }
    }
    
    public static func addXP(_ amount: Int) {
        var identity = self.identity
        identity.xp += amount
        while identity.xp >= identity.level * 100 {
            identity.xp -= identity.level * 100
            identity.level += 1
            identity.title = identity.level >= 10 ? "GRIT LEGEND" : identity.level >= 5 ? "ACID OPERATOR" : "GHOST TRAINEE"
        }
        self.identity = identity
    }
    
    // MARK: - Sent gifts (for the activity feed)
    
    public static var sentCount: Int {
        get { return UserDefaults.standard.integer(forKey: sentKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: sentKey)
            NotificationCenter.default.post(name: changedNotification, object: nil)
        }
    }
    
    public static func markGiftSent(_ gift: GritGift) {
        sentCount += 1
        addXP(15)
        NotificationCenter.default.post(name: giftSentNotification, object: gift)
    }
}
