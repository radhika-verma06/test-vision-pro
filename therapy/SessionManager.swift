import Foundation
import Combine
import simd

class SessionManager: ObservableObject {
    @Published var isSessionActive = false
    @Published var currentExerciseIndex = 0
    @Published var timeRemaining = 0
    @Published var sessionComplete = false
    @Published var speedMultiplier: Double = 1.0
    @Published var isRecording = false
    
    // Real-time metrics updated at 10Hz
    @Published var isAligned = false
    @Published var realTimeFeedback = "Waiting for hand detection..."
    @Published var distanceError: Float = 0.0
    @Published var angleError: Float = 0.0
    
    // Core controllers for hand tracking and reference animation
    var handTracker = HandTrackingController()
    var refController = ReferenceHandController()
    
    var session = TherapySession()
    private var timer: AnyCancellable?
    private var updateTimer: Timer?
    private var exercises = Exercise.defaults
    
    // Performance accumulators (per exercise)
    private var totalSamples = 0
    private var sumDistanceError: Float = 0.0
    private var sumAngleError: Float = 0.0
    private var timeInThresholdSecs: Double = 0.0
    private var successfulMatchesCount = 0
    private var totalDurationSecs: Double = 0.0
    
    // Performance accumulators (session wide)
    private var sessionTotalSamples = 0
    private var sessionSumDistanceError: Float = 0.0
    private var sessionSumAngleError: Float = 0.0
    private var sessionTimeInThresholdSecs: Double = 0.0
    private var sessionTotalDurationSecs: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentExercise: Exercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    init() {
        // Forward change notifications from controllers so view updates instantly
        handTracker.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        refController.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        // Configure reference hand matched callback
        refController.onPoseMatched = { [weak self] in
            guard let self = self else { return }
            self.successfulMatchesCount += 1
            AICoach.shared.speak("Perfect match! Keep holding.", force: true)
        }
        
        // Configure reference hand sequence complete callback
        refController.onSequenceCompleted = { [weak self] in
            guard let self = self else { return }
            AICoach.shared.speak("Exercise sequence complete!", force: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.completeCurrentExercise()
            }
        }
    }
    
    func setSpeed(_ multiplier: Double) {
        guard let ex = currentExercise else { return }
        speedMultiplier = min(max(multiplier, ex.safeMinSpeed), ex.safeMaxSpeed)
    }
    
    func startSession() {
        session = TherapySession()
        session.startTime = Date()
        currentExerciseIndex = 0
        isSessionActive = true
        isRecording = true
        
        // Reset session-wide statistics
        sessionTotalSamples = 0
        sessionSumDistanceError = 0.0
        sessionSumAngleError = 0.0
        sessionTimeInThresholdSecs = 0.0
        sessionTotalDurationSecs = 0.0
        successfulMatchesCount = 0
        
        handTracker.startTracking()
        startExercise()
    }
    
