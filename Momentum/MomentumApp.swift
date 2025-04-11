import SwiftUI

@main
struct MomentumApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AuthRouter()
        }
    }
}
