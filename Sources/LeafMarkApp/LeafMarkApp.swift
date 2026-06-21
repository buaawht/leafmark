import AppKit
import SwiftUI

@main
struct LeafMarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var openURLRouter = OpenURLRouter.shared

    var body: some Scene {
        WindowGroup {
            ContentView(openURLRouter: openURLRouter)
                .frame(minWidth: 900, minHeight: 600)
                .onOpenURL { url in
                    openURLRouter.append([url])
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            OpenURLRouter.shared.append(urls)
        }
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Task { @MainActor in
            OpenURLRouter.shared.append([URL(fileURLWithPath: filename)])
        }
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        Task { @MainActor in
            OpenURLRouter.shared.append(urls)
        }
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

}

@MainActor
final class OpenURLRouter: ObservableObject {
    static let shared = OpenURLRouter()

    @Published private(set) var pendingChangeID = 0
    private var pendingURLs: [URL] = []

    private init() {}

    func append(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        pendingURLs.append(contentsOf: urls)
        pendingChangeID += 1
    }

    func consumePendingURLs() -> [URL] {
        let urls = pendingURLs
        pendingURLs.removeAll()
        return urls
    }
}
