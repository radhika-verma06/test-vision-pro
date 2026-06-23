import Foundation
import AVFoundation

class AICoach {
    static let shared = AICoach()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpeechTime = Date.distantPast
    private var lastSpokenMessage = ""
    
    // Cooldown in seconds to prevent the coach from speaking too frequently
    private let speechCooldown: TimeInterval = 4.0
    
    /// Speaks the given message if cooldown has passed or if forced
    /// - Parameters:
    ///   - message: The text to be spoken
    ///   - force: If true, overrides the cooldown checks
    func speak(_ message: String, force: Bool = false) {
        let now = Date()
        
        // Throttling checks
        let timePassed = now.timeIntervalSince(lastSpeechTime)
        guard force || (timePassed >= speechCooldown && message != lastSpokenMessage) else {
            return
        }
        
        // Interrupted/stop current speaking immediately for new guidance
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: message)
        
        // Configure voice parameters for clear speech
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        utterance.rate = 0.52 // Moderate, clear speaking rate
        utterance.pitchMultiplier = 1.05 // Friendly pitch
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        lastSpeechTime = now
        lastSpokenMessage = message
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
