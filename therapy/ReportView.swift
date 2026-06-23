import SwiftUI

struct ReportView: View {
    var session: TherapySession
    @Environment(\.dismiss) var dismiss
    
    var totalDuration: Int {
        session.completedExercises.reduce(0) { $0 + $1.durationSeconds }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Text("Therapy Diagnostic Report")
                        .font(.title).bold()
                    Text("Completed: \(session.startTime?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                if let report = session.report {
                    // 1. Performance Overview Gauges
                    HStack(spacing: 24) {
                        VStack(spacing: 10) {
                            Text("Accuracy")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.1), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(report.accuracyPercentage / 100.0))
                                    .stroke(
                                        AngularGradient(
                                            colors: [.orange, .green],
                                            center: .center,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(360)
                                        ),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 80, height: 80)
                                
                                Text(String(format: "%.0f%%", report.accuracyPercentage))
                                    .font(.title3).bold()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        VStack(spacing: 10) {
                            Text("Consistency")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.1), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(report.consistencyScore / 100.0))
                                    .stroke(
                                        AngularGradient(
                                            colors: [.blue, .cyan],
                                            center: .center,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(360)
                                        ),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 80, height: 80)
                                
                                Text(String(format: "%.0f%%", report.consistencyScore))
                                    .font(.title3).bold()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    
                    // 2. Spatial Metrics Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Detailed Spatial Metrics")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average Error")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f cm", report.averageError * 100.0))
                                    .font(.title3).bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time in Target")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1fs", report.timeInThreshold))
                                    .font(.title3).bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Matches Held")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(report.successfulMatches) poses")
                                    .font(.title3).bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    
                    // 3. AI Coach Tip Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("AI Therapist Feedback")
                                .font(.headline)
                        }
                        
                        Text(report.improvementSuggestion)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(16)
                }
                
                Divider()
                
                // 4. Completed Exercises list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise History")
                        .font(.headline)
                    
                    ForEach(session.completedExercises) { completed in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completed.exercise.name)
                                    .font(.subheadline).bold()
                                Text("Duration: \(completed.durationSeconds)s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(completed.estimatedAccuracy)% Acc")
                                .font(.subheadline).bold()
                                .foregroundColor(completed.estimatedAccuracy >= 80 ? .green : .orange)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
                
                // Disclaimer
                Text("⚠️ Clinical accuracy figures are based on experimental spatial models. Do not use for formal medical decisions.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Done Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Close Report")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .frame(width: 500, height: 600)
    }
}
