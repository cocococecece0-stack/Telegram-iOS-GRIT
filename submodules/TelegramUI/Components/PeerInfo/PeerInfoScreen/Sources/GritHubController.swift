import Foundation
import UIKit
import Display
import AccountContext
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData

// MARK: - Small closure-backed controls

private final class GritSwitch: UISwitch {
    var onChange: ((Bool) -> Void)?
    
    init(value: Bool) {
        super.init(frame: .zero)
        self.isOn = value
        self.onTintColor = UIColor(rgb: 0x9eff00)
        self.thumbTintColor = .white
        self.addTarget(self, action: #selector(changed), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func changed() {
        self.onChange?(self.isOn)
    }
}

private final class GritButton: UIButton {
    var onTap: (() -> Void)?
    
    init(title: String, tint: UIColor) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        self.setTitleColor(tint, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
        self.contentHorizontalAlignment = .left
        self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapped() {
        self.onTap?()
    }
}

/// GRIT v5 — the one place for every GRIT feature. Fully local, no server calls.
final class GritHubController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let context: AccountContext
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let mainStack = UIStackView()
    
    init(context: AccountContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "GRIT HUB"
        self.view.backgroundColor = UIColor(rgb: 0x070b07)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true
        self.view.addSubview(self.scrollView)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.contentView)
        
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.contentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.contentView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor)
        ])
        
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.headerView.clipsToBounds = true
        self.contentView.addSubview(self.headerView)
        
        self.mainStack.translatesAutoresizingMaskIntoConstraints = false
        self.mainStack.axis = .vertical
        self.mainStack.spacing = 16.0
        self.contentView.addSubview(self.mainStack)
        
        NSLayoutConstraint.activate([
            self.headerView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.headerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.headerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.headerView.heightAnchor.constraint(equalToConstant: 230.0),
            
            self.mainStack.topAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: 16.0),
            self.mainStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16.0),
            self.mainStack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16.0),
            self.mainStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -32.0)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataChanged), name: GritVault.changedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataChanged), name: GritSettings.changedNotification, object: nil)
        
        self.buildHeader()
        self.rebuild()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func done() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func dataChanged() {
        self.rebuild()
    }
    
    // MARK: - Header
    
    private func buildHeader() {
        self.headerView.layer.sublayers?.removeAll()
        
        let gradient = SimpleGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: max(UIScreen.main.bounds.width, 1.0), height: 230.0)
        gradient.colors = [
            UIColor(rgb: 0x9eff00, alpha: 0.9).cgColor,
            UIColor(rgb: 0x00e676, alpha: 0.5).cgColor,
            UIColor(rgb: 0xb388ff, alpha: 0.65).cgColor,
            UIColor(rgb: 0x070b07).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        let animation = CABasicAnimation(keyPath: "colors")
        animation.toValue = [
            UIColor(rgb: 0xb388ff, alpha: 0.8).cgColor,
            UIColor(rgb: 0x9eff00, alpha: 0.75).cgColor,
            UIColor(rgb: 0x00e676, alpha: 0.55).cgColor,
            UIColor(rgb: 0x070b07).cgColor
        ]
        animation.duration = 6.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "gritHubHeader")
        self.headerView.layer.insertSublayer(gradient, at: 0)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "ENTER THE GRIT"
        title.font = UIFont.systemFont(ofSize: 34.0, weight: .black)
        title.textColor = .black
        self.headerView.addSubview(title)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.text = "GRIT HUB  //  v5  //  OFFLINE VISUAL SYSTEM"
        subtitle.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        subtitle.textColor = UIColor.black.withAlphaComponent(0.75)
        self.headerView.addSubview(subtitle)
        
        let stats = UILabel()
        stats.translatesAutoresizingMaskIntoConstraints = false
        stats.text = self.headerStatsText()
        stats.font = UIFont.systemFont(ofSize: 14.0, weight: .black)
        stats.textColor = .black
        self.headerView.addSubview(stats)
        
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 20.0),
            title.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: -56.0),
            subtitle.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 20.0),
            subtitle.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: -32.0),
            stats.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 20.0),
            stats.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: -10.0)
        ])
    }
    
    private func headerStatsText() -> String {
        let identity = GritVault.identity
        let progress = GritProgress.registerOpen()
        return "LVL \(identity.level) · \(identity.title) · 🔥 \(progress.streak)D · ★ \(GritVault.stars)"
    }
    
    // MARK: - Content
    
    private func rebuild() {
        for view in self.mainStack.arrangedSubviews {
            self.mainStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        self.mainStack.addArrangedSubview(self.makeIdentityCard())
        self.mainStack.addArrangedSubview(self.makeInvisibleCard())
        self.mainStack.addArrangedSubview(self.makeVisualsCard())
        self.mainStack.addArrangedSubview(self.makeGiftStudioCard())
        self.mainStack.addArrangedSubview(self.makePrivacyCard())
        self.mainStack.addArrangedSubview(self.makeCodesCard())
        
        if let stats = self.headerView.subviews.compactMap({ $0 as? UILabel }).last {
            stats.text = self.headerStatsText()
        }
    }
    
    private func makeCard(title: String, subtitle: String? = nil, tint: UIColor) -> (UIView, UIStackView) {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 20.0
        card.clipsToBounds = true
        card.layer.borderWidth = 1.0
        card.layer.borderColor = tint.withAlphaComponent(0.35).cgColor
        
        let effect: UIVisualEffectView
        if #available(iOS 26.0, *), GritSettings.liquidGlassEnabled {
            effect = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            effect = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        }
        effect.translatesAutoresizingMaskIntoConstraints = false
        card.insertSubview(effect, at: 0)
        NSLayoutConstraint.activate([
            effect.topAnchor.constraint(equalTo: card.topAnchor),
            effect.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            effect.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10.0
        card.addSubview(stack)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .black)
        titleLabel.textColor = tint
        stack.addArrangedSubview(titleLabel)
        
        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel.text = subtitle
            subtitleLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .medium)
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.55)
            subtitleLabel.numberOfLines = 0
            stack.addArrangedSubview(subtitleLabel)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16.0),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16.0)
        ])
        
        return (card, stack)
    }
    
    private func makeToggleRow(title: String, subtitle: String, feature: GritFeature) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let labels = UIStackView()
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.axis = .vertical
        labels.spacing = 2.0
        row.addSubview(labels)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        titleLabel.textColor = .white
        labels.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        subtitleLabel.numberOfLines = 0
        labels.addArrangedSubview(subtitleLabel)
        
        let toggle = GritSwitch(value: GritSettings.isEnabled(feature))
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onChange = { value in
            GritSettings.setEnabled(value, for: feature)
        }
        row.addSubview(toggle)
        
        NSLayoutConstraint.activate([
            labels.topAnchor.constraint(equalTo: row.topAnchor),
            labels.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            labels.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            toggle.leadingAnchor.constraint(equalTo: labels.trailingAnchor, constant: 12.0),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        
        return row
    }
    
    private func makeActionRow(title: String, subtitle: String? = nil, tint: UIColor, action: @escaping () -> Void) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let button = GritButton(title: title, tint: tint)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.onTap = action
        row.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: row.topAnchor),
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: row.trailingAnchor)
        ])
        
        if let subtitle {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = subtitle
            label.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
            label.textColor = UIColor.white.withAlphaComponent(0.5)
            label.numberOfLines = 0
            row.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 2.0),
                label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                label.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                button.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
        }
        
        return row
    }
    
    // MARK: - Cards
    
    private func makeIdentityCard() -> UIView {
        let identity = GritVault.identity
        let (card, stack) = makeCard(title: "GRIT IDENTITY", subtitle: "Local NFT-style profile. Never leaves this device.", tint: UIColor(rgb: 0xb388ff))
        
        let aliasRow = makeActionRow(title: "✦  \(identity.alias)", subtitle: "\(identity.title) · LEVEL \(identity.level) · XP \(identity.xp)", tint: .white) { [weak self] in
            self?.editAlias()
        }
        stack.addArrangedSubview(aliasRow)
        
        let nft = UIView()
        nft.translatesAutoresizingMaskIntoConstraints = false
        nft.layer.cornerRadius = 14.0
        nft.clipsToBounds = true
        let nftGradient = SimpleGradientLayer()
        nftGradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width - 64.0, height: 84.0)
        nftGradient.colors = [
            UIColor(rgb: 0x9eff00, alpha: 0.8).cgColor,
            UIColor(rgb: 0x00e676, alpha: 0.55).cgColor,
            UIColor(rgb: 0xb388ff, alpha: 0.85).cgColor
        ]
        nftGradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        nftGradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        nft.layer.insertSublayer(nftGradient, at: 0)
        let nftLabel = UILabel()
        nftLabel.translatesAutoresizingMaskIntoConstraints = false
        nftLabel.text = "GRIT PASS #\(String(format: "%08X", identity.nftSeed))"
        nftLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .black)
        nftLabel.textColor = .black
        nft.addSubview(nftLabel)
        NSLayoutConstraint.activate([
            nft.heightAnchor.constraint(equalToConstant: 84.0),
            nftLabel.leadingAnchor.constraint(equalTo: nft.leadingAnchor, constant: 14.0),
            nftLabel.centerYAnchor.constraint(equalTo: nft.centerYAnchor)
        ])
        stack.addArrangedSubview(nft)
        
        return card
    }
    
    private func makeInvisibleCard() -> UIView {
        let (card, stack) = makeCard(title: "REŽIM PRITZRAK", subtitle: "Looks offline while you stay in the app. Suppresses outgoing presence pings and read receipts locally.", tint: UIColor(rgb: 0x00e676))
        stack.addArrangedSubview(makeToggleRow(title: "GRIT GHOST MODE", subtitle: "No typing, no sticker/voice activity, no local read-receipt pushes.", feature: .ghost))
        stack.addArrangedSubview(makeToggleRow(title: "GRIT STEALTH", subtitle: "Extra client-side presence suppression. For real server-side invisibility also set Telegram → Settings → Privacy → Last Seen → Nobody.", feature: .stealth))
        stack.addArrangedSubview(makeToggleRow(title: "GRIT SHIELD", subtitle: "Warns on screenshots and masks the app while screen recording.", feature: .antiScreenshot))
        stack.addArrangedSubview(makeActionRow(title: "☠  GO FULLY OFFLINE (SERVER-SIDE)", subtitle: "Sets Telegram's Last Seen → Nobody on your account. This is a real account privacy change.", tint: UIColor(rgb: 0xff5c8a)) { [weak self] in
            guard let self else {
                return
            }
            let _ = self.context.engine.privacy.updateSelectiveAccountPrivacySettings(
                type: .presence,
                settings: .disableEveryone(enableFor: [:], enableForCloseFriends: false, enableForPremium: false, enableForBots: false)
            ).start()
            GritSettings.setEnabled(true, for: .stealth)
        })
        return card
    }
    
    private func makeVisualsCard() -> UIView {
        let (card, stack) = makeCard(title: "VISUAL OVERHAUL", subtitle: "All changes are local and instant.", tint: UIColor(rgb: 0x9eff00))
        stack.addArrangedSubview(makeToggleRow(title: "LIQUID GLASS", subtitle: "Native iOS 26/27 glass on HUB cards, with a dark blur fallback.", feature: .liquidGlass))
        stack.addArrangedSubview(makeToggleRow(title: "HOLO PROFILE", subtitle: "Animated holographic banner, avatar ring and ID badges on profiles.", feature: .holoProfile))
        stack.addArrangedSubview(makeToggleRow(title: "GIFT FX", subtitle: "Full-screen star-rain celebrations when you send virtual gifts.", feature: .giftFx))
        stack.addArrangedSubview(makeToggleRow(title: "PROFILE GLOW", subtitle: "Acid halo around avatars.", feature: .profileGlow))
        stack.addArrangedSubview(makeToggleRow(title: "CHAT GRID", subtitle: "CRT grid layer in chats.", feature: .chatGrid))
        stack.addArrangedSubview(makeToggleRow(title: "CRT / PULSE / GLITCH", subtitle: "The classic GRIT atmosphere.", feature: .crt))
        return card
    }
    
    private func makeGiftStudioCard() -> UIView {
        let (card, stack) = makeCard(title: "GIFT STUDIO", subtitle: "Create and 'send' visual gifts. These are local collectibles — no real stars are spent or transferred.", tint: UIColor(rgb: 0xffd54f))
        
        stack.addArrangedSubview(makeActionRow(title: "+  CREATE VIRTUAL GIFT", subtitle: "Pick a photo, name it, give it rarity and a star value.", tint: UIColor(rgb: 0x9eff00)) { [weak self] in
            self?.createGift()
        })
        
        for gift in GritVault.gifts {
            let giftRow = UIButton()
            giftRow.translatesAutoresizingMaskIntoConstraints = false
            giftRow.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            giftRow.layer.cornerRadius = 14.0
            giftRow.layer.borderWidth = 1.0
            giftRow.layer.borderColor = UIColor(rgb: gift.tint, alpha: 0.55).cgColor
            giftRow.heightAnchor.constraint(equalToConstant: 68.0).isActive = true
            
            if let image = GritVault.loadImage(named: gift.imageName) {
                let imageView = UIImageView(image: image)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 10.0
                giftRow.insertSubview(imageView, at: 0)
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: giftRow.leadingAnchor, constant: 6.0),
                    imageView.topAnchor.constraint(equalTo: giftRow.topAnchor, constant: 6.0),
                    imageView.bottomAnchor.constraint(equalTo: giftRow.bottomAnchor, constant: -6.0),
                    imageView.widthAnchor.constraint(equalToConstant: 56.0)
                ])
            }
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "\(gift.symbol) \(gift.name)  ·  \(gift.rarity)  ·  ★ \(gift.stars)"
            label.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
            label.textColor = UIColor(rgb: gift.tint)
            giftRow.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: giftRow.leadingAnchor, constant: 72.0),
                label.trailingAnchor.constraint(equalTo: giftRow.trailingAnchor, constant: -12.0),
                label.centerYAnchor.constraint(equalTo: giftRow.centerYAnchor)
            ])
            
            let identifier = gift.id
            giftRow.tag = identifier.hash
            giftRow.addTarget(self, action: #selector(sendGift(_:)), for: .touchUpInside)
            stack.addArrangedSubview(giftRow)
        }
        
        stack.addArrangedSubview(makeActionRow(title: "★  STAR RAIN  ·  +50 VISUAL STARS", subtitle: "Balance: \(GritVault.stars)", tint: UIColor(rgb: 0xffd54f)) { [weak self] in
            GritVault.addStars(50)
            NotificationCenter.default.post(name: GritSettings.codeFxNotification, object: "STAR")
            self?.rebuild()
        })
        
        return card
    }
    
    private func makePrivacyCard() -> UIView {
        let (card, stack) = makeCard(title: "PRIVACY / TIME", subtitle: "Client-side behaviour. Nothing here changes your Telegram account settings.", tint: UIColor(rgb: 0xff5c8a))
        stack.addArrangedSubview(makeToggleRow(title: "GRIT VANISH", subtitle: "Sent messages revoke themselves after a delay.", feature: .vanish))
        stack.addArrangedSubview(makeToggleRow(title: "GRIT ARCHIVE", subtitle: "Keeps a local copy of deleted message text.", feature: .archive))
        stack.addArrangedSubview(makeActionRow(title: "VANISH TIMER · \(GritSettings.vanishSeconds)s", tint: UIColor(rgb: 0xff5c8a)) {
            let steps = [10, 30, 60, 120]
            let current = GritSettings.vanishSeconds
            GritSettings.vanishSeconds = steps.first(where: { $0 > current }) ?? steps[0]
        })
        stack.addArrangedSubview(makeActionRow(title: "VIEW GRIT ARCHIVE · \(GritArchive.entries.count) saved", tint: UIColor(rgb: 0xff5c8a)) {
            NotificationCenter.default.post(name: GritSettings.codeFxNotification, object: "ARCHIVE")
        })
        return card
    }
    
    private func makeCodesCard() -> UIView {
        let (card, stack) = makeCard(title: "SECRET CODES", subtitle: "Type these in any chat input. Visuals only.", tint: UIColor(rgb: 0x00e5ff))
        let codes = ["GRIT", "ACID", "VOID", "FILTH", "PULSE", "STAR"]
        for code in codes {
            stack.addArrangedSubview(makeActionRow(title: "> \(code)", tint: UIColor(rgb: 0x00e5ff)) {
                NotificationCenter.default.post(name: GritSettings.codeFxNotification, object: code)
            })
        }
        return card
    }
    
    // MARK: - Actions
    
    @objc private func sendGift(_ sender: UIButton) {
        guard let gift = GritVault.gifts.first(where: { $0.id.hash == sender.tag }) else {
            return
        }
        GritVault.markGiftSent(gift)
        NotificationCenter.default.post(name: GritSettings.codeFxNotification, object: "GIFT:\(gift.id)")
        self.rebuild()
    }
    
    private func editAlias() {
        let alert = UIAlertController(title: "GRIT IDENTITY", message: "Choose your local alias", preferredStyle: .alert)
        alert.addTextField { field in
            field.text = GritVault.identity.alias
            field.textColor = .white
        }
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "SAVE", style: .default) { [weak self] _ in
            let alias = alert.textFields?.first?.text ?? ""
            var identity = GritVault.identity
            identity.alias = alias.isEmpty ? "GRIT USER" : alias.uppercased()
            GritVault.identity = identity
            self?.rebuild()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func createGift() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true) { [weak self] in
            guard let image else {
                return
            }
            self?.nameGift(image: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func nameGift(image: UIImage) {
        let alert = UIAlertController(title: "NEW GRIT GIFT", message: "Visuals only — nothing is uploaded", preferredStyle: .alert)
        alert.addTextField { field in
            field.text = "VOID RELIC"
            field.textColor = .white
        }
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "CREATE", style: .default) { [weak self] _ in
            let name = (alert.textFields?.first?.text ?? "").uppercased()
            let rarities = ["RARE", "EPIC", "LEGENDARY", "MYTHIC"]
            let tints: [UInt32] = [0x9eff00, 0xb388ff, 0x00e676, 0xffb300]
            let rarity = rarities.randomElement() ?? "RARE"
            let tint = tints.randomElement() ?? 0x9eff00
            let stars = (30...500).randomElement() ?? 30
            let fileName = GritVault.saveImage(image, name: "gift_\(Int(Date().timeIntervalSince1970))")
            let gift = GritGift(name: name.isEmpty ? "GRIT RELIC" : name, rarity: rarity, tint: tint, imageName: fileName, stars: stars)
            GritVault.addGift(gift)
            GritVault.markGiftSent(gift)
            NotificationCenter.default.post(name: GritSettings.codeFxNotification, object: "GIFT:\(gift.id)")
            self?.rebuild()
        })
        self.present(alert, animated: true, completion: nil)
    }
}
