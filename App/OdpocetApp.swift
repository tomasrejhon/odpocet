import SwiftUI

@main
struct OdpocetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.orange)
                .environment(\.locale, Locale(identifier: "cs_CZ"))
        }
    }
}
