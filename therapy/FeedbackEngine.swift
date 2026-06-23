import Foundation
import simd

struct FeedbackResult {
    let distance: Float
    let angleDifferenceDegrees: Float
    let feedbackText: String
    let isAligned: Bool
}

class FeedbackEngine {
    // Configurable thresholds: 5 cm distance and 20 degrees angle
    static let distanceThreshold: Float = 0.05
    static let angleThresholdDegrees: Float = 20.0
    
    /// Computes feedback by comparing the user hand status with the reference pose
    /// - Parameters:
    ///   - userPosition: The tracked position of the user's hand (SIMD3<Float>)
    ///   - userDirection: The normal/pointing direction of the user's hand (SIMD3<Float>)
    ///   - refPosition: The position of the target reference hand (SIMD3<Float>)
    ///   - refDirection: The direction of the target reference hand (SIMD3<Float>)
    static func analyze(userPosition: SIMD3<Float>, userDirection: SIMD3<Float>,
                        refPosition: SIMD3<Float>, refDirection: SIMD3<Float>) -> FeedbackResult {
        
        // 1. distance = length(userHand - referenceHand)
        let distance = simd_length(userPosition - refPosition)
        
        // 2. direction = normalize(vector)
        let userDirNorm = simd_normalize(userDirection)
        let refDirNorm = simd_normalize(refDirection)
        
        // 3. angle = acos(dot(a, b) / (|a||b|))
        let dotProduct = simd_dot(userDirNorm, refDirNorm)
        let clampedRatio = max(-1.0, min(1.0, dotProduct))
        let angleRad = acos(clampedRatio)
        
        let angleDeg = angleRad * 180.0 / .pi
        
        // 4. real-time feedback classification
        let isDistanceOk = distance <= distanceThreshold
        let isAngleOk = angleDeg <= angleThresholdDegrees
        
        let feedbackText: String
        if !isDistanceOk {
            feedbackText = "Move closer"
        } else if !isAngleOk {
            feedbackText = "Adjust angle"
        } else {
            feedbackText = "Good alignment"
        }
        
        return FeedbackResult(
            distance: distance,
            angleDifferenceDegrees: angleDeg,
            feedbackText: feedbackText,
            isAligned: isDistanceOk && isAngleOk
        )
    }
}
