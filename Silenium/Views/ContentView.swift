import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomeView()
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // экран не гаснет, пока приложение открыто (как в играх)
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}
