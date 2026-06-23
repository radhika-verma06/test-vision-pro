import Foundation

struct TherapyPose: Identifiable, Codable {
    let id: UUID
    let name: String
    let targetPosition: SIMD3<Float>
    let targetDirection: SIMD3<Float>
    
    init(id: UUID = UUID(), name: String, targetPosition: SIMD3<Float>, targetDirection: SIMD3<Float>) {
        self.id = id
        self.name = name
        self.targetPosition = targetPosition
        self.targetDirection = targetDirection
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let durationSeconds: Int
    let targetAngleDegrees: Int
    let safeMinSpeed: Double  // multiplier e.g. 0.5 = half speed
    let safeMaxSpeed: Double  // e.g. 1.5 = 50% faster
    let poses: [TherapyPose]

    static let defaults: [Exercise] = [
        Exercise(
            id: UUID(),
            name: "Wrist Flexion & Extension",
            description: "Follow the guide hand as it bends downwards, returns neutral, and extends upwards.",
            durationSeconds: 45,
            targetAngleDegrees: 45,
            safeMinSpeed: 0.5,
            safeMaxSpeed: 1.5,
            poses: [
                TherapyPose(
                    name: "Neutral Hand",
                    targetPosition: SIMD3<Float>(0.0, 0.0, -0.4),
                    targetDirection: SIMD3<Float>(0.0, 1.0, 0.0) // Palm facing up
                ),
                TherapyPose(
                    name: "Wrist Flexion (Down)",
                    targetPosition: SIMD3<Float>(0.0, -0.08, -0.38),
                    targetDirection: SIMD3<Float>(0.0, 0.707, 0.707) // Bent forward/downward
                ),
                TherapyPose(
                    name: "Neutral Hand",
                    targetPosition: SIMD3<Float>(0.0, 0.0, -0.4),
                    targetDirection: SIMD3<Float>(0.0, 1.0, 0.0)
                ),
                TherapyPose(
                    name: "Wrist Extension (Up)",
                    targetPosition: SIMD3<Float>(0.0, 0.08, -0.42),
                    targetDirection: SIMD3<Float>(0.0, 0.707, -0.707) // Bent backward/upward
                )
            ]
        ),
        Exercise(
            id: UUID(),
            name: "Finger Spreading & Fist",
            description: "Open your fingers wide, then slowly curl them into a tight fist.",
            durationSeconds: 45,
            targetAngleDegrees: 60,
            safeMinSpeed: 0.5,
            safeMaxSpeed: 1.5,
            poses: [
                TherapyPose(
                    name: "Open Flat Hand",
                    targetPosition: SIMD3<Float>(0.05, 0.02, -0.4),
                    targetDirection: SIMD3<Float>(0.0, 1.0, 0.0)
                ),
                TherapyPose(
                    name: "Spread Fingers Wide",
                    targetPosition: SIMD3<Float>(0.05, 0.02, -0.4),
                    targetDirection: SIMD3<Float>(0.0, 0.9, 0.1)
                ),
                TherapyPose(
                    name: "Closed Fist",
                    targetPosition: SIMD3<Float>(0.05, -0.02, -0.4),
                    targetDirection: SIMD3<Float>(0.0, 0.5, 0.5)
                )
            ]
        )
    ]
}

struct SessionReport: Identifiable, Codable {
    let id: UUID
    let averageError: Float         // in meters
    let timeInThreshold: Double     // seconds
    let successfulMatches: Int
    let accuracyPercentage: Double  // 0 to 100
    let consistencyScore: Double    // 0 to 100
    let improvementSuggestion: String
    
    init(id: UUID = UUID(), averageError: Float, timeInThreshold: Double, successfulMatches: Int, accuracyPercentage: Double, consistencyScore: Double, improvementSuggestion: String) {
        self.id = id
        self.averageError = averageError
        self.timeInThreshold = timeInThreshold
        self.successfulMatches = successfulMatches
        self.accuracyPercentage = accuracyPercentage
        self.consistencyScore = consistencyScore
        self.improvementSuggestion = improvementSuggestion
    }
}

struct CompletedExercise: Identifiable, Codable {
    let id: UUID
    let exercise: Exercise
    let completedAt: Date
    let durationSeconds: Int
    let estimatedAccuracy: Int
    
    init(id: UUID = UUID(), exercise: Exercise, completedAt: Date, durationSeconds: Int, estimatedAccuracy: Int) {
        self.id = id
        self.exercise = exercise
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.estimatedAccuracy = estimatedAccuracy
    }
}

struct TherapySession {
    var startTime: Date?
    var endTime: Date?
    var completedExercises: [CompletedExercise] = []
    var report: SessionReport?
}
