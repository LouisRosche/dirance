# Production Readiness Gaps - Move Match

**Current Status:** 95% complete (core functionality)
**Production-Ready Status:** 75% complete (missing polish & enterprise features)

This document outlines critical features needed before App Store launch.

---

## Critical Gaps (Must Fix Before Launch)

### 1. Accessibility Features ⚠️ HIGH PRIORITY
**Status:** Not implemented
**Impact:** App Store rejection risk + excludes 15-20% of potential users

**Missing Features:**
- ❌ VoiceOver support (screen reader)
- ❌ Dynamic Type (adjustable text size)
- ❌ Reduced Motion support (respect system setting)
- ❌ High Contrast mode
- ❌ Color blindness considerations
- ❌ Accessibility labels on all interactive elements
- ❌ Accessibility hints for complex gestures
- ❌ Minimum touch target sizes (44×44 points)

**Implementation Required:**
```swift
// VoiceOver labels
Button("Play") { ... }
    .accessibilityLabel("Start playing selected song")
    .accessibilityHint("Begins gameplay with AR body tracking")

// Dynamic Type
Text("Score: \(score)")
    .font(.system(.title, design: .rounded))
    .dynamicTypeSize(...standardRange)

// Reduced Motion
@Environment(\.accessibilityReduceMotion) var reduceMotion
if reduceMotion {
    // Use simple fade instead of complex animations
}
```

**Effort:** 2-3 days
**Files to modify:** All UI views (7 files)

---

### 2. User Behavior Analytics ⚠️ HIGH PRIORITY
**Status:** Basic Firebase Analytics only
**Impact:** No data for product decisions

**What We Have:**
- ✅ Basic event logging (`song_completed`, `level_up`)
- ✅ Firebase Analytics initialized

**What's Missing:**
- ❌ Comprehensive event taxonomy
- ❌ Funnel tracking (onboarding → first song → retention)
- ❌ A/B testing framework
- ❌ Cohort analysis setup
- ❌ User properties (skill level, favorite genre)
- ❌ Custom conversion events
- ❌ Engagement tracking (session length, frequency)

**Events to Add:**
```swift
// Onboarding Funnel
- onboarding_started
- onboarding_step_completed (step: permissions, calibration, first_song)
- onboarding_abandoned (step: X)
- onboarding_completed (time_taken: 120s)

// Gameplay
- song_started (genre, bpm, difficulty)
- puzzle_attempted (type, difficulty)
- puzzle_completed (accuracy, time_taken)
- move_performed (move_type, was_correct, on_beat)
- combo_achieved (combo_count)
- song_failed (completion_percent)
- song_paused (time_into_song)

// Monetization
- ad_requested (placement: results_screen)
- ad_loaded (network: admob)
- ad_impression
- ad_clicked
- ad_failed (error: no_fill)
- iap_initiated (product_id)
- iap_completed (product_id, revenue, currency)
- iap_cancelled (product_id, step: payment_sheet)

// Engagement
- daily_quest_viewed
- daily_quest_completed (quest_id)
- profile_viewed
- shop_viewed (tab: gems|moves|vip)
- leaderboard_viewed

// Retention
- session_started
- session_ended (duration, songs_played, xp_earned)
- day_N_retention (N: 1, 3, 7, 14, 30)
```

**User Properties:**
```swift
Analytics.setUserProperty("beginner", forName: "skill_level")
Analytics.setUserProperty("electronic", forName: "favorite_genre")
Analytics.setUserProperty("3", forName: "average_stars")
Analytics.setUserProperty("true", forName: "has_vip")
```

**Effort:** 1-2 days
**Files to create:** `Services/Analytics/AnalyticsManager.swift`

---

