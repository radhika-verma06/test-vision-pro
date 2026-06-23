import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var showDoctorUnlock = false
    @State private var unlockEmail = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text("Welcome, \(auth.currentUser?.username ?? "Patient")")
                    .font(.extraLargeTitle).bold()

                if auth.currentUser?.isUnlockedByDoctor == true {
                    // UNLOCKED — show exercises
                    Text("Your prescribed sessions are ready.")
                        .foregroundColor(.green)

                    NavigationLink("Start Therapy Session") {
                        SessionView()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)

                } else {
                    // LOCKED
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Your session hasn't been unlocked yet.")
                            .font(.title2)
                        Text("Your doctor needs to approve your therapy plan first.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // PROTOTYPE ONLY — simulates doctor unlock
                    Button("Simulate Doctor Unlock") {
                        showDoctorUnlock = true
                    }
                    .foregroundColor(.secondary)
                    .font(.footnote)
                }

                Spacer()

                Button("Log Out") { auth.logout() }
                    .foregroundColor(.red)
            }
            .padding(40)
            .sheet(isPresented: $showDoctorUnlock) {
                VStack(spacing: 16) {
                    Text("Doctor Portal (Prototype)")
                        .font(.title).bold()
                    Text("Enter patient email or username to unlock:")
                    TextField("Email or Username", text: $unlockEmail)
                        .textFieldStyle(.roundedBorder)
                    Button("Unlock") {
                        auth.doctorUnlock(emailOrUsername: unlockEmail)
                        showDoctorUnlock = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                .frame(minWidth: 400)
            }
        }
    }
}