    private func startExercise() {
        guard let ex = currentExercise else {
            endSession()
            return
        }
        
        // Reset per-exercise statistics
        totalSamples = 0
        sumDistanceError = 0.0
        sumAngleError = 0.0
        timeInThresholdSecs = 0.0
        totalDurationSecs = 0.0
        
        refController.startSequence(with: ex.poses)
        timeRemaining = Int(Double(ex.durationSeconds) / speedMultiplier)
        
        AICoach.shared.speak("Starting \(ex.name). \(ex.description)", force: true)
        
        // 1-second interval countdown timer
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.completeCurrentExercise()
                }
            }
            
        // 10Hz feedback engine cycle
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.performAnalysis()
        }
    }
    
    private func performAnalysis() {
        guard isSessionActive, handTracker.isTracked, refController.currentPose != nil else {
            DispatchQueue.main.async {
                self.realTimeFeedback = "Looking for your hand..."
            }
            return
        }
        
        let refPos = refController.currentPosition
        let refDir = refController.currentDirection
        
        // Pass the reference target coordinates to the hand tracker so simulation tracks them
        handTracker.referenceTarget = refPos
        handTracker.referenceDirection = refDir
        
        totalDurationSecs += 0.1
        sessionTotalDurationSecs += 0.1
        
        let userPos = handTracker.userHandPosition
        let userDir = handTracker.userHandDirection
        
        // Run Math Engine
        let result = FeedbackEngine.analyze(
            userPosition: userPos,
            userDirection: userDir,
            refPosition: refPos,
            refDirection: refDir
        )
        
        // Accumulate per-exercise statistics
        totalSamples += 1
        sumDistanceError += result.distance
        sumAngleError += result.angleDifferenceDegrees
        if result.isAligned {
            timeInThresholdSecs += 0.1
        }
        
        // Accumulate session-wide statistics
        sessionTotalSamples += 1
        sessionSumDistanceError += result.distance
        sessionSumAngleError += result.angleDifferenceDegrees
        if result.isAligned {
            sessionTimeInThresholdSecs += 0.1
        }
        
        // Update guide pose sequence matching hold tracker
        refController.updateMatching(isAligned: result.isAligned, deltaTime: 0.1)
        
        // Update states
        DispatchQueue.main.async {
            self.isAligned = result.isAligned
            self.realTimeFeedback = result.feedbackText
            self.distanceError = result.distance
            self.angleError = result.angleDifferenceDegrees
            
            // Speak correction cues
            if !result.isAligned {
                AICoach.shared.speak(result.feedbackText)
            } else {
                AICoach.shared.speak("Good job, hold it right there!")
            }
        }
    }
    
    private func completeCurrentExercise() {
        guard let ex = currentExercise else { return }
        
        let exerciseAccuracy = totalSamples > 0 
            ? Int((timeInThresholdSecs / totalDurationSecs) * 100.0) 
            : 0
            
        session.completedExercises.append(CompletedExercise(
            exercise: ex,
            completedAt: Date(),
            durationSeconds: ex.durationSeconds,
            estimatedAccuracy: max(0, min(100, exerciseAccuracy))
        ))
        
        currentExerciseIndex += 1
        
        if currentExerciseIndex < exercises.count {
            startExercise()
        } else {
            endSession()
        }
    }
    
    func endSession() {
        updateTimer?.invalidate()
        updateTimer = nil
        timer?.cancel()
        timer = nil
        
        handTracker.stopTracking()
        refController.stopSequence()
        AICoach.shared.stopSpeaking()
        
        session.endTime = Date()
        isSessionActive = false
        isRecording = false
        sessionComplete = true
        
        // Compile Performance Metrics
        let avgDist = sessionTotalSamples > 0 ? (sessionSumDistanceError / Float(sessionTotalSamples)) : 0.0
        let avgAng = sessionTotalSamples > 0 ? (sessionSumAngleError / Float(sessionTotalSamples)) : 0.0
        
        let accuracyPercent = sessionTotalDurationSecs > 0 
            ? (sessionTimeInThresholdSecs / sessionTotalDurationSecs) * 100.0 
            : 0.0
            
        let stabilityPenalty = min(50.0, Double(avgDist * 600.0)) // 60% penalty if 10cm off
        let consistency = max(10.0, min(100.0, accuracyPercent * 0.7 + Double(successfulMatchesCount) * 12.0 - stabilityPenalty))
        
        let suggestion: String
        if accuracyPercent >= 80.0 {
            suggestion = "Superb control! Your spatial alignment was highly consistent. Try increasing the speed multiplier to challenge your dexterity."
        } else if avgAng > 20.0 {
            suggestion = "Excellent reach, but your wrist angle was rotated slightly out of axis. Focus on matching the exact palm alignment of the guide hand."
        } else if avgDist > 0.05 {
            suggestion = "Try to bring your hand closer to the target guide. Keep your forearm steady and follow the guide path slowly."
        } else {
            suggestion = "Good progress! Practice regularly to improve wrist flexibility and maintain alignment within the guide area."
        }
        
        session.report = SessionReport(
            averageError: avgDist,
            timeInThreshold: sessionTimeInThresholdSecs,
            successfulMatches: successfulMatchesCount,
            accuracyPercentage: max(0.0, min(100.0, accuracyPercent)),
            consistencyScore: max(0.0, min(100.0, consistency)),
            improvementSuggestion: suggestion
        )
        
        AICoach.shared.speak("Session complete. You achieved an accuracy of \(Int(accuracyPercent)) percent. Check your dashboard for the detailed report.", force: true)
    }
}
