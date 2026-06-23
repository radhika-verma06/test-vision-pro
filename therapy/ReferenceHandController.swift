import Foundation
import Combine
import simd

class ReferenceHandController: ObservableObject {
    @Published var currentPoseIndex = 0
    @Published var currentPose: TherapyPose?
    
    // Smoothly interpolated position and direction for the 3D reference hand model
    @Published var currentPosition = SIMD3<Float>(0.0, 1.2, -0.5)
    @Published var currentDirection = SIMD3<Float>(0.0, 1.0, 0.0)
    
    // Hold progress (0.0 to 1.0) representing how long the user has held the current pose
    @Published var holdProgress: Double = 0.0
    
    private var poses: [TherapyPose] = []
    private var updateTimer: Timer?
    private var holdAccumulator: Double = 0.0
    private let holdDurationRequired: Double = 2.0 // 2 seconds hold required to complete a pose
    
    var onPoseMatched: (() -> Void)?
    var onSequenceCompleted: (() -> Void)?
    
    func startSequence(with poses: [TherapyPose]) {
        self.poses = poses
        self.currentPoseIndex = 0
        self.holdAccumulator = 0.0
        self.holdProgress = 0.0
        
        if !poses.isEmpty {
            let initialPose = poses[0]
            self.currentPose = initialPose
            self.currentPosition = initialPose.targetPosition
            self.currentDirection = initialPose.targetDirection
        }
        
        startLoop()
    }
    
    func stopSequence() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func startLoop() {
        updateTimer?.invalidate()
        // 60Hz update rate for fluid animation
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self, let targetPose = self.currentPose else { return }
            
            // Linear interpolation (lerp) coefficient
            let lerpAlpha: Float = 0.08
            
            // Interpolate position
            self.currentPosition = self.currentPosition + (targetPose.targetPosition - self.currentPosition) * lerpAlpha
            
            // Interpolate direction vector (and normalize to avoid scaling artifacts)
            self.currentDirection = simd_normalize(self.currentDirection + (targetPose.targetDirection - self.currentDirection) * lerpAlpha)
        }
    }
    
    /// Update matching state based on real-time alignment
    func updateMatching(isAligned: Bool, deltaTime: Double) {
        guard currentPose != nil else { return }
        
        if isAligned {
            holdAccumulator += deltaTime
            holdProgress = min(1.0, holdAccumulator / holdDurationRequired)
            
            if holdAccumulator >= holdDurationRequired {
                advancePose()
            }
        } else {
            // Slowly decay alignment if they drift out of alignment
            holdAccumulator = max(0.0, holdAccumulator - deltaTime * 0.8)
            holdProgress = holdAccumulator / holdDurationRequired
        }
    }
    
    private func advancePose() {
        holdAccumulator = 0.0
        holdProgress = 0.0
        onPoseMatched?()
        
        if currentPoseIndex + 1 < poses.count {
            currentPoseIndex += 1
            currentPose = poses[currentPoseIndex]
        } else {
            // Sequence completed!
            onSequenceCompleted?()
        }
    }
}
