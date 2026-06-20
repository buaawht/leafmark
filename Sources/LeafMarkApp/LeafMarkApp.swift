import SwiftUI

@main
struct LeafMarkApp: App {
    @State private var openedURLs: [URL] = []

    var body: some Scene {
        WindowGroup {
            ContentView(pendingOpenedURLs: $openedURLs)
                .frame(minWidth: 900, minHeight: 600)
                .onOpenURL { url in
                    openedURLs.append(url)
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
