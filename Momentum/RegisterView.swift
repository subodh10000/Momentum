// MARK: - RegisterView.swift (UPDATED)

import SwiftUI
import FirebaseAuth // Required for AuthErrorCode

struct RegisterView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @Environment(\.presentationMode) var presentationMode // If presented modally

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Optional Background to match LoginView if desired
            // Color.gray.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle.bold())
                    .foregroundColor(.purple) // Match theme
                    .padding(.bottom, 20)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress).autocapitalization(.none)
                    .padding().background(Color.gray.opacity(0.1)).cornerRadius(10)
                    .disabled(isLoading)

                SecureField("Password (min. 6 characters)", text: $password) // Hint for user
                    .padding().background(Color.gray.opacity(0.1)).cornerRadius(10)
                    .disabled(isLoading)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding().background(Color.gray.opacity(0.1)).cornerRadius(10)
                    .disabled(isLoading)

                if let errMsg = errorMessage {
                    Text(errMsg)
                        .foregroundColor(.red).font(.callout)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                Button(action: performRegistration) {
                    Text("Register")
                        .frame(maxWidth: .infinity).padding()
                        .background(isLoading ? Color.purple.opacity(0.5) : Color.purple)
                        .foregroundColor(.white).cornerRadius(10)
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding()

            // Loading Indicator Overlay
            if isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView().scaleEffect(1.5).progressViewStyle(CircularProgressViewStyle(tint: .purple))
            }
        }
        // Use .navigationTitle only if pushed onto a NavigationView stack from LoginView
        // .navigationTitle("Register")
        // .navigationBarTitleDisplayMode(.inline) // Or .large
        // Add back button customization if needed
    }

    // MARK: - Registration Logic
    func performRegistration() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        // Password length checked by Firebase, but good to check client-side too
        guard password.count >= 6 else {
             errorMessage = "Password must be at least 6 characters long."
             return
        }

        errorMessage = nil
        isLoading = true

        authManager.register(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                print("Registration successful, user should be logged in.")
                // AuthRouter handles view switch. No explicit navigation needed here.
                // Optionally dismiss if presented modally:
                // presentationMode.wrappedValue.dismiss()
                
            case .failure(let error):
                 if let nsError = error as NSError,
                    let errorCode = AuthErrorCode(rawValue: nsError.code) {
                    switch errorCode {
                    case .emailAlreadyInUse:
                        errorMessage = "This email address is already in use."
                    case .invalidEmail:
                        errorMessage = "The email address is badly formatted."
                    case .weakPassword:
                        errorMessage = error.localizedDescription // Firebase often gives good description
                    case .networkError:
                        errorMessage = "Network error. Please check your connection."
                    default:
                         errorMessage = "An unexpected error occurred. (\(errorCode.rawValue))"
                         print("Unhandled Firebase Auth Error Code: \(errorCode.rawValue) - \(error.localizedDescription)")
                    }
                 } else {
                     errorMessage = "An error occurred: \(error.localizedDescription)"
                     print("Registration failed with non-Firebase or unknown error: \(error)")
                 }
            }
        }
    }
}

// MARK: - RegisterView Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Preview within NavigationView context
            RegisterView()
                .environmentObject(FirebaseAuthManager())
        }
    }
}
