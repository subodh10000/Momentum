
import SwiftUI

struct AuthRouter: View {
    @EnvironmentObject var authManager: FirebaseAuthManager

    var body: some View {
        if authManager.isLoggedIn {
            HomeView()
            LoginView()
        }
    }
}
