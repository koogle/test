import SwiftUI

@main
struct MLPlaygroundApp: App {
    @StateObject private var modelManager = MLModelManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelManager)
        }
    }
}
