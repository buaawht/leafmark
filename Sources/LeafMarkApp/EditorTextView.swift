import AppKit
import SwiftUI

struct EditorTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollPercentage: Double
    @Binding var requestedLine: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, scrollPercentage: $scrollPercentage, requestedLine: $requestedLine)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.delegate = context.coordinator
        textView.string = text

        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.startObservingBoundsChanges()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.scrollPercentage = $scrollPercentage
        context.coordinator.requestedLine = $requestedLine

        if let textView = context.coordinator.textView, textView.string != text {
            context.coordinator.isApplyingExternalTextChange = true
            textView.string = text
            context.coordinator.isApplyingExternalTextChange = false
        }

        if let line = requestedLine {
            context.coordinator.scrollToLine(line)
            DispatchQueue.main.async {
                requestedLine = nil
            }
        }
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.stopObservingBoundsChanges()
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var scrollPercentage: Binding<Double>
        var requestedLine: Binding<Int?>
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isApplyingExternalTextChange = false
        private var boundsObserver: NSObjectProtocol?

        init(
            text: Binding<String>,
            scrollPercentage: Binding<Double>,
            requestedLine: Binding<Int?>
        ) {
            self.text = text
            self.scrollPercentage = scrollPercentage
            self.requestedLine = requestedLine
        }

        deinit {
            stopObservingBoundsChanges()
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingExternalTextChange,
                  let textView = notification.object as? NSTextView
            else { return }

            text.wrappedValue = textView.string
        }

        func startObservingBoundsChanges() {
            guard boundsObserver == nil,
                  let contentView = scrollView?.contentView
            else { return }

            boundsObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: contentView,
                queue: .main
            ) { [weak self] _ in
                self?.updateScrollPercentage()
            }
        }

        func stopObservingBoundsChanges() {
            guard let boundsObserver else { return }
            NotificationCenter.default.removeObserver(boundsObserver)
            self.boundsObserver = nil
        }

        func scrollToLine(_ line: Int) {
            guard let textView else { return }

            let offset = utf16Offset(forLine: line, in: textView.string)
            textView.scrollRangeToVisible(NSRange(location: offset, length: 0))
            updateScrollPercentage()
        }

        private func updateScrollPercentage() {
            guard let scrollView,
                  let documentView = scrollView.documentView
            else { return }

            let maxOffset = max(0, documentView.bounds.height - scrollView.contentView.bounds.height)
            let percentage = maxOffset > 0 ? scrollView.contentView.bounds.origin.y / maxOffset : 0
            let clampedPercentage = min(1, max(0, percentage))

            if abs(scrollPercentage.wrappedValue - clampedPercentage) > 0.005 {
                scrollPercentage.wrappedValue = clampedPercentage
            }
        }

        private func utf16Offset(forLine line: Int, in text: String) -> Int {
            let targetLine = max(1, line)
            guard targetLine > 1 else { return 0 }

            var currentLine = 1
            var offset = 0

            for scalar in text.unicodeScalars {
                if currentLine == targetLine {
                    break
                }

                offset += scalar.utf16.count
                if scalar == "\n" {
                    currentLine += 1
                }
            }

            return offset
        }
    }
}