### 3. Onboarding Tutorial Flow ⚠️ MEDIUM PRIORITY
**Status:** Welcome screen only, no tutorial
**Impact:** Poor D1 retention (users don't understand how to play)

**Current Flow:**
1. Welcome screen with Sign-In
2. Main menu (user is lost)
3. Song selection (no guidance)
4. Gameplay (no instructions on what to do)

**Improved Flow Needed:**
1. Welcome screen
2. **Permission requests with context** (camera, music)
3. **Interactive tutorial** (3-5 steps):
   - Step 1: "Move Match tracks your body with AR"
   - Step 2: "Try a jump!" (detect first jump)
   - Step 3: "Try a squat!" (detect first squat)
   - Step 4: "Complete combos to score points"
   - Step 5: "Let's play your first song!"
4. **First song with hints** (tutorial mode)
5. **Celebration + rewards** (50 coins, 100 XP)
6. Main menu (now with context)

**UI Components Needed:**
```swift
struct TutorialView: View {
    @State private var currentStep = 0
    let steps = [
        TutorialStep(title: "Welcome to Move Match!",
                     description: "Your iPhone camera tracks your dance moves",
                     animation: "camera-tracking"),
        TutorialStep(title: "Try a jump!",
                     description: "Jump up and down to continue",
                     requiredMove: .jump),
        // ... more steps
    ]
}

struct TutorialOverlay: View {
    // Appears during first song
    // Shows arrows pointing to puzzle prompt
    // Highlights score/combo HUD elements
}
```

**Effort:** 2-3 days
**Files to create:** `Features/Tutorial/TutorialView.swift`, `Features/Tutorial/TutorialOverlay.swift`

---

### 4. Haptic Feedback ⚠️ MEDIUM PRIORITY
**Status:** No haptics implemented
**Impact:** Game feels less responsive and polished

**Haptic Moments:**
```swift
import CoreHaptics

// Success haptics
- Move detected correctly: .light impact
- Combo milestone (5x, 10x, 25x): .medium impact
- Level up: .success notification
- Star earned: .light impact
- Perfect timing (on-beat): .rigid impact

// Error haptics
- Missed move: .error notification
- Wrong move: .warning notification

// UI haptics
- Button taps: .selection
- Tab switches: .light impact
- Slider adjustments: .selection (subtle)
```

**Implementation:**
```swift
class HapticManager {
    static let shared = HapticManager()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func success() {
        notification.notificationOccurred(.success)
    }

    func moveDetected() {
        impactLight.impactOccurred()
    }

    func combo(level: Int) {
        if level % 5 == 0 {
            impactMedium.impactOccurred(intensity: 0.8)
        }
    }
}
```

**Effort:** 4-6 hours
**Files to create:** `Services/HapticManager.swift`

---

### 5. Loading States & Skeleton Screens ⚠️ MEDIUM PRIORITY
**Status:** Basic loading spinners only
**Impact:** App feels unresponsive during async operations

**Current Issues:**
- Song analysis shows generic spinner (3-5 seconds wait)
- Music library loads with no feedback
- Firebase queries show blank screens
- No indication of progress

**Improved UX:**
```swift
// Song Selection View
if isLoadingSongs {
    SkeletonSongList()  // Gray placeholder cards
} else {
    SongList(songs)
}

// Song Analysis
ProgressView(value: analysisProgress) {
    VStack {
        Text("Analyzing '\(song.title)'...")
        Text("Detecting BPM, energy, genre...")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// Firebase Queries
if isLoadingProfile {
    ProfileSkeleton()
} else {
    ProfileView(profile)
}
```

**Skeleton Components Needed:**
- `SkeletonSongCard` (shimmer effect)
- `SkeletonProfileView`
- `SkeletonLeaderboard`

**Effort:** 1-2 days
**Files to create:** `UI/Components/SkeletonViews.swift`

---

### 6. Error Handling & Offline Mode ⚠️ HIGH PRIORITY
**Status:** Minimal error handling
**Impact:** App crashes or shows cryptic errors

**Current Problems:**
```swift
// What happens if...
- ❌ No internet connection? (Firebase fails silently)
- ❌ Camera permission denied? (ARKit crashes)
- ❌ No songs in library? (Empty state not handled)
- ❌ Song analysis fails? (User stuck on loading screen)
- ❌ Ad fails to load? (Currently has fallback ✅)
- ❌ IAP purchase fails? (No user feedback)
```

**Needed:**
```swift
// Network Monitoring
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true

    func checkConnection() {
        // Use NWPathMonitor
    }
}

// Offline Mode
- Cache song analysis locally (persist AudioFeatures)
- Queue Firebase writes when offline (sync later)
- Show banner: "Playing offline - progress will sync later"
- Allow gameplay without internet (local mode)

// Graceful Errors
struct ErrorBanner: View {
    let error: AppError
    var retry: (() -> Void)?

    // Shows dismissible banner with retry button
}

enum AppError: LocalizedError {
    case cameraPermissionDenied
    case noSongsInLibrary
    case songAnalysisFailed(reason: String)
    case networkUnavailable
    case firebaseSaveFailed

    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera access is required for body tracking. Enable in Settings."
        // ... user-friendly messages
        }
    }
}
```

**Effort:** 2-3 days
**Files to create:** `Services/NetworkMonitor.swift`, `UI/Components/ErrorBanner.swift`

---

### 7. Sound Effects & Audio Feedback 🔊 LOW PRIORITY
**Status:** No sound effects
**Impact:** Game feels less engaging (but not critical)

**Sound Moments:**
```swift
- Move detected: "swoosh.wav" (subtle, 200ms)
- Correct move: "ding.wav" (pleasant chime)
- Wrong move: "buzz.wav" (soft error sound)
- Combo milestone: "combo-5x.wav", "combo-10x.wav"
- Level up: "level-up.wav" (celebration)
- Star earned: "star.wav" (sparkle sound)
- Button tap: "tap.wav" (minimal, 50ms)
- Puzzle complete: "success.wav"
```

**Implementation:**
```swift
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var players: [String: AVAudioPlayer] = [:]

    func preload() {
        let sounds = ["swoosh", "ding", "buzz", "combo-5x", ...]
        for sound in sounds {
            if let url = Bundle.main.url(forResource: sound, withExtension: "wav") {
                players[sound] = try? AVAudioPlayer(contentsOf: url)
                players[sound]?.prepareToPlay()
            }
        }
    }

    func play(_ sound: String, volume: Float = 1.0) {
        players[sound]?.volume = volume
        players[sound]?.play()
    }
}
```

**Asset Requirements:**
- 8-10 sound effects (~50 KB each)
- Short duration (50-500ms)
- Respect mute switch
- Volume respects system volume

**Effort:** 1-2 days (including finding/creating sounds)
**Files to create:** `Services/SoundManager.swift` + sound assets

---

### 8. Performance Monitoring Dashboard 📊 LOW PRIORITY
**Status:** Crashlytics only
**Impact:** No visibility into performance issues

**What to Track:**
```swift
// Custom performance metrics
- ARKit FPS (target: 30+)
- Memory usage (target: <200 MB)
- Battery drain (target: <15%/hour)
- Song analysis time (target: <5 seconds)
- Network latency (Firebase operations)

// Use Firebase Performance Monitoring
let trace = Performance.startTrace(name: "song_analysis")
// ... analyze song
trace?.stop()

// Custom metrics
trace?.setValue(analysisTime, forMetric: "duration_ms")
trace?.setValue(audioFeatures.bpm, forMetric: "bpm_detected")
```

**Dashboard Views:**
```swift
#if DEBUG
struct PerformanceOverlay: View {
    @ObservedObject var monitor = PerformanceMonitor.shared

    var body: some View {
        VStack(alignment: .leading) {
            Text("FPS: \(monitor.fps)")
            Text("Memory: \(monitor.memoryMB) MB")
            Text("ARKit: \(monitor.arKitStatus)")
        }
        .font(.system(.caption, design: .monospaced))
        .padding(8)
        .background(.black.opacity(0.7))
    }
}
#endif
```

**Effort:** 1-2 days
**Files to create:** `Services/PerformanceMonitor.swift`

---

## Medium Priority Gaps (Nice to Have)

### 9. Settings Screen
**Status:** Not implemented
**What's needed:**
- Volume controls (music, sound effects)
- Difficulty adjustment
- Metric units (calories: kcal or kJ)
- Privacy settings (analytics opt-out)
- Account management (delete account)
- Accessibility settings

**Effort:** 1-2 days

### 10. Social Features
**Status:** Leaderboards only (basic)
**What's missing:**
- Friend system
- Challenge friends
- Share to TikTok (direct integration)
- Share to Instagram Stories
- Replay system (record and share gameplay)

**Effort:** 3-5 days

### 11. Advanced Puzzle Types
**Status:** 5 basic types implemented
**Could add:**
- Mirror mode (reverse left/right)
- Speed mode (2x tempo)
- Endurance mode (no breaks)
- Freestyle mode (no prompts, just track)
- Boss battles (special challenges)

**Effort:** 2-3 days

---

## Low Priority Gaps (Post-Launch)

### 12. Localization
**Status:** English only
**Markets to target:**
- Spanish (LATAM, Spain)
- Portuguese (Brazil)
- Japanese
- Korean
- French
- German

**Effort:** 2-3 days per language

### 13. iPad Support
**Status:** iPhone only
**Challenge:** ARKit body tracking doesn't work on iPad
**Solution:** Alternative control scheme (tap-based rhythm game)

**Effort:** 1-2 weeks

### 14. Apple Watch Companion
**Status:** None
**Features:**
- Heart rate monitoring during gameplay
- Calorie tracking (more accurate)
- Quick stats view
- Remote control (play/pause)

**Effort:** 1 week

---

## Effort Summary

### Must Fix Before Launch (2-3 weeks)
| Feature | Priority | Effort | Impact |
|---------|----------|--------|--------|
| Accessibility | HIGH | 2-3 days | App Store compliance |
| Analytics | HIGH | 1-2 days | Product decisions |
| Error Handling | HIGH | 2-3 days | Stability |
| Haptics | MEDIUM | 4-6 hours | Polish |
| Loading States | MEDIUM | 1-2 days | UX quality |
| Onboarding | MEDIUM | 2-3 days | Retention |
| Sound Effects | LOW | 1-2 days | Engagement |
| Performance | LOW | 1-2 days | Optimization |

**Total:** 12-18 days to production-ready

### Nice to Have (Can ship without)
- Settings screen (1-2 days)
- Social features (3-5 days)
- Advanced puzzles (2-3 days)

### Post-Launch
- Localization (ongoing)
- iPad support (1-2 weeks)
- Apple Watch (1 week)

---

## Recommended Launch Plan

### Option 1: Quick Launch (1 week)
**Ship with:**
- ✅ Core gameplay (done)
- ✅ Basic accessibility (VoiceOver labels only)
- ✅ Minimal analytics (existing Firebase)
- ✅ Error handling (critical paths only)

**Ship without:**
- Haptics
- Sound effects
- Onboarding tutorial
- Performance dashboard

**Risk:** Lower D1 retention, less polished

### Option 2: Polished Launch (2-3 weeks) ⭐ RECOMMENDED
**Ship with:**
- ✅ Core gameplay
- ✅ Full accessibility compliance
- ✅ Comprehensive analytics
- ✅ Complete error handling + offline mode
- ✅ Haptic feedback
- ✅ Loading states
- ✅ Onboarding tutorial

**Ship without:**
- Sound effects (add in v1.1)
- Performance dashboard (internal tool)
- Settings screen (add in v1.1)

**Risk:** Minimal, best chance at success

### Option 3: Feature-Complete Launch (4-6 weeks)
**Ship with:** Everything above plus:
- Sound effects
- Settings screen
- Social features
- Advanced puzzle types

**Risk:** Delayed launch, market opportunity cost

---

## Next Steps

1. **Prioritize** which features are critical for YOUR launch
2. **Implement** in order of priority (start with accessibility)
3. **Test** each feature on real devices
4. **Iterate** based on TestFlight feedback
5. **Launch** when comfortable with quality level

---

**Recommendation:** Aim for **Option 2** (Polished Launch) - 2-3 weeks additional work will dramatically improve chances of success without excessive delay.

**Critical Path:**
1. Accessibility (3 days)
2. Analytics + error handling (3 days)
3. Onboarding tutorial (3 days)
4. Haptics + loading states (2 days)
5. Polish + testing (4 days)

**Total:** ~15 days to truly production-ready

---

**Last Updated:** Oct 25, 2025
