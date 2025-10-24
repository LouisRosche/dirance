# Move Match - Technical Architecture
## Computer Vision Dance-Puzzle Game - iOS Implementation

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS CLIENT                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   SwiftUI    │  │  ARKit +     │  │   AVFoundation│      │
│  │   Interface  │  │  Vision      │  │   Audio       │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘      │
│         │                  │                  │               │
│  ┌──────▼──────────────────▼──────────────────▼────────┐    │
│  │           Game State Manager (Swift)                 │    │
│  │  - Puzzle Logic    - Scoring    - Progression       │    │
│  └──────┬───────────────────────────────────────────────┘    │
│         │                                                     │
└─────────┼─────────────────────────────────────────────────────┘
          │
     HTTPS │ (Firebase SDK)
          │
┌─────────▼─────────────────────────────────────────────────────┐
│                    BACKEND (Firebase + Redis)                  │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │  Firestore  │  │ Remote       │  │  Redis Cloud   │       │
│  │  User Data  │  │ Config       │  │  Leaderboards  │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │ Analytics   │  │ Auth         │  │  AdMob         │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
└────────────────────────────────────────────────────────────────┘
```

---

## 1. Computer Vision System (ARKit + Vision Framework)

### 1.1 Technology Choice: Native iOS vs Unity

**Decision: Native Swift + ARKit for MVP**

| Criteria | Swift + ARKit | Unity + AR Foundation |
|----------|---------------|----------------------|
| Performance | Excellent (native) | Good (overhead) |
| Vision integration | Native, optimized | Requires plugins |
| Build size | 15-25 MB | 40-60 MB |
| Development speed | Slower (build UI) | Faster (editor) |
| Cost | Free | Free <$200K revenue |
| Cross-platform | iOS only | iOS + Android |

**Rationale for Swift:**
- Computer vision is performance-critical
- ARKit body tracking is iOS-native (no Android equivalent)
- Smaller build size = higher download conversion (guide emphasizes ASO)
- Can port to Unity for Android v2.0 if validated

**Future Android Path:**
- ML Kit Pose Detection (Google's equivalent)
- Rebuild in Unity with platform-specific backends
- Estimated: 2-3 month port after iOS success

---

### 1.2 ARKit Body Tracking Implementation

**Requirements:**
- iOS 14+ (ARKit 3.0 for body tracking)
- iPhone with A12+ chip (iPhone XS, XR and newer)
- 2x2 meter play space minimum

**Core Setup:**

```swift
import ARKit
import Vision

class BodyTrackingManager: NSObject, ARSessionDelegate {
    private var arSession = ARSession()
    private var bodyAnchor: ARBodyAnchor?

    // Configure AR session for body tracking
    func startTracking() {
        let configuration = ARBodyTrackingConfiguration()

        // Optimize for performance
        configuration.frameSemantics = .bodyDetection
        configuration.automaticImageScaleEstimation = false

        arSession.delegate = self
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // ARSessionDelegate - receives body pose updates at 60 FPS
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

            // Process skeleton data
            processBodyPose(bodyAnchor)
        }
    }
}
```

**Skeletal Tracking:**
ARBodyAnchor provides 91 joints, but we only need 7 key points:

```swift
enum KeyJoint: String {
    case head = "head_joint"
    case leftShoulder = "left_shoulder_1_joint"
    case rightShoulder = "right_shoulder_1_joint"
    case hips = "hips_joint"
    case leftKnee = "left_leg_joint"
    case rightKnee = "right_leg_joint"
    case leftWrist = "left_hand_joint"
    case rightWrist = "right_hand_joint"
}
```

---

### 1.3 Move Detection Algorithms

**Architecture:**

```swift
class MoveDetector {
    private var baseline: BodyPose?          // Calibration reference
    private var lastDetectionTime: TimeInterval = 0
    private let cooldownDuration: TimeInterval = 0.3  // 300ms debounce

    private var movementHistory: [BodyPose] = []  // 60-frame buffer (1 sec)
    private let historySize = 60

