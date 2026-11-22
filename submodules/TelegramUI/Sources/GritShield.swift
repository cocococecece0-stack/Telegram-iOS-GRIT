import Foundation
import UIKit
import SwiftSignalKit
import Display
import ScreenCaptureDetection
import TelegramPresentationData

private func gritStarParticle() -> UIImage {
    let size = CGSize(width: 14.0, height: 14.0)
    return UIGraphicsImageRenderer(size: size).image { context in
        UIColor(rgb: 0x9eff00).setFill()
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        for i in 0 ..< 10 {
            let angle = CGFloat(i) * .pi / 5.0 - .pi / 2.0
            let radius: CGFloat = i % 2 == 0 ? 6.5 : 2.8
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        path.fill()
    }
}

/// GRIT SHIELD: local privacy layer.
/// - On a screenshot: flashes an acid warning over the whole app.
/// - On screen recording: masks the window with an opaque GRIT panel while recording is active.
public final class GritShield {
    private weak var window: UIWindow?
    private var disposable: Disposable?
    private var screenshotOverlay: UIView?
    private var recordingOverlay: UIView?
    private var codeOverlay: UIView?
    private var fxObserver: NSObjectProtocol?
    private var hideTimer: SwiftSignalKit.Timer?
    private var recordingCheckTimer: SwiftSignalKit.Timer?

    public init(window: UIWindow) {
        self.window = window
    }

    public func start() {
        guard self.disposable == nil else {
            return
        }
        self.disposable = (screenCaptureEvents() |> deliverOnMainQueue).start(next: { [weak self] event in
            guard let self else {
                return
            }
            switch event {
            case .still:
                if GritSettings.antiScreenshotEnabled {
                    self.flashScreenshotWarning()
                }
            case .video:
                if GritSettings.antiScreenshotEnabled {
                    self.updateRecordingOverlay()
                }
            }
        })

        self.recordingCheckTimer = SwiftSignalKit.Timer(timeout: 0.5, repeat: true, completion: { [weak self] in
            Queue.mainQueue().async {
                self?.updateRecordingOverlay()
            }
        }, queue: Queue.mainQueue())
        self.recordingCheckTimer?.start()

        self.fxObserver = NotificationCenter.default.addObserver(forName: GritSettings.codeFxNotification, object: nil, queue: .main) { [weak self] note in
            guard let code = note.object as? String else {
                return
            }
            self?.flashCode(code)
        }
    }

    /// GRIT v5: a full-screen, local-only gift / star celebration.
    private func showCelebration(title: String, subtitle: String, tint: UInt32, image: UIImage?, stars: Int?) {
        guard let window, GritSettings.giftFxEnabled else {
            return
        }
        self.codeOverlay?.removeFromSuperview()
        
        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.layer.zPosition = 10005
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.86)
        
        let cardWidth = min(window.bounds.width - 64.0, 320.0)
        let cardHeight: CGFloat = image == nil ? 360.0 : 420.0
        let card = UIView(frame: CGRect(x: (window.bounds.width - cardWidth) / 2.0, y: (window.bounds.height - cardHeight) / 2.0, width: cardWidth, height: cardHeight))
        card.layer.cornerRadius = 28.0
        card.clipsToBounds = true
        card.layer.borderWidth = 1.0
        card.layer.borderColor = UIColor(rgb: tint, alpha: 0.8).cgColor
        
        let gradient = SimpleGradientLayer()
        gradient.frame = card.bounds
        gradient.colors = [
            UIColor(rgb: tint, alpha: 0.55).cgColor,
            UIColor.black.cgColor,
            UIColor(rgb: 0x101810).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        card.layer.insertSublayer(gradient, at: 0)
        
        var y: CGFloat = 20.0
        if let image {
            let imageView = UIImageView(frame: CGRect(x: 16.0, y: y, width: cardWidth - 32.0, height: 230.0))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 20.0
            imageView.image = image
            card.addSubview(imageView)
            y += 246.0
        } else {
            let symbol = UILabel(frame: CGRect(x: 0.0, y: 40.0, width: cardWidth, height: 150.0))
            symbol.text = "✦"
            symbol.textAlignment = .center
            symbol.textColor = UIColor(rgb: tint)
            symbol.font = UIFont.systemFont(ofSize: 110.0, weight: .black)
            card.addSubview(symbol)
            y += 176.0
        }
        
        let titleLabel = UILabel(frame: CGRect(x: 20.0, y: y, width: cardWidth - 40.0, height: 34.0))
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .black)
        card.addSubview(titleLabel)
        y += 42.0
        
        let subtitleLabel = UILabel(frame: CGRect(x: 20.0, y: y, width: cardWidth - 40.0, height: 22.0))
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor(rgb: tint)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
        card.addSubview(subtitleLabel)
        y += 30.0
        
        if let stars {
            let starsLabel = UILabel(frame: CGRect(x: 20.0, y: y, width: cardWidth - 40.0, height: 26.0))
            starsLabel.text = "★ \(stars)  ·  BALANCE \(GritVault.stars)"
            starsLabel.textAlignment = .center
            starsLabel.textColor = UIColor(rgb: 0xffd54f)
            starsLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            card.addSubview(starsLabel)
        }
        
        overlay.addSubview(card)
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: window.bounds.width / 2.0, y: -20.0)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: window.bounds.width, height: 1.0)
        let particle = CAEmitterCell()
        particle.birthRate = 26.0
        particle.lifetime = 5.0
        particle.velocity = 90.0
        particle.velocityRange = 60.0
        particle.emissionRange = .pi / 8.0
        particle.yAcceleration = 22.0
        particle.scale = 0.5
        particle.scaleRange = 0.4
        particle.alphaSpeed = -0.2
        particle.contents = gritStarParticle().cgImage
        emitter.emitterCells = [particle]
        overlay.layer.addSublayer(emitter)
        
        window.addSubview(overlay)
        self.codeOverlay = overlay
        
        card.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        card.alpha = 0.0
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, animations: {
            card.transform = .identity
            card.alpha = 1.0
        })
        UIView.animate(withDuration: 0.4, delay: 3.0, animations: {
            overlay.alpha = 0.0
        }, completion: { _ in
            overlay.removeFromSuperview()
            if self.codeOverlay === overlay {
                self.codeOverlay = nil
            }
        })
    }
    
    /// GRIT secret codes: `acid`, `void`, `filth`, `pulse`, `grit`.
    public func flashCode(_ code: String) {
        guard let window = self.window, self.codeOverlay == nil else {
            return
        }
        if code == "STAR" {
            self.showCelebration(title: "GRIT STARS", subtitle: "VISUAL REWARD // LOCAL ONLY", tint: 0xffd54f, image: nil, stars: nil)
            return
        }
        if code == "GIFT" {
            if let gift = GritVault.gifts.randomElement() {
                GritVault.markGiftSent(gift)
                self.showCelebration(title: gift.name, subtitle: "\(gift.symbol) \(gift.rarity) // VISUAL GIFT", tint: gift.tint, image: GritVault.loadImage(named: gift.imageName), stars: gift.stars)
                return
            }
        }
        if code.hasPrefix("GIFT:") {
            let identifier = String(code.dropFirst("GIFT:".count))
            if let gift = GritVault.gifts.first(where: { $0.id == identifier }) {
                self.showCelebration(title: gift.name, subtitle: "\(gift.symbol) \(gift.rarity) // VISUAL GIFT", tint: gift.tint, image: GritVault.loadImage(named: gift.imageName), stars: gift.stars)
                return
            }
        }
        guard GritSettings.secretEnabled else {
            return
        }
        
        let color: UIColor
        let title: String
        switch code {
        case "ACID":
            color = UIColor(rgb: 0x9eff00)
            title = "ACID // OVERDOSE"
        case "VOID":
            color = UIColor(rgb: 0xb388ff)
            title = "VOID // NOTHING HERE"
        case "FILTH":
            color = UIColor(rgb: 0x2f6b28)
            title = "FILTH // WELCOME TO THE GUTTER"
        case "PULSE":
            color = UIColor(rgb: 0x00e676)
            title = "PULSE // HEARTBEAT"
        case "ARCHIVE":
            color = UIColor(rgb: 0xb388ff)
            let entries = GritArchive.entries
            if entries.isEmpty {
                title = "GRIT ARCHIVE // EMPTY"
            } else {
                let lines = entries.prefix(6).map { entry -> String in
                    let text = (entry["text"] as? String) ?? ""
                    let outgoing = (entry["outgoing"] as? Bool) ?? false
                    return (outgoing ? "› " : "‹ ") + text.replacingOccurrences(of: "\n", with: " ")
                }
                title = "GRIT ARCHIVE // \(entries.count) SAVED\n" + lines.joined(separator: "\n")
            }
        default:
            color = UIColor(rgb: 0x9eff00)
            title = "ENTER THE GRIT"
        }

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = false
        overlay.layer.zPosition = 10002
        overlay.alpha = 0.0

        let wash = UIView(frame: overlay.bounds)
        wash.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wash.backgroundColor = color.withAlphaComponent(0.22)
        overlay.addSubview(wash)

        let label = UILabel(frame: overlay.bounds.insetBy(dx: 24.0, dy: 24.0))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let isArchive = code == "ARCHIVE"
        label.text = title
        label.textColor = color
        label.font = UIFont.systemFont(ofSize: isArchive ? 15.0 : 28.0, weight: isArchive ? .semibold : .black)
        label.textAlignment = isArchive ? .left : .center
        label.numberOfLines = isArchive ? 0 : 2
        overlay.addSubview(label)

        window.addSubview(overlay)
        self.codeOverlay = overlay
        UIView.animate(withDuration: 0.1, animations: {
            overlay.alpha = 1.0
        }, completion: { [weak self] _ in
            self?.hideTimer?.invalidate()
            let timer = SwiftSignalKit.Timer(timeout: code == "ARCHIVE" ? 5.0 : 1.1, repeat: false, completion: { [weak self] in
                Queue.mainQueue().async {
                    guard let self else {
                        return
                    }
                    UIView.animate(withDuration: 0.25, animations: {
                        overlay.alpha = 0.0
                    }, completion: { _ in
                        overlay.removeFromSuperview()
                        if self.codeOverlay === overlay {
                            self.codeOverlay = nil
                        }
                    })
                }
            }, queue: Queue.mainQueue())
            self?.hideTimer = timer
            timer.start()
        })
    }

    private func updateRecordingOverlay() {
        guard let window = self.window else {
            return
        }
        let recording = UIScreen.main.isCaptured && GritSettings.antiScreenshotEnabled
        if recording {
            if self.recordingOverlay == nil {
                let overlay = UIView(frame: window.bounds)
                overlay.backgroundColor = UIColor.black
                overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlay.isUserInteractionEnabled = false
                overlay.layer.zPosition = 10000

                let grid = UIView(frame: overlay.bounds)
                grid.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                grid.backgroundColor = UIColor(patternImage: gritShieldPattern())
                grid.alpha = 0.35
                overlay.addSubview(grid)

                let label = UILabel(frame: overlay.bounds.insetBy(dx: 24.0, dy: 24.0))
                label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                label.text = "GRIT // SHIELD\nRECORDING BLOCKED"
                label.textColor = UIColor(red: 0.62, green: 1.0, blue: 0.0, alpha: 1.0)
                label.font = UIFont.systemFont(ofSize: 26.0, weight: .bold)
                label.numberOfLines = 2
                label.textAlignment = .center
                overlay.addSubview(label)

                window.addSubview(overlay)
                self.recordingOverlay = overlay
            }
        } else if let overlay = self.recordingOverlay {
            overlay.removeFromSuperview()
            self.recordingOverlay = nil
        }
    }

    private func flashScreenshotWarning() {
        guard let window = self.window, self.screenshotOverlay == nil else {
            return
        }
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.94)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = false
        overlay.layer.zPosition = 10001
        overlay.alpha = 0.0

        let label = UILabel(frame: overlay.bounds.insetBy(dx: 24.0, dy: 24.0))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.text = "GRIT // SHIELD\nSCREENSHOT DETECTED"
        label.textColor = UIColor(red: 0.62, green: 1.0, blue: 0.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        label.numberOfLines = 2
        label.textAlignment = .center
        overlay.addSubview(label)

        window.addSubview(overlay)
        self.screenshotOverlay = overlay
        UIView.animate(withDuration: 0.12, animations: {
            overlay.alpha = 1.0
        }, completion: { [weak self] _ in
            self?.hideTimer?.invalidate()
            let timer = SwiftSignalKit.Timer(timeout: 1.5, repeat: false, completion: { [weak self] in
                Queue.mainQueue().async {
                    guard let self else {
                        return
                    }
                    UIView.animate(withDuration: 0.2, animations: {
                        overlay.alpha = 0.0
                    }, completion: { _ in
                        overlay.removeFromSuperview()
                        if self.screenshotOverlay === overlay {
                            self.screenshotOverlay = nil
                        }
                    })
                }
            }, queue: Queue.mainQueue())
            self?.hideTimer = timer
            timer.start()
        })
    }

    deinit {
        self.disposable?.dispose()
        if let observer = self.fxObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.hideTimer?.invalidate()
        self.recordingCheckTimer?.invalidate()
        self.screenshotOverlay?.removeFromSuperview()
        self.recordingOverlay?.removeFromSuperview()
        self.codeOverlay?.removeFromSuperview()
    }
}

private func gritShieldPattern() -> UIImage {
    let size = CGSize(width: 8.0, height: 8.0)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    UIColor.clear.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    UIColor(red: 0.62, green: 1.0, blue: 0.0, alpha: 0.35).setFill()
    UIRectFill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: size.height))
    UIRectFill(CGRect(x: 0.0, y: 0.0, width: size.width, height: 1.0))
    let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    UIGraphicsEndImageContext()
    return image
}
