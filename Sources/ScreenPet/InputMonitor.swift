import AppKit
import ApplicationServices

enum InputDiagnosticEvent: Equatable {
    case mouseDown
    case keyDown(keyCode: UInt16, isRepeat: Bool)
    case other
}

enum InputEventClassifier {
    static let spaceKeyCode: UInt16 = 49

    static func message(for event: InputDiagnosticEvent) -> String? {
        switch event {
        case .mouseDown:
            return "Click detected"
        case let .keyDown(keyCode, isRepeat):
            guard keyCode == spaceKeyCode, !isRepeat else { return nil }
            return "Space pressed"
        case .other:
            return nil
        }
    }
}

@MainActor
final class InputMonitor {
    private var mouseMonitor: Any?
    private var keyboardMonitor: Any?
    private var isStarted = false
    var onMessage: (@MainActor (String) -> Void)?

    func start() {
        guard !isStarted else { return }
        isStarted = true

        requestAccessibilityIfNeeded()

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.emit(.mouseDown)
            }
        }

        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.emit(.keyDown(keyCode: event.keyCode, isRepeat: event.isARepeat))
            }
        }
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false

        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
            self.keyboardMonitor = nil
        }
    }

    private func requestAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        guard !AXIsProcessTrustedWithOptions(options) else { return }

        print("Accessibility access is required for global Space monitoring; enable ScreenPet in System Settings > Privacy & Security > Accessibility.")
    }

    private func emit(_ event: InputDiagnosticEvent) {
        if let message = InputEventClassifier.message(for: event) {
            onMessage?(message)
        }
    }
}
