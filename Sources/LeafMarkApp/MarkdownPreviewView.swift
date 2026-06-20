import AppKit
import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    @Binding var copyRequested: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let resourceBaseURL = baseURL?.deletingLastPathComponent()

        if context.coordinator.lastHTML != html
            || context.coordinator.lastResourceBaseURL != resourceBaseURL {
            context.coordinator.lastHTML = html
            context.coordinator.lastResourceBaseURL = resourceBaseURL
            if let navigation = webView.loadHTMLString(html, baseURL: resourceBaseURL) {
                context.coordinator.isLoading = true
                context.coordinator.loadingNavigation = navigation
            } else {
                context.coordinator.isLoading = false
                context.coordinator.loadingNavigation = nil
            }
        }

        if copyRequested {
            let copyRequested = $copyRequested
            if context.coordinator.isLoading {
                context.coordinator.pendingCopy = true
            } else {
                context.coordinator.copyRenderedContent()
            }
            DispatchQueue.main.async {
                copyRequested.wrappedValue = false
            }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastHTML = ""
        var lastResourceBaseURL: URL?
        var isLoading = false
        var pendingCopy = false
        var loadingNavigation: WKNavigation?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased()
            if ["http", "https", "mailto"].contains(scheme) {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard navigation === loadingNavigation else { return }

            isLoading = false
            loadingNavigation = nil

            if pendingCopy {
                pendingCopy = false
                copyRenderedContent()
            }
        }

        func copyRenderedContent() {
            webView?.evaluateJavaScript("document.documentElement.outerHTML") { html, _ in
                self.webView?.evaluateJavaScript("document.body.innerText") { text, _ in
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()

                    if let html = html as? String {
                        pasteboard.setString(html, forType: .html)
                    }

                    if let text = text as? String {
                        pasteboard.setString(text, forType: .string)
                    }
                }
            }
        }
    }
}
