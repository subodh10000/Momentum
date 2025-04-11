// LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Momentum")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.black)

            Text("Let's boost your productivity.")
                .foregroundColor(.gray)
                .font(.subheadline)

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person")
                    TextField("Enter your email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))

                HStack {
                    Image(systemName: "lock")
                    SecureField("Enter your password", text: $password)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Forgot Password?") {
                    // Handle password reset
                }
                .foregroundColor(.gray)
                .font(.caption)
            }

            Button(action: {
                authManager.login(email: email, password: password) { result in
                    switch result {
                    case .success():
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                Text("Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            HStack {
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                Text("Or continue with")
                    .font(.caption)
                    .foregroundColor(.gray)
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
            }

            HStack(spacing: 24) {
                Image("google")
                    .resizable().frame(width: 36, height: 36)
                Image("apple")
                    .resizable().frame(width: 36, height: 36)
                Image("twitter")
                    .resizable().frame(width: 36, height: 36)
            }

            HStack(spacing: 4) {
                Text("Don’t have an account?")
                NavigationLink("Register", destination: RegisterView())
                    .foregroundColor(.blue)
            }
            .font(.footnote)

            Spacer()
        }
        .padding()
    }
}
