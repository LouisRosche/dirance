import UIKit
import CoreHaptics

/// Manages haptic feedback throughout the app for improved user experience
/// Provides tactile feedback for game events, UI interactions, and achievements
@MainActor
class HapticManager {
    static let shared = HapticManager()

    // MARK: - Feedback Generators

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // Core Haptics Engine (iOS 13+)
    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics = false

    // MARK: - Settings

    @Published var isEnabled = true // User preference

    // MARK: - Initialization

    private init() {
        prepareGenerators()
        setupCoreHaptics()
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactRigid.prepare()
        impactSoft.prepare()
        notification.prepare()
        selection.prepare()
    }

    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            supportsHaptics = true

            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("❌ Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("⚠️ Haptic engine creation failed: \(error)")
            supportsHaptics = false
        }
    }

    // MARK: - Gameplay Haptics

    /// Called when a move is correctly detected
    func moveDetected(move: String, onBeat: Bool = false) {
        guard isEnabled else { return }

        if onBeat {
            // Special rigid impact for perfect timing
            impactRigid.impactOccurred(intensity: 0.8)
        } else {
            // Light impact for normal move detection
            impactLight.impactOccurred(intensity: 0.6)
        }
    }

    /// Called when wrong move is performed
    func moveIncorrect() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    /// Called when a move is missed (no move when required)
    func moveMissed() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// Called when combo milestone is reached
    func combo(count: Int) {
        guard isEnabled else { return }

        switch count {
        case 5:
            impactLight.impactOccurred(intensity: 0.7)
        case 10:
            impactMedium.impactOccurred(intensity: 0.8)
        case 25:
            impactHeavy.impactOccurred(intensity: 0.9)
        case 50:
            playCustomPattern(.fireworks)
        default:
            if count % 10 == 0 {
                impactMedium.impactOccurred()
            }
        }
    }

    /// Called when combo is broken
    func comboLost() {
        guard isEnabled else { return }
        impactSoft.impactOccurred(intensity: 0.4)
    }

    /// Called when puzzle is completed
    func puzzleCompleted(perfectTiming: Bool = false) {
        guard isEnabled else { return }

        if perfectTiming {
            notification.notificationOccurred(.success)
        } else {
            impactMedium.impactOccurred(intensity: 0.7)
        }
    }

    /// Called when song/session ends
    func sessionCompleted(stars: Int) {
        guard isEnabled else { return }

        switch stars {
        case 3:
            playCustomPattern(.celebration)
        case 2:
            notification.notificationOccurred(.success)
        case 1:
            impactMedium.impactOccurred()
        default:
            impactLight.impactOccurred()
        }
    }

    // MARK: - Achievement Haptics

    /// Called when player levels up
    func levelUp() {
        guard isEnabled else { return }
        playCustomPattern(.levelUp)
    }

    /// Called when star is earned (during results screen)
    func starEarned() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.5)
    }

    /// Called when unlock is granted
    func unlockGranted() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Called when achievement is earned
    func achievementEarned() {
        guard isEnabled else { return }
        playCustomPattern(.achievement)
    }

    // MARK: - UI Haptics

    /// Called on button tap
    func buttonTap() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    /// Called when switching tabs
    func tabChanged() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.3)
    }

    /// Called when slider value changes
    func sliderChanged() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    /// Called when toggle is switched
    func toggleChanged() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.5)
    }

    /// Called when modal sheet appears/disappears
    func modalPresented() {
        guard isEnabled else { return }
        impactMedium.impactOccurred(intensity: 0.4)
    }

    // MARK: - Notification Haptics

    /// Generic success feedback
    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Generic warning feedback
    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// Generic error feedback
    func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    // MARK: - Custom Haptic Patterns (iOS 13+)

    private enum HapticPattern {
        case celebration  // Level up, 3 stars
        case fireworks    // Big combo milestone (50x)
        case levelUp      // Level up animation
        case achievement  // Special unlock
    }

    private func playCustomPattern(_ pattern: HapticPattern) {
        guard supportsHaptics, let engine = hapticEngine else {
            // Fallback to basic haptics
            notification.notificationOccurred(.success)
            return
        }

        let events: [CHHapticEvent]

        switch pattern {
        case .celebration:
            // Three quick bursts
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.15),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.3)
            ]

        case .fireworks:
            // Rapid burst pattern
            events = (0..<5).map { i in
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.6 + Double(i) * 0.08)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: Double(i) * 0.08)
            }

        case .levelUp:
            // Rising intensity pattern
            events = [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0, duration: 0.3),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.35)
            ]

        case .achievement:
            // Two-pulse pattern
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.2)
            ]
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("⚠️ Failed to play custom haptic pattern: \(error)")
            // Fallback
            notification.notificationOccurred(.success)
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension View {
    /// Adds haptic feedback on button tap
    func hapticFeedback(_ style: HapticFeedbackStyle = .selection) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .selection:
                    HapticManager.shared.buttonTap()
                case .light:
                    HapticManager.shared.impactLight.impactOccurred()
                case .medium:
                    HapticManager.shared.impactMedium.impactOccurred()
                case .success:
                    HapticManager.shared.success()
                case .warning:
                    HapticManager.shared.warning()
                case .error:
                    HapticManager.shared.error()
                }
            }
        )
    }
}

enum HapticFeedbackStyle {
    case selection
    case light
    case medium
    case success
    case warning
    case error
}
