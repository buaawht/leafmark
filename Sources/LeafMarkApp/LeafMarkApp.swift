import AppKit
import SwiftUI

@main
struct LeafMarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var openedURLs: [URL] = []

    var body: some Scene {
        Window("LeafMark", id: "main") {
            ContentView(pendingOpenedURLs: $openedURLs)
                .frame(minWidth: 900, minHeight: 600)
                .onOpenURL { url in
                    openedURLs.append(url)
                }
                .onAppear {
                    openedURLs.append(contentsOf: appDelegate.consumePendingOpenURLs())
                }
                .onReceive(NotificationCenter.default.publisher(for: .leafMarkOpenURLs)) { notification in
                    guard let urls = notification.userInfo?[AppDelegate.openURLsUserInfoKey] as? [URL] else {
                        return
                    }
                    openedURLs.append(contentsOf: urls)
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let openURLsUserInfoKey = "urls"
    private var pendingOpenURLs: [URL] = []

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        pendingOpenURLs.append(contentsOf: urls)
        NotificationCenter.default.post(
            name: .leafMarkOpenURLs,
            object: nil,
            userInfo: [Self.openURLsUserInfoKey: urls]
        )
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func consumePendingOpenURLs() -> [URL] {
        let urls = pendingOpenURLs
        pendingOpenURLs.removeAll()
        return urls
    }
}

extension Notification.Name {
    static let leafMarkOpenURLs = Notification.Name("leafMarkOpenURLs")
}