    func detectMove(from pose: BodyPose) -> DetectedMove? {
        // Update history buffer
        movementHistory.append(pose)
        if movementHistory.count > historySize {
            movementHistory.removeFirst()
        }

        // Check cooldown
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastDetectionTime > cooldownDuration else {
            return nil
        }

        // Run detection algorithms in priority order
        if let jump = detectJump(pose) {
            lastDetectionTime = currentTime
            return .jump
        }

        if let squat = detectSquat(pose) {
            lastDetectionTime = currentTime
            return .squat
        }

        // ... other moves

        return nil
    }
}
```

**Jump Detection:**

```swift
func detectJump(_ pose: BodyPose) -> Bool {
    guard let baseline = baseline else { return false }

    // Get hip joint positions
    let currentHipY = pose.joints[.hips]?.position.y ?? 0
    let baselineHipY = baseline.joints[.hips]?.position.y ?? 0

    // Calculate frame height for relative threshold
    let headY = pose.joints[.head]?.position.y ?? 0
    let frameHeight = abs(headY - currentHipY)

    // Jump = hip rises by 20%+ of body height
    let threshold = frameHeight * 0.2
    let displacement = currentHipY - baselineHipY

    // Also check velocity (avoid false positives from camera movement)
    let velocity = calculateVerticalVelocity(movementHistory)

    return displacement > threshold && velocity > 0.5  // m/s
}
```

**Squat Detection:**

```swift
func detectSquat(_ pose: BodyPose) -> Bool {
    // Calculate hip-knee-ankle angle
    guard let hip = pose.joints[.hips]?.position,
          let knee = pose.joints[.leftKnee]?.position,
          let ankle = pose.joints[.leftAnkle]?.position else {
        return false
    }

    let angle = calculateAngle(point1: hip, vertex: knee, point2: ankle)

    // Squat = knee angle 45-110 degrees
    // (too low = sitting, too high = standing)
    let isSquatAngle = angle > 45 && angle < 110

    // Also verify hip dropped (not just knee bend)
    guard let baseline = baseline else { return false }
    let baselineHipY = baseline.joints[.hips]?.position.y ?? 0
    let currentHipY = hip.y
    let hipDropped = currentHipY < baselineHipY - 0.1  // 10cm threshold

    return isSquatAngle && hipDropped
}
```

**Arm Raise Detection:**

```swift
func detectArmRaise(_ pose: BodyPose, side: Side) -> Bool {
    let wristKey: KeyJoint = (side == .left) ? .leftWrist : .rightWrist
    let shoulderKey: KeyJoint = (side == .left) ? .leftShoulder : .rightShoulder

    guard let wrist = pose.joints[wristKey]?.position,
          let shoulder = pose.joints[shoulderKey]?.position,
          let head = pose.joints[.head]?.position else {
        return false
    }

    // Arm raised = wrist is above shoulder AND near head height
    let wristAboveShoulder = wrist.y > shoulder.y + 0.15  // 15cm clearance

    // Verify wrist reached at least 70% to head height
    let shoulderToHead = head.y - shoulder.y
    let shoulderToWrist = wrist.y - shoulder.y
    let percentToHead = shoulderToWrist / shoulderToHead

    return wristAboveShoulder && percentToHead > 0.7
}
```

**Spin Detection (Complex):**

```swift
func detectSpin(_ pose: BodyPose) -> Bool {
    // Track shoulder rotation over time
    guard movementHistory.count >= 30 else { return false }  // Need 0.5sec data

    var rotationAccumulation: Float = 0

    for i in 1..<movementHistory.count {
        let prev = movementHistory[i-1]
        let current = movementHistory[i]

        // Calculate shoulder line rotation
        let prevAngle = shoulderLineAngle(prev)
        let currentAngle = shoulderLineAngle(current)

        var delta = currentAngle - prevAngle

        // Handle 360-degree wraparound
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        rotationAccumulation += delta
    }

    // Full spin = 270+ degrees rotation (allow some leniency)
    return abs(rotationAccumulation) > 270
}

private func shoulderLineAngle(_ pose: BodyPose) -> Float {
    guard let left = pose.joints[.leftShoulder]?.position,
          let right = pose.joints[.rightShoulder]?.position else {
        return 0
    }

    let dx = right.x - left.x
    let dz = right.z - left.z
    return atan2(dz, dx) * 180 / .pi
}
```

---

### 1.4 Calibration & Error Handling

**Pre-Game Calibration (5 seconds):**

```swift
class CalibrationView: View {
    @State private var countdown = 5
    @State private var feedback = "Stand in frame"

    var body: some View {
        ZStack {
            ARViewContainer(onPoseUpdate: { pose in
                // Validate pose quality
                let validation = validatePose(pose)

                switch validation {
                case .tooClose:
                    feedback = "Step back"
                case .tooFar:
                    feedback = "Move closer"
                case .poorLighting:
                    feedback = "Need better lighting"
                case .partialOcclusion:
                    feedback = "Full body must be visible"
                case .good:
                    feedback = "Hold steady..."
                    countdown -= 1
                }
            })

            VStack {
                Text(feedback)
                    .font(.title)
                Text("\(countdown)")
                    .font(.system(size: 72))
            }
        }
    }
}

func validatePose(_ pose: BodyPose) -> PoseQuality {
    // Check all required joints have valid data
    let requiredJoints: [KeyJoint] = [.head, .hips, .leftShoulder, .rightShoulder]
    for joint in requiredJoints {
        guard let data = pose.joints[joint],
              data.confidence > 0.8 else {
            return .partialOcclusion
        }
    }

    // Check distance (optimal = 2-3 meters)
    let headToCamera = pose.joints[.head]!.position.z
    if headToCamera < 1.5 { return .tooClose }
    if headToCamera > 3.5 { return .tooFar }

    // Check lighting (ARKit provides ambient light estimate)
    // ... lighting check logic

    return .good
}
```

**Fallback to Manual Controls:**

```swift
class InputManager {
    var useVisionTracking = true

    func processInput() -> DetectedMove? {
        if useVisionTracking {
            // Try ARKit detection
            if let move = visionDetector.detectMove() {
                return move
            } else if visionQualityPoor() {
                // Auto-fallback after 3 failed detections
                showFallbackPrompt()
            }
        }

        // Manual controls for accessibility / older devices
        return manualInputDetector.checkTouchInput()
    }
}

