import Foundation
import Combine

struct AppUser: Codable {
    let email: String
    let username: String
    var isUnlockedByDoctor: Bool
}

class AuthManager: ObservableObject {
    @Published var currentUser: AppUser? = nil
    @Published var isLoggedIn = false 
    private var mockUsers: [AppUser] = [
        AppUser(email: "patient@test.com", username: "radhika", isUnlockedByDoctor: false),
        AppUser(email: "unlocked@test.com", username: "testpatient", isUnlockedByDoctor: true)
    ]

    func login(emailOrUsername: String, password: String) -> Bool {
        if let user = mockUsers.first(where: {
            $0.email == emailOrUsername || $0.username == emailOrUsername
        }) {
            currentUser = user
            isLoggedIn = true
            return true
        }
        return false
    }

    func createAccount(email: String, username: String, password: String) {
        let newUser = AppUser(email: email, username: username, isUnlockedByDoctor: false)
        mockUsers.append(newUser)
        currentUser = newUser
        isLoggedIn = true
    }

    func doctorUnlock(emailOrUsername: String) {
        for i in mockUsers.indices {
            if mockUsers[i].email == emailOrUsername || mockUsers[i].username == emailOrUsername {
                mockUsers[i].isUnlockedByDoctor = true
                if currentUser?.email == emailOrUsername || currentUser?.username == emailOrUsername {
                    currentUser = mockUsers[i]
                }
            }
        }
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
}
