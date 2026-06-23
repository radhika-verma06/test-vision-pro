import SwiftUI

struct SessionView: View {
    @EnvironmentObject var manager: SessionManager
    @State private var showReport = false
    
    // visionOS immersive space environment actions
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        VStack(spacing: 24) {
            if manager.isSessionActive, let exercise = manager.currentExercise {
                // ACTIVE SESSION VIEW
                VStack(spacing: 20) {
                    // Header Bar
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .opacity(manager.isAligned ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(), value: manager.isAligned)
                            Text("Session Active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Simulation Status Badge
                        if manager.handTracker.isSimulated {
                            Text("Simulator Fallback Active")
                                .font(.caption2).bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Exercise Details
                    VStack(spacing: 8) {
                        Text(exercise.name)
                            .font(.largeTitle).bold()
                        Text(exercise.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Core 3D Matching Feedback Dashboard
                    HStack(spacing: 20) {
                        // Left Card: Pose sequence matching progress
                        VStack(spacing: 12) {
                            Text("Target Pose")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            Text(manager.refController.currentPose?.name ?? "Neutral")
                                .font(.title2).bold()
                                .foregroundColor(.cyan)
                                .multilineTextAlignment(.center)
                                .frame(height: 50)
                            
                            // Visual circular progress or linear progress bar for pose matching
                            VStack(spacing: 6) {
                                ProgressView(value: manager.refController.holdProgress, total: 1.0)
                                    .tint(.green)
                                    .background(Color.secondary.opacity(0.1))
                                
                                Text(String(format: "Pose Match Hold: %.0f%%", manager.refController.holdProgress * 100.0))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        // Right Card: Distance and Angle Errors
                        VStack(spacing: 12) {
                            Text("Precision Metrics")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("Offset")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f cm", manager.distanceError * 100.0))
                                        .font(.title3).monospacedDigit().bold()
                                        .foregroundColor(manager.distanceError <= 0.05 ? .green : .orange)
                                }
                                
                                Divider().frame(height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text("Rotation")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.0f°", manager.angleError))
                                        .font(.title3).monospacedDigit().bold()
                                        .foregroundColor(manager.angleError <= 20.0 ? .green : .orange)
                                }
                            }
                            
                            // Alignment State text
                            Text(manager.realTimeFeedback.uppercased())
                                .font(.caption2).bold()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(manager.isAligned ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(manager.isAligned ? .green : .orange)
                                .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    
                    // Progress & Speed Adjustments
                    HStack(spacing: 30) {
                        // Timer Remaining
                        VStack(alignment: .leading) {
                            Text("Time Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(manager.timeRemaining)s")
                                .font(.title).bold().monospacedDigit()
                        }
                        
                        // Speed Multiplier Controller
                        VStack(alignment: .leading) {
                            Text("Pacing Speed: \(String(format: "%.1f", manager.speedMultiplier))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { manager.speedMultiplier },
                                    set: { manager.setSpeed($0) }
                                ),
                                in: exercise.safeMinSpeed...exercise.safeMaxSpeed,
                                step: 0.1
                            )
                            .frame(width: 180)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    // Stop Session Button
                    Button(action: {
                        Task {
                            await dismissImmersiveSpace()
                            manager.endSession()
                        }
                    }) {
                        Text("End Session Early")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                .padding()
            } else if manager.sessionComplete {
                // SESSION COMPLETE
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .scaleEffect(showReport ? 1.0 : 1.1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: manager.sessionComplete)
                    
                    Text("Therapy Session Complete!")
                        .font(.largeTitle).bold()
                    
                    Text("You've finished all prescribed exercises. Let's analyze your results.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showReport = true
                    }) {
                        Text("View Diagnostic Report")
                            .font(.headline)
                            .padding()
                            .frame(width: 250)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            } else {
                // START SESSION DASHBOARD
                VStack(spacing: 30) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        
                    VStack(spacing: 12) {
                        Text("Spatial Hand Therapy")
                            .font(.largeTitle).bold()
                        Text("Prepare your physical workspace. Once session begins, look at your hand to spawn the 3D tracking anchors.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        Task {
                            // Launch the RealityKit Immersive view
                            let result = await openImmersiveSpace(id: "TherapySpace")
                            switch result {
                            case .opened:
                                manager.startSession()
                            case .error, .userCancelled:
                                print("Could not open immersive space: \(result)")
                                // Fallback: Start session anyway in case simulator environment doesn't support rendering
                                manager.startSession()
                            @unknown default:
                                manager.startSession()
                            }
                        }
                    }) {
                        Text("Begin Spatial Session")
                            .font(.headline)
                            .padding()
                            .frame(width: 250)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
        .glassBackgroundEffect()
        .sheet(isPresented: $showReport) {
            ReportView(session: manager.session)
                .environmentObject(manager)
        }
    }
}