class ManualInputDetector {
    func checkTouchInput() -> DetectedMove? {
        // On-screen buttons in corners
        // Swipe gestures for direction
        // Tap rhythm for timing
        // Still provides puzzle-solving gameplay
    }
}
```

**Performance Optimization:**

```swift
class VisionOptimizer {
    private var thermalState: ProcessInfo.ThermalState = .nominal
    private var targetFPS = 30

    func optimizeForDevice() {
        // Monitor thermal state
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustPerformance()
        }
    }

    private func adjustPerformance() {
        thermalState = ProcessInfo.processInfo.thermalState

        switch thermalState {
        case .nominal:
            targetFPS = 30
            // Full resolution processing

        case .fair:
            targetFPS = 24
            // Reduce processing resolution

        case .serious:
            targetFPS = 15
            showCoolingWarning()

        case .critical:
            pauseGameAndCool()
        }
    }
}
```

---

## 2. Music Integration System

### 2.1 Apple Music API (User Library Access)

**Setup:**

```swift
import MediaPlayer

class MusicManager {
    func requestAuthorization() async -> Bool {
        let status = await MPMediaLibrary.requestAuthorization()
        return status == .authorized
    }

    func fetchUserSongs() -> [Song] {
        let query = MPMediaQuery.songs()

        // Filter to ensure playable, non-DRM
        let predicate = MPMediaPropertyPredicate(
            value: MPMediaType.music.rawValue,
            forProperty: MPMediaItemPropertyMediaType
        )
        query.addFilterPredicate(predicate)

        guard let items = query.items else { return [] }

        return items.compactMap { item in
            guard let url = item.assetURL else { return nil }  // Skip DRM tracks

            return Song(
                id: item.persistentID,
                title: item.title ?? "Unknown",
                artist: item.artist ?? "Unknown",
                duration: item.playbackDuration,
                assetURL: url,
                bpm: estimateBPM(item)  // Analyze or use metadata
            )
        }
    }
}
```

**BPM Detection (Critical for Puzzle Generation):**

```swift
import AVFoundation

class BPMAnalyzer {
    func analyze(audioURL: URL) async -> Float {
        let asset = AVAsset(url: audioURL)

        // Use AVAudioFile for offline analysis
        guard let audioFile = try? AVAudioFile(forReading: audioURL) else {
            return 120  // Default fallback
        }

        // Read audio buffer
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return 120
        }

        try? audioFile.read(into: buffer)

        // Perform onset detection (beat detection)
        let onsets = detectOnsets(buffer)

        // Calculate median interval between beats
        let intervals = zip(onsets.dropFirst(), onsets).map { $1 - $0 }
        let medianInterval = intervals.sorted()[intervals.count / 2]

        // Convert to BPM
        let bpm = 60.0 / medianInterval

        return Float(bpm)
    }

    private func detectOnsets(_ buffer: AVAudioPCMBuffer) -> [TimeInterval] {
        // Simplified onset detection
        // Production: Use Essentia, Librosa iOS port, or pre-trained ML model

        var onsets: [TimeInterval] = []

        guard let data = buffer.floatChannelData?[0] else { return [] }
        let frameLength = Int(buffer.frameLength)

        let hopSize = 512
        var previousEnergy: Float = 0

        for i in stride(from: 0, to: frameLength, by: hopSize) {
            let endIndex = min(i + hopSize, frameLength)
            var energy: Float = 0

            for j in i..<endIndex {
                energy += abs(data[j])
            }

            // Onset = sudden energy increase
            if energy > previousEnergy * 1.5 {
                let time = TimeInterval(i) / buffer.format.sampleRate
                onsets.append(time)
            }

            previousEnergy = energy
        }

        return onsets
    }
}
```

**Alternative: ShazamKit for Metadata**

```swift
import ShazamKit

class ShazamBPMFetcher {
    func fetchBPM(for song: Song) async -> Float? {
        // Use ShazamKit to get rich metadata (includes tempo)
        let session = SHSession()
        let signature = try? await createSignature(from: song.assetURL)

        guard let signature = signature else { return nil }

        let match = try? await session.match(signature)

        // ShazamKit returns tempo in mediaItems
        return match?.mediaItems.first?.tempo
    }
}
```

---

### 2.2 Audio Playback & Synchronization

**Precise Timing for On-Beat Detection:**

```swift
class AudioEngine {
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?

    private var startTime: TimeInterval = 0
    private var bpm: Float = 120
    private var beatDuration: TimeInterval {
        return 60.0 / Double(bpm)
    }

    func loadSong(_ song: Song) {
        audioFile = try? AVAudioFile(forReading: song.assetURL)

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFile?.processingFormat)

