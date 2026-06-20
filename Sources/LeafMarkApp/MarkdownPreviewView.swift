import AppKit
import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    @Binding var copyRequested: Bool
    @Binding var scrollPercentage: Double
    @Binding var scrollTargetID: String?
    @Binding var pdfExportURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.webViewConfiguration())
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    static func webViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        return configuration
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

        context.coordinator.applyScrollPercentage(scrollPercentage)

        if scrollTargetID != nil {
            let scrollTargetIDBinding = $scrollTargetID
            context.coordinator.scrollToElement(id: scrollTargetIDBinding.wrappedValue)
            DispatchQueue.main.async {
                scrollTargetIDBinding.wrappedValue = nil
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

        if pdfExportURL != nil {
            let pdfExportURLBinding = $pdfExportURL
            context.coordinator.exportPDF(to: pdfExportURLBinding.wrappedValue)
            DispatchQueue.main.async {
                pdfExportURLBinding.wrappedValue = nil
            }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastHTML = ""
        var lastResourceBaseURL: URL?
        var isLoading = false
        var pendingCopy = false
        var pendingScrollPercentage: Double?
        var pendingScrollTargetID: String?
        var pendingPDFExportURL: URL?
        var loadingNavigation: WKNavigation?
        private var lastAppliedScrollPercentage: Double?
        private var pdfExporter: PDFExporter?

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

            if let pendingScrollPercentage {
                self.pendingScrollPercentage = nil
                applyScrollPercentage(pendingScrollPercentage)
            }

            if let pendingScrollTargetID {
                self.pendingScrollTargetID = nil
                scrollToElement(id: pendingScrollTargetID)
            }

            if let pendingPDFExportURL {
                self.pendingPDFExportURL = nil
                exportPDF(to: pendingPDFExportURL)
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

        func applyScrollPercentage(_ percentage: Double) {
            let clampedPercentage = min(1, max(0, percentage))

            guard abs((lastAppliedScrollPercentage ?? -1) - clampedPercentage) > 0.01 else {
                return
            }

            if isLoading {
                pendingScrollPercentage = clampedPercentage
                return
            }

            lastAppliedScrollPercentage = clampedPercentage
            let script = """
            (() => {
              const maxY = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
              window.scrollTo(0, \(clampedPercentage) * maxY);
            })();
            """
            webView?.evaluateJavaScript(script)
        }

        func scrollToElement(id: String?) {
            guard let id, !id.isEmpty else { return }

            if isLoading {
                pendingScrollTargetID = id
                return
            }

            let script = """
            (() => {
              const element = document.getElementById(\(Self.javaScriptStringLiteral(id)));
              if (element) {
                element.scrollIntoView({ block: 'start' });
              }
            })();
            """
            webView?.evaluateJavaScript(script)
        }

        private static func javaScriptStringLiteral(_ value: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [value]),
                  let arrayLiteral = String(data: data, encoding: .utf8)
            else {
                return #""""#
            }

            return String(arrayLiteral.dropFirst().dropLast())
        }

        func exportPDF(to url: URL?) {
            guard let url else { return }

            if isLoading {
                pendingPDFExportURL = url
                return
            }

            let exporter = PDFExporter(
                html: lastHTML,
                baseURL: lastResourceBaseURL,
                destinationURL: url
            ) { [weak self] in
                self?.pdfExporter = nil
            }
            pdfExporter = exporter
            exporter.start()
        }
    }
}

private final class PDFExporter: NSObject, WKNavigationDelegate {
    private static let a4Width = 794.0
    private static let a4Height = 1123.0

    private let html: String
    private let baseURL: URL?
    private let destinationURL: URL
    private let completion: () -> Void
    private let webView: WKWebView
    private var navigation: WKNavigation?

    init(
        html: String,
        baseURL: URL?,
        destinationURL: URL,
        completion: @escaping () -> Void
    ) {
        self.html = html
        self.baseURL = baseURL
        self.destinationURL = destinationURL
        self.completion = completion
        self.webView = WKWebView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Self.a4Width,
                height: Self.a4Height
            ),
            configuration: MarkdownPreviewView.webViewConfiguration()
        )
        super.init()
        webView.navigationDelegate = self
    }

    func start() {
        navigation = webView.loadHTMLString(html, baseURL: baseURL)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard navigation === self.navigation else { return }

        webView.evaluateJavaScript("[document.documentElement.scrollWidth, document.documentElement.scrollHeight]") { dimensions, _ in
            let configuration = WKPDFConfiguration()
            configuration.rect = CGRect(origin: .zero, size: Self.pdfSize(from: dimensions))
            let destinationURL = self.destinationURL
            let completion = self.completion

            webView.createPDF(configuration: configuration) { [destinationURL, completion] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        do {
                            try data.write(to: destinationURL, options: .atomic)
                        } catch {
                            AppDialogCoordinator.showError(error.localizedDescription)
                        }
                    case .failure(let error):
                        AppDialogCoordinator.showError(error.localizedDescription)
                    }
                    completion()
                }
            }
        }
    }

    private static func pdfSize(from dimensions: Any?) -> CGSize {
        guard let values = dimensions as? [Any], values.count == 2 else {
            return CGSize(width: a4Width, height: a4Height)
        }

        let height = values[1] as? Double ?? a4Height
        return CGSize(width: a4Width, height: max(a4Height, height))
    }
}
