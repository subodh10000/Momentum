// MARK: - FirebaseAuthManager.swift (UPDATED)

import Foundation
import FirebaseAuth
import Combine
class FirebaseAuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        startListening()
    }

    deinit {
        stopListening()
    }


    func startListening() {
        if authStateHandle != nil { stopListening() }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let previousState = self.isLoggedIn
                self.isLoggedIn = (user != nil)
                if self.isLoggedIn != previousState { // Optional: Only print on actual change
                     print("Auth State Changed: User is \(self.isLoggedIn ? "Logged In" : "Logged Out")")
                }
            }
        }
    }

    func stopListening() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
            print("Auth State Listener Removed")
        }
    }


    func register(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                 print("Registration successful for \(authResult?.user.email ?? "unknown user")")
                completion(.success(()))
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Login successful for \(authResult?.user.email ?? "unknown user")")
                completion(.success(()))
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            print("Logout successful")
            NotificationCenter.default.post(name: .didLogout, object: nil)
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}
