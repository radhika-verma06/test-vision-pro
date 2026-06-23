import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var newEmail = ""
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Hand Therapy Pro")
                .font(.extraLargeTitle).bold()

            if !isCreatingAccount {
                // LOGIN
                TextField("Email or Username", text: $emailOrUsername)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red)
                }

                Button("Log In") {
                    if !auth.login(emailOrUsername: emailOrUsername, password: password) {
                        errorMessage = "User not found. Check your details."
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Create an account instead") {
                    isCreatingAccount = true
                    errorMessage = ""
                }

            } else {
                // CREATE ACCOUNT
                TextField("Email", text: $newEmail)
                    .textFieldStyle(.roundedBorder)
                TextField("Username", text: $newUsername)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $newPassword)
                    .textFieldStyle(.roundedBorder)

                Button("Create Account") {
                    guard !newEmail.isEmpty && !newUsername.isEmpty else {
                        errorMessage = "Please fill all fields."
                        return
                    }
                    auth.createAccount(email: newEmail, username: newUsername, password: newPassword)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Back to Login") {
                    isCreatingAccount = false
                    errorMessage = ""
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
    }
}
