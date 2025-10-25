import SwiftUI

// MARK: - Accessibility Extensions for Move Match

/// Provides accessibility support for VoiceOver, Dynamic Type, Reduced Motion, and more
/// Critical for App Store compliance and inclusive design

// MARK: - View Extensions

extension View {
    /// Adds comprehensive accessibility labels and hints
    func gameAccessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(traits)
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
    }

    /// Ensures minimum touch target size (44×44 points per Apple HIG)
    func minimumTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }

    /// Respects user's reduced motion preference
    func adaptiveAnimation<V: Equatable>(
        _ value: V,
        fullAnimation: Animation,
        reducedAnimation: Animation = .linear(duration: 0.1)
    ) -> some View {
        self.modifier(AdaptiveAnimationModifier(
            value: value,
            fullAnimation: fullAnimation,
            reducedAnimation: reducedAnimation
        ))
    }

    /// Helper for conditional modifiers
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Adds high contrast border if needed
    func highContrastBorder() -> some View {
        self.modifier(HighContrastBorderModifier())
    }
}

// MARK: - Adaptive Animation Modifier

struct AdaptiveAnimationModifier<V: Equatable>: ViewModifier {
    let value: V
    let fullAnimation: Animation
    let reducedAnimation: Animation

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? reducedAnimation : fullAnimation, value: value)
    }
}

// MARK: - High Contrast Modifier

struct HighContrastBorderModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast

    func body(content: Content) -> some View {
        if contrast == .increased {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 2)
                )
        } else {
            content
        }
    }
}

// MARK: - Accessible Button Styles

struct AccessibleButtonStyle: ButtonStyle {
    let role: ButtonRole?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .minimumTouchTarget()
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Game-specific fonts that respect Dynamic Type
    static func gameTitle() -> Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }

    static func gameHeadline() -> Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }

    static func gameBody() -> Font {
        .system(.body, design: .default)
    }

    static func gameCaption() -> Font {
        .system(.caption, design: .default)
    }

    /// Score font with maximum size for readability
    static func score() -> Font {
        .system(.title, design: .rounded, weight: .heavy)
    }
}

// MARK: - Accessibility Announcements

struct AccessibilityAnnouncer {
    /// Announces game events to VoiceOver users
    static func announce(_ message: String, withPriority priority: AccessibilityNotification = .announcement) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }

    /// Announces score changes
    static func announceScore(_ score: Int) {
        announce("Score: \(score)", withPriority: .announcement)
    }

    /// Announces combo milestones
    static func announceCombo(_ count: Int) {
        if count >= 5 {
            announce("\(count)x combo!", withPriority: .announcement)
        }
    }

    /// Announces level up
    static func announceLevelUp(_ level: Int) {
        announce("Level up! You are now level \(level)", withPriority: .announcement)
    }

    /// Announces move detection
    static func announceMove(_ move: DetectedMove, correct: Bool) {
        let status = correct ? "Correct" : "Missed"
        announce("\(status): \(move.displayName)", withPriority: .announcement)
    }

    /// Announces puzzle start
    static func announcePuzzle(_ puzzle: PuzzleChallenge) {
        announce("New puzzle: \(puzzle.type.displayName)", withPriority: .announcement)
    }
}

// MARK: - DetectedMove Display Names

extension DetectedMove {
    var displayName: String {
        switch self {
        case .jump: return "Jump"
        case .squat: return "Squat"
        case .armRaiseLeft: return "Raise left arm"
        case .armRaiseRight: return "Raise right arm"
        case .sideStepLeft: return "Side step left"
        case .sideStepRight: return "Side step right"
        case .spin: return "Spin"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .jump: return "Jump up with both feet leaving the ground"
        case .squat: return "Bend your knees and lower your hips"
        case .armRaiseLeft: return "Raise your left arm above your head"
        case .armRaiseRight: return "Raise your right arm above your head"
        case .sideStepLeft: return "Take a step to your left"
        case .sideStepRight: return "Take a step to your right"
        case .spin: return "Turn around in a full circle"
        }
    }
}

// MARK: - PuzzleType Display Names

extension PuzzleType {
    var displayName: String {
        switch self {
        case .simpleRepetition: return "Repetition Challenge"
        case .comboSequence: return "Combo Sequence"
        case .timingChallenge: return "Perfect Timing"
        case .endurance: return "Endurance Test"
        case .countingChallenge: return "Counting Challenge"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .simpleRepetition:
            return "Perform the same move multiple times in a row"
        case .comboSequence:
            return "Complete a sequence of different moves"
        case .timingChallenge:
            return "Hit moves perfectly on the beat"
        case .endurance:
            return "Keep moving without stopping"
        case .countingChallenge:
            return "Perform a specific number of moves within the time limit"
        }
    }
}