        try? audioEngine.start()
    }

    func play() {
        guard let audioFile = audioFile else { return }

        // Record precise start time
        startTime = CACurrentMediaTime()

        playerNode.scheduleFile(audioFile, at: nil)
        playerNode.play()
    }

    func currentBeat() -> Int {
        let elapsed = CACurrentMediaTime() - startTime
        return Int(elapsed / beatDuration)
    }

    func isOnBeat(tolerance: TimeInterval = 0.15) -> Bool {
        let elapsed = CACurrentMediaTime() - startTime
        let beatPhase = elapsed.truncatingRemainder(dividingBy: beatDuration)

        // On-beat window: ±150ms of beat
        return beatPhase < tolerance || beatPhase > (beatDuration - tolerance)
    }
}
```

---

## 3. Puzzle Generation System

### 3.1 Algorithm Architecture

**Design Goal:** Procedurally generate 3-5 puzzles per song that:
- Match song structure (intensity, drops, bridges)
- Scale difficulty based on user level
- Feel hand-crafted, not random

**Data Structure:**

```swift
struct PuzzleChallenge {
    let id: UUID
    let type: PuzzleType
    let startTime: TimeInterval  // When to show prompt
    let duration: TimeInterval   // Time limit to complete
    let requirements: [MoveRequirement]
    let difficultyMultiplier: Float
}

enum PuzzleType {
    case simpleRepetition     // "Do 5 Jumps"
    case comboSequence        // "Jump → Squat → Arms"
    case timingChallenge      // "Hit 10 on-beat moves"
    case endurance            // "Don't break combo for 30sec"
    case countingChallenge    // "20 total moves before chorus"
}

struct MoveRequirement {
    let move: DetectedMove
    let count: Int
    let mustBeOnBeat: Bool
}
```

**Generation Algorithm:**

```swift
class PuzzleGenerator {
    func generate(for song: Song, userLevel: Int) -> [PuzzleChallenge] {
        var puzzles: [PuzzleChallenge] = []

        // 1. Analyze song structure
        let structure = analyzeSongStructure(song)

        // 2. Determine difficulty curve
        let baseDifficulty = calculateBaseDifficulty(userLevel)

        // 3. Place puzzles at musical landmarks
        for landmark in structure.landmarks {
            let puzzle = createPuzzleFor(
                landmark: landmark,
                difficulty: baseDifficulty,
                userLevel: userLevel
            )
            puzzles.append(puzzle)
        }

        // 4. Ensure variety (no two consecutive same type)
        puzzles = ensureVariety(puzzles)

        return puzzles
    }

    private func analyzeSongStructure(_ song: Song) -> SongStructure {
        // Simplified analysis - production would use ML model

        let intro = 0..<15  // seconds
        let verse1 = 15..<45
        let chorus1 = 45..<75
        let verse2 = 75..<105
        let chorus2 = 105..<135
        let bridge = 135..<155
        let finalChorus = 155..<song.duration

        return SongStructure(
            landmarks: [
                .init(name: "Intro", range: intro, intensity: .low),
                .init(name: "First Chorus", range: chorus1, intensity: .high),
                .init(name: "Bridge", range: bridge, intensity: .medium),
                .init(name: "Final Drop", range: finalChorus, intensity: .extreme)
            ],
            bpm: song.bpm
        )
    }

    private func createPuzzleFor(
        landmark: SongLandmark,
        difficulty: Float,
        userLevel: Int
    ) -> PuzzleChallenge {

        // Match puzzle intensity to music intensity
        let puzzleType: PuzzleType
        let moveCount: Int

        switch landmark.intensity {
        case .low:
            puzzleType = .simpleRepetition
            moveCount = Int(3 * difficulty)  // 3-9 moves

        case .medium:
            puzzleType = .comboSequence
            moveCount = Int(2 * difficulty)  // 2-6 move sequence

        case .high:
            puzzleType = (userLevel > 5) ? .timingChallenge : .countingChallenge
            moveCount = Int(8 * difficulty)

        case .extreme:
            puzzleType = .endurance
            moveCount = 0  // Time-based, not count
        }

        // Select moves based on user's unlocked repertoire
        let availableMoves = getUnlockedMoves(userLevel)
        let selectedMoves = selectMovesFor(
            type: puzzleType,
            count: moveCount,
            from: availableMoves
        )

        return PuzzleChallenge(
            id: UUID(),
            type: puzzleType,
            startTime: landmark.range.lowerBound,
            duration: Double(landmark.range.count),
            requirements: selectedMoves,
            difficultyMultiplier: difficulty
        )
    }

    private func selectMovesFor(
        type: PuzzleType,
        count: Int,
        from available: [DetectedMove]
    ) -> [MoveRequirement] {

        switch type {
        case .simpleRepetition:
            // Repeat single move
            let move = available.randomElement()!
            return [MoveRequirement(move: move, count: count, mustBeOnBeat: false)]

        case .comboSequence:
            // Alternate different moves
            var sequence: [MoveRequirement] = []
            for i in 0..<count {
                let move = available[i % available.count]
                sequence.append(MoveRequirement(move: move, count: 1, mustBeOnBeat: false))
            }
            return sequence

        case .timingChallenge:
            // Any moves, but must be on-beat
            let move = available.randomElement()!
            return [MoveRequirement(move: move, count: count, mustBeOnBeat: true)]

        case .endurance:
            // Any moves, just don't stop
            return []  // Special case handled differently

        case .countingChallenge:
            // Mix of 2-3 moves
            let moves = available.shuffled().prefix(3)
            return moves.map { MoveRequirement(move: $0, count: count / moves.count, mustBeOnBeat: false) }
        }
    }
}
```

---

### 3.2 Adaptive Difficulty System

**Goal:** If player fails 3x, make easier. If player 3-stars 5x in row, make harder.

```swift
class DifficultyAdjuster {
    private var recentResults: [PuzzleResult] = []
    private let historySize = 5

