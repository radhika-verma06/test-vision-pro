import Foundation
import Combine
import simd

#if os(visionOS)
import ARKit
#endif

class HandTrackingController: ObservableObject {
    @Published var userHandPosition = SIMD3<Float>(0.0, 0.0, -0.4)
    @Published var userHandDirection = SIMD3<Float>(0.0, 1.0, 0.0)
    @Published var isTracked = false
    @Published var isSimulated = true
    
    #if os(visionOS)
    private var arkitSession = ARKitSession()
    private var handTracking = HandTrackingProvider()
    #endif
    
    private var trackingTask: Task<Void, Never>?
    private var simulationTimer: Timer?
    private var simTime: Float = 0.0
    
    // The simulation reads these to know WHERE the reference hand currently is,
    // so it can oscillate around the correct target coordinates.
    // SessionManager updates these each analysis tick.
    var referenceTarget: SIMD3<Float>?
    var referenceDirection: SIMD3<Float>?
    
    func startTracking() {
        #if os(visionOS)
        // Check if hand tracking is supported (only true on Apple Vision Pro hardware, false in simulator)
        if HandTrackingProvider.isSupported {
            isSimulated = false
            trackingTask = Task {
                do {
                    try await arkitSession.run([handTracking])
                    await MainActor.run {
                        self.isTracked = true
                    }
                    
                    for await update in handTracking.anchorUpdates {
                        let anchor = update.anchor
                        // Track the right hand
                        if anchor.chirality == .right && anchor.isTracked {
                            let transform = anchor.originFromAnchorTransform
                            
                            // Extract position from columns.3
                            let position = SIMD3<Float>(
                                transform.columns.3.x,
                                transform.columns.3.y,
                                transform.columns.3.z
                            )
                            
                            // Extract direction (up vector of the hand coordinate frame)
                            let direction = SIMD3<Float>(
                                transform.columns.1.x,
                                transform.columns.1.y,
                                transform.columns.1.z
                            )
                            
                            await MainActor.run {
                                self.userHandPosition = position
                                self.userHandDirection = direction
                            }
                        }
                    }
                } catch {
                    print("ARKit Hand Tracking failed to run: \(error). Falling back to simulation.")
                    await MainActor.run {
                        self.startSimulation()
                    }
                }
            }
            return
        }
        #endif
        
        // Fallback to simulation if not visionOS hardware or not supported
        startSimulation()
    }
    
    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
        #if os(visionOS)
        arkitSession.stop()
        #endif
        stopSimulation()
    }
    
    private func startSimulation() {
        isSimulated = true
        isTracked = true
        simTime = 0.0
        
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.simTime += 1.0 / 30.0
            
            // The simulation tracks the REFERENCE hand's current target position
            // and oscillates around it, periodically drifting in and out of alignment.
            // This makes the spatial matching loop actually testable.
            let refPos = self.referenceTarget ?? SIMD3<Float>(0.0, 0.0, -0.4)
            let refDir = self.referenceDirection ?? SIMD3<Float>(0.0, 1.0, 0.0)
            
            // Oscillate around the reference target within ±3-4cm
            // Uses multiple sine waves to create organic, non-repeating motion
            let xDrift = Float(0.035 * sin(Double(self.simTime) * 1.5))
            let yDrift = Float(0.030 * cos(Double(self.simTime) * 2.0))
            let zDrift = Float(0.025 * sin(Double(self.simTime) * 0.8))
            
            let simPos = SIMD3<Float>(
                refPos.x + xDrift,
                refPos.y + yDrift,
                refPos.z + zDrift
            )
            
            // Direction oscillates around the reference direction
            let pitch = Float(sin(Double(self.simTime) * 1.2) * 0.35)
            let simDir = SIMD3<Float>(
                refDir.x + pitch * 0.3,
                refDir.y * cos(pitch),
                refDir.z + sin(pitch) * 0.4
            )
            
            DispatchQueue.main.async {
                self.userHandPosition = simPos
                self.userHandDirection = simDir
            }
        }
    }
    
    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isTracked = false
    }
}