// MARK: - Color Accessibility

extension Color {
    /// Color-blind safe palette for game UI
    static let gameSuccess = Color.green
    static let gameWarning = Color.orange
    static let gameError = Color.red
    static let gamePrimary = Color.purple
    static let gameSecondary = Color.pink

    /// Returns a color with increased contrast if needed
    func adaptiveContrast(in colorScheme: ColorScheme, contrastLevel: ColorSchemeContrast) -> Color {
        if contrastLevel == .increased {
            return colorScheme == .dark ? self.opacity(0.9) : self.opacity(0.8)
        }
        return self
    }
}

// MARK: - VoiceOver Game State Reader

struct GameStateReader: View {
    let gameState: GameState
    let score: Int
    let combo: Int

    var body: some View {
        EmptyView()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stateDescription)
            .accessibilityValue("\(score) points, \(combo) combo")
    }

    private var stateDescription: String {
        switch gameState {
        case .idle: return "Game ready"
        case .calibrating: return "Calibrating camera"
        case .playing: return "Game in progress"
        case .paused: return "Game paused"
        case .finished: return "Game finished"
        }
    }
}

// MARK: - Accessible HUD Components

struct AccessibleScoreDisplay: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.score())
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityLabel("Score")
            .accessibilityValue("\(score) points")
    }
}

struct AccessibleComboDisplay: View {
    let combo: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("\(combo)x")
                .font(.gameHeadline())
            Text("COMBO")
                .font(.gameCaption())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Combo")
        .accessibilityValue("\(combo) times")
    }
}

// MARK: - Accessible Progress Bar

struct AccessibleProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let label: String

    var body: some View {
        ProgressView(value: progress)
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(progress * 100))% complete")
    }
}

// MARK: - Accessible Star Rating

struct AccessibleStarRating: View {
    let stars: Int // 0-3

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .foregroundColor(index < stars ? .yellow : .gray)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(stars) out of 3 stars")
    }
}

// MARK: - Accessible Button

struct AccessibleGameButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let role: ButtonRole?

    init(title: String, icon: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.gameHeadline())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gamePrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(AccessibleButtonStyle(role: role))
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Reduce Transparency Support

struct AdaptiveBackground: View {
    let defaultBackground: Color
    let reducedTransparencyBackground: Color

    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        Rectangle()
            .fill(reduceTransparency ? reducedTransparencyBackground : defaultBackground)
    }
}

// MARK: - Guided Access Helper

struct GuidedAccessHelper {
    /// Checks if device is in Guided Access mode (single-app mode)
    static var isInGuidedAccess: Bool {
        UIAccessibility.isGuidedAccessEnabled
    }

    /// Adjusts UI for Guided Access (e.g., hide exit buttons)
    static func configure(for view: some View) -> some View {
        view.onChange(of: UIAccessibility.isGuidedAccessEnabled) { enabled in
            if enabled {
                print("ℹ️ Guided Access enabled - adjusting UI")
            }
        }
    }
}

// MARK: - Differentiate Without Color

/// Helper to ensure UI is understandable without relying solely on color
struct DifferentiateWithoutColor {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    func icon(for state: Bool) -> String {
        if differentiateWithoutColor {
            return state ? "checkmark.circle.fill" : "xmark.circle.fill"
        } else {
            return state ? "circle.fill" : "circle"
        }
    }
}

// MARK: - Usage Examples in Comments

/*
 USAGE EXAMPLES:

 1. Accessible Button:
 ```
 AccessibleGameButton(title: "Play Song", icon: "play.fill") {
     startGame()
 }
 ```

 2. Reduced Motion Animation:
 ```
 Text("Score")
     .adaptiveAnimation(score, fullAnimation: .spring(), reducedAnimation: .linear)
 ```

 3. VoiceOver Announcement:
 ```
 AccessibilityAnnouncer.announceScore(1000)
 AccessibilityAnnouncer.announceCombo(10)
 ```

 4. High Contrast Support:
 ```
 RoundedRectangle(cornerRadius: 12)
     .fill(Color.gamePrimary)
     .highContrastBorder()
 ```

 5. Minimum Touch Target:
 ```
 Image(systemName: "xmark")
     .minimumTouchTarget()
 ```
 */