    func adjustDifficulty(after result: PuzzleResult) -> Float {
        recentResults.append(result)
        if recentResults.count > historySize {
            recentResults.removeFirst()
        }

        let failures = recentResults.filter { $0.stars == 0 }.count
        let perfectRuns = recentResults.filter { $0.stars == 3 }.count

        if failures >= 3 {
            return max(0.5, currentDifficulty - 0.2)  // Easier
        }

        if perfectRuns >= 5 {
            return min(2.0, currentDifficulty + 0.3)  // Harder
        }

        return currentDifficulty
    }
}
```

---

## 4. Backend Infrastructure (Firebase + Redis)

### 4.1 Firebase Architecture

**Cost Projection (from Guide):**
- 0-10K users: $0/month (free tier)
- 10K users: $20-30/month
- 100K users: $150-300/month
- 1M users: $2K-4K/month

**Firestore Data Model:**

```
users/
  {userId}/
    profile:
      - displayName: String
      - level: Int
      - totalXP: Int
      - coins: Int (soft currency)
      - gems: Int (hard currency)
      - createdAt: Timestamp
      - lastPlayedAt: Timestamp

    unlocks:
      - moves: [String]  // ["jump", "squat", "doubleJump"]
      - characters: [String]
      - powerUps: [String]
      - songs: [String]

    stats:
      - totalSongsPlayed: Int
      - totalCaloriesBurned: Int
      - totalComboStreak: Int
      - averageStars: Float

    seasonPass:
      - tier: Int (0-30)
      - isPremium: Bool
      - xpProgress: Int
      - seasonId: String

    purchases:
      - transactions: [Transaction]

songs/
  {songId}/
    performances:
      {userId}: {
        - stars: Int
        - score: Int
        - completedPuzzles: Int
        - playedAt: Timestamp
      }

dailyChallenges/
  {date}/
    - challengeType: String
    - requirement: Int
    - rewardXP: Int
    - rewardCoins: Int

seasonPasses/
  {seasonId}/
    - startDate: Timestamp
    - endDate: Timestamp
    - tiers: [TierReward]
```

**Firestore Rules (Security):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId
                   && validateUserUpdate(request.resource.data);
    }

    // Prevent cheating: server validates score increases
    match /users/{userId}/stats/{stat} {
      allow update: if request.auth.uid == userId
                    && request.resource.data.value > resource.data.value
                    && request.resource.data.value < resource.data.value + 10000;
    }

    // Public leaderboard data (read-only)
    match /leaderboards/{board} {
      allow read: if true;
      allow write: if false;  // Cloud Function only
    }
  }
}

function validateUserUpdate(data) {
  // Ensure no hacking of premium currency
  return data.gems == resource.data.gems  // Can't modify gems client-side
      || hasValidPurchaseReceipt();  // Unless receipt provided
}
```

---

### 4.2 Firebase Remote Config (A/B Testing & Live Events)

**Use Cases:**
- Test IAP pricing ($2.99 vs $4.99 Season Pass)
- Adjust puzzle difficulty multipliers without app update
- Schedule limited-time events (2x XP weekend)
- Feature flags (enable new moves for beta users)

**Setup:**

```swift
import FirebaseRemoteConfig

class RemoteConfigManager {
    private let remoteConfig = RemoteConfig.remoteConfig()

    func initialize() async {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600  // 1 hour cache
        remoteConfig.configSettings = settings

        // Set defaults
        remoteConfig.setDefaults([
            "season_pass_price_usd": 4.99,
            "base_difficulty_multiplier": 1.0,
            "enable_spin_move": false,
            "double_xp_event_active": false,
            "rewarded_ad_frequency": 2  // Show after every N songs
        ])

        // Fetch from server
        try? await remoteConfig.fetch()
        try? await remoteConfig.activate()
    }

    func getSeasonPassPrice() -> Float {
        return Float(remoteConfig["season_pass_price_usd"].numberValue)
    }

    func isDoubleXPActive() -> Bool {
        return remoteConfig["double_xp_event_active"].boolValue
    }
}
```

**A/B Test Example:**

```swift
// In Firebase console, create experiment:
// Variant A: season_pass_price_usd = 2.99
// Variant B: season_pass_price_usd = 4.99
// Goal: Maximize revenue_per_user_7d

class IAPManager {
    func getSeasonPassProduct() -> Product {
        let price = RemoteConfigManager.shared.getSeasonPassPrice()

        // Dynamically set price based on A/B test
        return Product(
            id: "season_pass",
            price: price,
            localizedPrice: formatCurrency(price)
        )
    }
}
```

---

### 4.3 Redis Leaderboards (Scalable Rankings)

**Why Redis? (From Guide):**
- Standard SQL: O(n²) complexity - breaks at 100K+ users
- Redis Sorted Sets: O(log n) updates, O(1) rank lookups
- Cost: $0-10/mo for <100K users (Redis Cloud free tier)

**Implementation:**

