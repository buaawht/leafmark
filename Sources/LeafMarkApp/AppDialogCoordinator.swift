import AppKit
import LeafMarkCore

enum AppDialogCoordinator {
    static func askUnsavedChanges(displayName: String) -> UnsavedChangesDecision {
        let alert = NSAlert()
        alert.messageText = "Save changes to \(displayName)?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .save
        case .alertSecondButtonReturn:
            return .discard
        default:
            return .cancel
        }
    }

    static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "LeafMark Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
