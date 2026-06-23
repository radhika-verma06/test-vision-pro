import SwiftUI

@main
struct therapyApp: App {
    @StateObject var auth = AuthManager()
    @StateObject var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                HomeView()
                    .environmentObject(auth)
                    .environmentObject(sessionManager)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
        
        // Register the spatial immersion space for 3D hand therapy guidance
        ImmersiveSpace(id: "TherapySpace") {
            ImmersiveView()
                .environmentObject(sessionManager)
                .environmentObject(sessionManager.refController)
                .environmentObject(sessionManager.handTracker)
        }
    }
}