```swift
// Server-side: Cloud Function (Node.js)
const redis = require('redis');
const client = redis.createClient({
    url: process.env.REDIS_URL
});

async function updateLeaderboard(userId, score, timeframe) {
    const leaderboardKey = `leaderboard:${timeframe}`;  // "daily", "weekly", "alltime"

    // Add/update score (O(log n))
    await client.zAdd(leaderboardKey, {
        score: score,
        value: userId
    });

    // Set expiry for daily/weekly boards
    if (timeframe === 'daily') {
        await client.expire(leaderboardKey, 86400);  // 24 hours
    } else if (timeframe === 'weekly') {
        await client.expire(leaderboardKey, 604800);  // 7 days
    }
}

async function getUserRank(userId, timeframe) {
    const leaderboardKey = `leaderboard:${timeframe}`;

    // Get rank (O(log n))
    const rank = await client.zRevRank(leaderboardKey, userId);

    // Get score (O(1))
    const score = await client.zScore(leaderboardKey, userId);

    return {
        rank: rank + 1,  // Convert 0-indexed to 1-indexed
        score: score
    };
}

async function getTopPlayers(timeframe, limit = 100) {
    const leaderboardKey = `leaderboard:${timeframe}`;

    // Get top N (O(log n + m))
    const topPlayers = await client.zRevRange(leaderboardKey, 0, limit - 1, {
        withScores: true
    });

    return topPlayers;
}
```

**Client-Side (Swift):**

```swift
class LeaderboardManager {
    func fetchLeaderboard(_ timeframe: String) async -> [LeaderboardEntry] {
        // Call Cloud Function
        let functions = Functions.functions()
        let callable = functions.httpsCallable("getLeaderboard")

        let result = try? await callable.call(["timeframe": timeframe])

        // Parse response
        guard let data = result?.data as? [[String: Any]] else { return [] }

        return data.compactMap { dict in
            LeaderboardEntry(
                rank: dict["rank"] as? Int ?? 0,
                userId: dict["userId"] as? String ?? "",
                displayName: dict["name"] as? String ?? "Anonymous",
                score: dict["score"] as? Int ?? 0
            )
        }
    }
}
```

---

## 5. Monetization Integration

### 5.1 AdMob (Rewarded Video - Primary Revenue)

**Setup:**

```swift
import GoogleMobileAds

class AdManager: NSObject, GADFullScreenContentDelegate {
    private var rewardedAd: GADRewardedAd?

    func loadRewardedAd() {
        GADRewardedAd.load(
            withAdUnitID: "ca-app-pub-XXXXXX/YYYYY",
            request: GADRequest()
        ) { [weak self] ad, error in
            if let error = error {
                print("Failed to load ad: \(error)")
                return
            }

            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showRewardedAd(
        from viewController: UIViewController,
        onReward: @escaping (Int) -> Void
    ) {
        guard let ad = rewardedAd else {
            // No ad available - grant reward anyway (good UX)
            onReward(0)
            return
        }

        ad.present(fromRootViewController: viewController) {
            let reward = ad.adReward
            // Double XP, retry with power-up, etc.
            onReward(reward.amount.intValue)
        }
    }

    // Delegate - reload next ad
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadRewardedAd()  // Preload next
    }
}
```

**Strategic Placement (from Guide):**

```swift
class GameFlowManager {
    private var songsPlayedSinceAd = 0
    private let adFrequency = 2  // Configurable via Remote Config

    func onSongComplete(score: Int) {
        songsPlayedSinceAd += 1

        // Offer rewarded ad
        if songsPlayedSinceAd >= adFrequency {
            showRewardedAdOffer()
            songsPlayedSinceAd = 0
        }
    }

    func showRewardedAdOffer() {
        // UI: "Watch video to double your XP?"
        // 80% of users accept this offer (guide data)

        let alert = UIAlertController(
            title: "Bonus XP!",
            message: "Watch a short video to earn 2x XP from this session?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Watch (2x XP)", style: .default) { _ in
            AdManager.shared.showRewardedAd(from: self) { reward in
                self.applyDoubleXP()
            }
        })

        alert.addAction(UIAlertAction(title: "No Thanks", style: .cancel))

        present(alert, animated: true)
    }
}
```

---

### 5.2 In-App Purchases (StoreKit 2)

**Products:**

```swift
enum IAPProduct: String, CaseIterable {
    case gems100 = "com.movematch.gems100"          // $0.99
    case gems500 = "com.movematch.gems500"          // $2.99
    case seasonPass = "com.movematch.seasonpass"    // $4.99
    case vipSubscription = "com.movematch.vip.monthly"  // $9.99/mo
    case removeAds24h = "com.movematch.noads24"     // $1.99

    var displayName: String {
        switch self {
        case .gems100: return "Starter Pack"
        case .gems500: return "Popular Pack"
        case .seasonPass: return "Season Pass"
        case .vipSubscription: return "VIP Membership"
        case .removeAds24h: return "Ad-Free Day Pass"
        }
    }
}
```

**StoreKit 2 Implementation:**

