import Foundation
import SwiftSignalKit
import AudioToolbox
import AppBundle
import TelegramPresentationData

private func loadSystemSoundFromBundle(name: String) -> SystemSoundID? {
    let path = "\(getAppBundle().resourcePath!)/\(name)"
    let url = URL(fileURLWithPath: path)
    var sound: SystemSoundID = 0
    if AudioServicesCreateSystemSoundID(url as CFURL, &sound) == noErr {
        return sound
    }
    return nil
}

public final class ServiceSoundManager {
    private let queue = Queue()
    private var messageDeliverySound: SystemSoundID?
    private var incomingMessageSound: SystemSoundID?
    private var gritCodeSound: SystemSoundID?
    
    init() {
        self.queue.async {
            // GRIT SOUND: own distorted thud and two-hit clank.
            self.messageDeliverySound = loadSystemSoundFromBundle(name: "grit_send.mp3")
            self.incomingMessageSound = loadSystemSoundFromBundle(name: "grit_notify.mp3")
            self.gritCodeSound = loadSystemSoundFromBundle(name: "grit_notify.mp3")
        }
    }
    
    public func playMessageDeliveredSound() {
        guard GritSettings.soundEnabled else {
            return
        }
        self.queue.async {
            if let messageDeliverySound = self.messageDeliverySound {
                AudioServicesPlaySystemSound(messageDeliverySound)
            }
        }
    }
    
    public func playIncomingMessageSound() {
        guard GritSettings.soundEnabled else {
            return
        }
        self.queue.async {
            if let incomingMessageSound = self.incomingMessageSound {
                AudioServicesPlaySystemSound(incomingMessageSound)
            }
        }
    }
    
    public func playGritCodeSound() {
        guard GritSettings.soundEnabled else {
            return
        }
        self.queue.async {
            if let gritCodeSound = self.gritCodeSound {
                AudioServicesPlaySystemSound(gritCodeSound)
            }
        }
    }

    public func playVibrationSound() {
        self.queue.async {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    public func playLockSound() {
        self.queue.async {
            AudioServicesPlaySystemSound(1100)
        }
    }
}

public let serviceSoundManager = ServiceSoundManager()