```swift
import StoreKit

class StoreManager: ObservableObject {
    @Published var products: [Product] = []

    private var transactionListener: Task<Void, Error>?

    func loadProducts() async {
        do {
            let productIds = IAPProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Grant entitlement
                await grantEntitlement(for: transaction)

                // Finish transaction
                await transaction.finish()

                return true

            case .userCancelled, .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func grantEntitlement(for transaction: Transaction) async {
        guard let product = IAPProduct(rawValue: transaction.productID) else { return }

        switch product {
        case .gems100:
            await UserManager.shared.addGems(100)
        case .gems500:
            await UserManager.shared.addGems(500)
        case .seasonPass:
            await UserManager.shared.unlockSeasonPass()
        case .vipSubscription:
            await UserManager.shared.activateVIP()
        case .removeAds24h:
            await UserManager.shared.disableAdsFor(hours: 24)
        }

        // Log to Firebase Analytics
        Analytics.logEvent("purchase", parameters: [
            "product_id": product.rawValue,
            "value": transaction.price ?? 0
        ])
    }
}
```

---

## 6. TikTok Integration (Viral Mechanics)

### 6.1 Video Recording System

**Capture Gameplay + Camera Feed:**

```swift
import ReplayKit

class RecordingManager {
    private let recorder = RPScreenRecorder.shared()
    private var videoWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?

    private var startTime: CFTimeInterval?

    func startRecording() {
        guard recorder.isAvailable else { return }

        // Request permission
        recorder.isMicrophoneEnabled = true  // Capture music

        recorder.startCapture { (buffer, bufferType, error) in
            guard error == nil else { return }

            // Write to video file
            self.processBuffer(buffer, type: bufferType)
        }
    }

    func stopRecording() async -> URL? {
        await withCheckedContinuation { continuation in
            recorder.stopCapture { error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                // Finalize video
                self.videoWriter?.finishWriting {
                    continuation.resume(returning: self.videoWriter?.outputURL)
                }
            }
        }
    }
}
```

**AI-Powered Highlight Detection:**

```swift
class HighlightDetector {
    private var comboHistory: [(timestamp: TimeInterval, combo: Int)] = []

    func recordComboEvent(combo: Int, at time: TimeInterval) {
        comboHistory.append((time, combo))
    }

    func findBestMoment(videoURL: URL) -> (start: TimeInterval, duration: TimeInterval) {
        // Find 15-second window with highest combo action

        guard comboHistory.count > 0 else {
            // Fallback: random 15sec from middle
            return (30, 15)
        }

        // Sort by combo value
        let sorted = comboHistory.sorted { $0.combo > $1.combo }
        let peakMoment = sorted.first!

        // Extract 15 seconds centered on peak
        let start = max(0, peakMoment.timestamp - 7.5)

        return (start, 15)
    }
}
```

**Export for TikTok:**

```swift
class TikTokExporter {
    func exportClip(
        videoURL: URL,
        startTime: TimeInterval,
        duration: TimeInterval
    ) async -> URL? {

        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        // Trim to 15-second highlight
        let timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )

        try? composition.insertTimeRange(timeRange, of: asset, at: .zero)

        // Add watermark overlay
        let videoComposition = await addWatermark(to: composition)

        // Export
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPreset1920x1080
        ) else { return nil }

        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mp4

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("movematch_\(UUID().uuidString).mp4")

        exporter.outputURL = outputURL

        await exporter.export()

        return exporter.status == .completed ? outputURL : nil
    }

    private func addWatermark(to composition: AVComposition) async -> AVVideoComposition {
        // Overlay "Move Match" logo in corner
        // Add challenge text ("Beat my 25x combo!")

        let size = CGSize(width: 1080, height: 1920)

        return AVVideoComposition(asset: composition) { request in
            let source = request.sourceImage.clampedToExtent()

            // Add text overlay
            let text = self.createTextOverlay("Play Move Match! #MoveMatchChallenge", size: size)

            let output = source.composited(over: text)
            request.finish(with: output, context: nil)
        }
    }
}
```

**Share Sheet Integration:**

```swift
class SocialShareManager {
    func shareToCommunity(videoURL: URL, score: Int) {
        let caption = """
        I just hit a \(score)x combo in Move Match! Can you beat it? 🔥

        #MoveMatchChallenge #DanceGaming #FitnessGames
        """

        let activityVC = UIActivityViewController(
            activityItems: [caption, videoURL],
            applicationActivities: nil
        )

        // Prioritize TikTok in share sheet (if installed)
        activityVC.excludedActivityTypes = [.assignToContact, .print]

        present(activityVC, animated: true)
    }
}
```

---

## 7. Performance Optimization & Monitoring

### 7.1 Analytics Integration

**Firebase Analytics Events:**

```swift
class AnalyticsManager {
    func logSongPlayed(songId: String, score: Int, stars: Int) {
        Analytics.logEvent("song_played", parameters: [
            "song_id": songId,
            "score": score,
            "stars": stars,
            "duration": 180  // seconds
        ])
    }

    func logPuzzleCompleted(puzzleType: String, difficulty: Float) {
        Analytics.logEvent("puzzle_completed", parameters: [
            "type": puzzleType,
            "difficulty": difficulty
        ])
    }

    func logRetentionMetrics() {
        // Auto-tracked by Firebase:
        // - first_open
        // - session_start
        // - user_engagement

        // Custom:
        Analytics.logEvent("day_7_return", parameters: [:])
    }
}
```

**Key Metrics to Track (from Guide):**
- D1 Retention (target: 35-40%)
- D7 Retention (target: 15-20%)
- ARPDAU (target: $0.12-0.15)
- IAP Conversion (target: 1.5-2%)
- Ad Fill Rate (target: >90%)
- Session Length (target: 10-15min)
- Puzzles Completed per Session (target: 3-5)

---

### 7.2 Crash Reporting & Monitoring

**Firebase Crashlytics:**

```swift
import FirebaseCrashlytics

class ErrorHandler {
    func logNonFatal(_ error: Error, context: String) {
        Crashlytics.crashlytics().record(error: error)
        Crashlytics.crashlytics().log("\(context): \(error.localizedDescription)")
    }

    func setUserContext(userId: String, level: Int) {
        Crashlytics.crashlytics().setUserID(userId)
        Crashlytics.crashlytics().setCustomValue(level, forKey: "user_level")
    }
}
```

**Performance Monitoring:**

```swift
import FirebasePerformance

class PerformanceTracker {
    func trackSongLoad() -> Trace {
        let trace = Performance.startTrace(name: "song_load")
        return trace!
    }

    func trackPuzzleGeneration() -> Trace {
        let trace = Performance.startTrace(name: "puzzle_generation")
        return trace!
    }
}

// Usage
let trace = PerformanceTracker().trackSongLoad()
await loadSongAsync()
trace.stop()  // Reports to Firebase
```

---

## 8. Deployment Checklist

### 8.1 App Store Requirements

**Info.plist Keys:**

```xml
<key>NSCameraUsageDescription</key>
<string>Move Match uses your camera to track your dance moves and create fun workout puzzles!</string>

<key>NSAppleMusicUsageDescription</key>
<string>Access your music library to play songs you love while dancing!</string>

<key>NSMicrophoneUsageDescription</key>
<string>Record your epic dance moments to share with friends!</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your gameplay highlights to share on TikTok!</string>
```

**Privacy Policy (COPPA Compliant):**
- Use TermsFeed generator (free)
- Host at: https://movematch.app/privacy
- Include: data collection, third-party SDKs (AdMob, Firebase), user rights

**Required Metadata:**
- Support URL
- Privacy Policy URL
- Age Rating: 4+ (no COPPA concerns if no social features for <13)

---

### 8.2 TestFlight Beta (Google Play 14-Day Requirement)

**Recruit Testers:**
- Friends/family: 5-10
- Reddit r/TestFlight: post with promo codes
- Beta testing services: BetaFamily ($50 for 20 testers)

**Feedback Focus:**
- ARKit tracking accuracy in different lighting
- Puzzle difficulty curve
- Tutorial clarity
- Monetization friction

---

## 9. Post-Launch Live Ops

### 9.1 Minimal Viable Live Ops (Solo Dev)

**Weekly Schedule (5-10 hours):**

**Monday (2hr):**
- Review weekend analytics
- Check crash reports
- Respond to App Store reviews

**Wednesday (3hr):**
- Update Daily Challenges (via Remote Config - no app update)
- Prepare next week's featured song playlist
- Social media post (TikTok, Reddit)

**Friday (2hr):**
- Monitor KPIs dashboard
- A/B test results analysis
- Plan next month's content

**Monthly (20-30hr):**
- Add 20-30 new curated songs
- Create 1 new move unlock
- Season Pass rollover (new 30-tier rewards)
- Bug fixes + performance improvements

---

### 9.2 Server-Side Events (No App Update Required)

**Firebase Remote Config Schedule:**

```json
{
  "events": [
    {
      "name": "2x XP Weekend",
      "active": true,
      "start": "2025-01-17T00:00:00Z",
      "end": "2025-01-19T23:59:59Z",
      "xp_multiplier": 2.0
    },
    {
      "name": "Lunar New Year Dance Challenge",
      "active": false,
      "featured_songs": ["song_id_1", "song_id_2"],
      "bonus_reward_gems": 100
    }
  ]
}
```

**Client-Side Handling:**

```swift
class EventManager {
    func checkActiveEvents() async {
        await RemoteConfigManager.shared.fetch()

        let events = parseEvents(RemoteConfigManager.shared.get("events"))

        for event in events where event.isActive {
            applyEventModifiers(event)
            showEventBanner(event)
        }
    }
}
```

---

## 10. Cost Summary

| Component | Month 1 | Month 6 (100K users) | Notes |
|-----------|---------|----------------------|-------|
| Firebase | $0 | $150-200 | Firestore, Analytics, Auth |
| Redis Cloud | $0 | $30-50 | Leaderboards |
| Apple Developer | $99/yr | $99/yr | One-time annual |
| Domain | $12/yr | $12/yr | movematch.app |
| Asset subscriptions | $15 | $15 | Epidemic Sound audio |
| **Total** | **~$10/mo** | **~$200/mo** | Scales with revenue |

---

## Next Steps

1. **Week 1-2:** ARKit prototype - validate move detection works
2. **Week 3:** User test with 10 people - 70%+ say "I'd use this" to proceed
3. **Week 4-16:** Build MVP following timeline
4. **Week 17-20:** Beta testing + polish
5. **Week 21:** Launch with $3K marketing budget

**Decision Gate:** If Week 3 validation fails, pivot to simpler mechanic (tap-rhythm instead of computer vision) before investing 4 months.

