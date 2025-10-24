# Move Match - Machine Learning & Neural Network Architecture
## Adaptive Music-to-Puzzle System with Personalized Difficulty

**Version:** 2.0 (Enhanced with ML/AI Layer)
**Author:** Claude Code + Market Insights
**Date:** October 24, 2025

---

## Executive Summary

**The Problem:** Rule-based puzzle generation creates generic experiences that don't adapt to:
- Music characteristics (hip-hop needs different moves than ballet)
- User skill level (beginners frustrated, experts bored)
- Musical structure (drops, bridges, buildups need different challenge types)
- Personal play style (some users love jumps, others prefer arm choreography)

**The ML Solution:** Neural networks that learn to:
1. **Classify music** (genre, mood, energy, tempo) in real-time
2. **Generate style-appropriate puzzles** (EDM → fast jumps, ballad → flowing arms)
3. **Personalize difficulty** (adapt to each user's skill curve)
4. **Predict engagement** (which puzzle types keep THIS user playing)

**The Business Impact:**
- **+15-25% retention** (personalized content sticks better)
- **+20% session length** (optimal challenge = flow state)
- **Competitive moat** (hard to copy, improves with data)
- **Premium positioning** ("AI-powered choreography" in ASO)

**Implementation Strategy:**
- **MVP (Launch):** Rule-based with basic audio analysis (0 ML cost)
- **v1.1 (Month 3):** Pre-trained Core ML models (free, on-device)
- **v1.5 (Month 6):** Cloud-based custom models (Google Vertex AI, $50-200/mo)
- **v2.0 (Year 2):** User behavior neural nets + reinforcement learning

---

## Phase 1: MVP (Launch) - Rule-Based Foundation

### Why Start Without ML?

**From the market guide:**
> "First games should validate core loop before adding complexity. Ship fast, iterate based on data."

**MVP Strategy:** Build a **smart rule-based system** that LOOKS like ML but uses deterministic logic. This lets us:
- Launch in 5-6 months (ML training would add 2-3 months)
- Collect real user data for training later
- Validate the core mechanic before expensive ML investment

---

### Audio Feature Extraction (No ML Required)

**Use AVFoundation + Accelerate Framework** (Apple's DSP library, free)

```swift
import AVFoundation
import Accelerate

class AudioAnalyzer {
    struct AudioFeatures {
        let bpm: Float              // Beats per minute
        let energy: Float           // 0-1, how "intense" the song is
        let danceability: Float     // 0-1, how rhythmic/danceable
        let spectralCentroid: Float // Brightness (low = bass, high = treble)
        let onsets: [TimeInterval]  // Beat positions
    }

    func analyze(audioURL: URL) async -> AudioFeatures {
        let audioFile = try! AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        try! audioFile.read(into: buffer)

        // Extract features using DSP
        let bpm = detectBPM(buffer)
        let energy = calculateEnergy(buffer)
        let danceability = calculateDanceability(buffer)
        let spectralCentroid = calculateSpectralCentroid(buffer)
        let onsets = detectOnsets(buffer)

        return AudioFeatures(
            bpm: bpm,
            energy: energy,
            danceability: danceability,
            spectralCentroid: spectralCentroid,
            onsets: onsets
        )
    }

    private func detectBPM(_ buffer: AVAudioPCMBuffer) -> Float {
        // Auto-correlation method for tempo detection
        guard let data = buffer.floatChannelData?[0] else { return 120 }
        let frameLength = Int(buffer.frameLength)

        var maxCorrelation: Float = 0
        var bestLag = 0

        // Search for periodicity between 60-180 BPM
        let sampleRate = buffer.format.sampleRate
        let minLag = Int(sampleRate * 60 / 180)  // 180 BPM
        let maxLag = Int(sampleRate * 60 / 60)   // 60 BPM

        for lag in minLag..<maxLag {
            var correlation: Float = 0
            for i in 0..<(frameLength - lag) {
                correlation += data[i] * data[i + lag]
            }

            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestLag = lag
            }
        }

        let bpm = Float(60.0 * sampleRate / Double(bestLag))
        return bpm
    }

    private func calculateEnergy(_ buffer: AVAudioPCMBuffer) -> Float {
        // RMS (Root Mean Square) energy
        guard let data = buffer.floatChannelData?[0] else { return 0.5 }
        let frameLength = Int(buffer.frameLength)

        var energy: Float = 0
        for i in 0..<frameLength {
            energy += data[i] * data[i]
        }
        energy = sqrt(energy / Float(frameLength))

        // Normalize to 0-1 (typical range is 0-0.5)
        return min(energy * 2, 1.0)
    }

    private func calculateDanceability(_ buffer: AVAudioPCMBuffer) -> Float {
        // Simplified: measure beat regularity + energy in bass frequencies
        let bpm = detectBPM(buffer)
        let energy = calculateEnergy(buffer)

        // Regular tempo (100-140 BPM) = more danceable
        let tempoScore = 1.0 - abs(bpm - 120) / 120

        // High energy = more danceable
        let energyScore = energy

        return (tempoScore * 0.4 + energyScore * 0.6)
    }

    private func calculateSpectralCentroid(_ buffer: AVAudioPCMBuffer) -> Float {
        // FFT to analyze frequency content
        guard let data = buffer.floatChannelData?[0] else { return 0.5 }
        let frameLength = Int(buffer.frameLength)

        // Use Accelerate for FFT
        let log2n = vDSP_Length(ceil(log2(Float(frameLength))))
        let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!

        var realp = [Float](repeating: 0, count: frameLength / 2)
        var imagp = [Float](repeating: 0, count: frameLength / 2)

        realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(
                    realp: realBuffer.baseAddress!,
                    imagp: imagBuffer.baseAddress!
                )

                data.withMemoryRebound(to: DSPComplex.self, capacity: frameLength / 2) { complexData in
                    vDSP_ctoz(complexData, 2, &splitComplex, 1, vDSP_Length(frameLength / 2))
                }

                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                // Calculate magnitude spectrum
                var magnitudes = [Float](repeating: 0, count: frameLength / 2)
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(frameLength / 2))

                // Spectral centroid = weighted mean of frequencies
                var weightedSum: Float = 0
                var sumMagnitudes: Float = 0

                for i in 0..<magnitudes.count {
                    weightedSum += Float(i) * magnitudes[i]
                    sumMagnitudes += magnitudes[i]
                }

                vDSP_destroy_fftsetup(fftSetup)

                let centroid = weightedSum / sumMagnitudes

                // Normalize to 0-1 (0 = bass-heavy, 1 = treble-heavy)
                return min(centroid / Float(magnitudes.count), 1.0)
            }
        }

        return 0.5  // Fallback
    }
}
```

---

### Rule-Based Puzzle Generation (Smart Heuristics)

**Map Audio Features → Puzzle Characteristics:**

```swift
class RuleBasedPuzzleGenerator {

    func generatePuzzles(for song: Song, features: AudioFeatures, userLevel: Int) -> [PuzzleChallenge] {

        let style = classifyMusicStyle(features)
        let intensity = calculateIntensity(features)
        let difficulty = calculateDifficulty(userLevel, intensity)

        var puzzles: [PuzzleChallenge] = []

        // Genre-specific puzzle generation
        switch style {
        case .electronic:
            puzzles = generateElectronicPuzzles(features, difficulty)
        case .hiphop:
            puzzles = generateHipHopPuzzles(features, difficulty)
        case .pop:
            puzzles = generatePopPuzzles(features, difficulty)
        case .rock:
            puzzles = generateRockPuzzles(features, difficulty)
        case .classical:
            puzzles = generateClassicalPuzzles(features, difficulty)
        case .latin:
            puzzles = generateLatinPuzzles(features, difficulty)
        }

        return puzzles
    }

    enum MusicStyle {
        case electronic, hiphop, pop, rock, classical, latin
    }

    private func classifyMusicStyle(_ features: AudioFeatures) -> MusicStyle {
        // Rule-based classification using audio features

        let bpm = features.bpm
        let energy = features.energy
        let spectralCentroid = features.spectralCentroid
        let danceability = features.danceability

        // Electronic: High energy, high BPM, bright treble
        if energy > 0.7 && bpm > 120 && spectralCentroid > 0.6 {
            return .electronic
        }

        // Hip-hop: Medium BPM (80-110), bass-heavy, high danceability
        if bpm > 80 && bpm < 110 && spectralCentroid < 0.4 && danceability > 0.6 {
            return .hiphop
        }

        // Classical: Low energy, wide BPM range, complex structure
        if energy < 0.4 && danceability < 0.4 {
            return .classical
        }

        // Latin: 100-130 BPM, high danceability, syncopated rhythms
        if bpm > 100 && bpm < 130 && danceability > 0.7 {
            return .latin
        }

        // Rock: High energy, 120-140 BPM, aggressive
        if energy > 0.6 && bpm > 110 && bpm < 150 {
            return .rock
        }

        // Default to pop
        return .pop
    }

    private func generateElectronicPuzzles(_ features: AudioFeatures, _ difficulty: Float) -> [PuzzleChallenge] {
        // Electronic music: Fast jumps, arm raises, spins on drops

        var puzzles: [PuzzleChallenge] = []

        // Intro: Simple repetition
        puzzles.append(PuzzleChallenge(
            type: .simpleRepetition,
            startTime: 0,
            duration: 15,
            requirements: [
                MoveRequirement(move: .jump, count: Int(5 * difficulty), mustBeOnBeat: true)
            ]
        ))

        // Buildup: Increasing intensity
        puzzles.append(PuzzleChallenge(
            type: .comboSequence,
            startTime: 30,
            duration: 20,
            requirements: [
                MoveRequirement(move: .armRaiseLeft, count: 1, mustBeOnBeat: true),
                MoveRequirement(move: .armRaiseRight, count: 1, mustBeOnBeat: true),
                MoveRequirement(move: .jump, count: 1, mustBeOnBeat: true)
            ]
        ))

        // Drop: Explosive movement
        let dropTime = findDrop(features.onsets, songDuration: 180)
        puzzles.append(PuzzleChallenge(
            type: .timingChallenge,
            startTime: dropTime,
            duration: 30,
            requirements: [
                MoveRequirement(move: .spin, count: Int(3 * difficulty), mustBeOnBeat: false)
            ]
        ))

        return puzzles
    }

    private func generateHipHopPuzzles(_ features: AudioFeatures, _ difficulty: Float) -> [PuzzleChallenge] {
        // Hip-hop: Groovy, syncopated, emphasize sidestepping and arm movements

        return [
            PuzzleChallenge(
                type: .comboSequence,
                startTime: 10,
                duration: 30,
                requirements: [
                    MoveRequirement(move: .sideStepLeft, count: 2, mustBeOnBeat: true),
                    MoveRequirement(move: .sideStepRight, count: 2, mustBeOnBeat: true),
                    MoveRequirement(move: .armRaiseLeft, count: 1, mustBeOnBeat: false)
                ]
            ),
            PuzzleChallenge(
                type: .countingChallenge,
                startTime: 60,
                duration: 45,
                requirements: [
                    MoveRequirement(move: .squat, count: Int(10 * difficulty), mustBeOnBeat: false)
                ]
            )
        ]
    }

    private func generateClassicalPuzzles(_ features: AudioFeatures, _ difficulty: Float) -> [PuzzleChallenge] {
        // Classical: Flowing, graceful arm movements, fewer jumps

        return [
            PuzzleChallenge(
                type: .comboSequence,
                startTime: 0,
                duration: 60,
                requirements: [
                    MoveRequirement(move: .armRaiseLeft, count: 1, mustBeOnBeat: false),
                    MoveRequirement(move: .armRaiseRight, count: 1, mustBeOnBeat: false),
                    // Alternate slowly
                ]
            ),
            PuzzleChallenge(
                type: .endurance,
                startTime: 90,
                duration: 60,
                requirements: []  // Just maintain smooth movement
            )
        ]
    }

    private func findDrop(_ onsets: [TimeInterval], songDuration: TimeInterval) -> TimeInterval {
        // Find the moment with biggest onset strength (the "drop")
        // Typically around 50-70% through the song in EDM

        let searchStart = songDuration * 0.4
        let searchEnd = songDuration * 0.7

        let candidateOnsets = onsets.filter { $0 > searchStart && $0 < searchEnd }

        // Return middle of search range if no strong onset found
        return candidateOnsets.first ?? (searchStart + searchEnd) / 2
    }
}
```

**MVP Outcome:** Puzzles adapt to music style WITHOUT ML, giving us training data for Phase 2.

---

## Phase 2: v1.1 (Month 3) - Core ML Pre-Trained Models

### Why Core ML?

**Advantages:**
- ✅ Runs **on-device** (zero cloud costs, works offline)
- ✅ Apple's **optimized** for iPhone hardware (fast, battery-efficient)
- ✅ **Pre-trained models** available (no training required)
- ✅ Privacy-friendly (no data sent to servers)

**Limitations:**
- ❌ Limited to Apple's model zoo (can't customize easily)
- ❌ iOS-only (Android requires TensorFlow Lite)
- ❌ Fixed models (don't improve with your user data)

---

### Implementation: Music Genre Classification

**Use Apple's Sound Classification Model** (free, pre-trained on 300+ audio classes)

```swift
import CoreML
import SoundAnalysis

class MLMusicClassifier {

    private let soundClassifier: SNClassifySoundRequest

    init() {
        // Use Apple's pre-trained sound classifier
        // Trained on 300+ classes including music genres
        let modelConfig = MLModelConfiguration()

        do {
            // Option 1: Use built-in sound classifier
            let model = try SNClassifierIdentifier.version1
            soundClassifier = try SNClassifySoundRequest(classifierIdentifier: model)

            // Option 2: Use custom Core ML model (if we train one later)
            // let customModel = try MusicGenreClassifier(configuration: modelConfig)
            // soundClassifier = try SNClassifySoundRequest(mlModel: customModel.model)

        } catch {
            fatalError("Failed to load sound classifier: \(error)")
        }
    }

    func classifyGenre(audioURL: URL) async -> MusicGenre {

        let audioFile = try! AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat

        return await withCheckedContinuation { continuation in

            let analyzer = SNAudioFileAnalyzer(url: audioURL)

            let observer = GenreObserver { genre in
                continuation.resume(returning: genre)
            }

            try? analyzer.add(soundClassifier, withObserver: observer)
            analyzer.analyze()
        }
    }
}

class GenreObserver: NSObject, SNResultsObserving {

    private let completion: (MusicGenre) -> Void

    init(completion: @escaping (MusicGenre) -> Void) {
        self.completion = completion
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {

        guard let result = result as? SNClassificationResult else { return }

        // Get top classification
        let topClassification = result.classifications.first!
        let identifier = topClassification.identifier
        let confidence = topClassification.confidence

        // Map Apple's classifications to our genres
        let genre = mapToGenre(identifier, confidence: confidence)

        completion(genre)
    }

    private func mapToGenre(_ identifier: String, confidence: Double) -> MusicGenre {
        // Apple's classifier outputs like "music_electronic", "music_rock", etc.

        if identifier.contains("electronic") || identifier.contains("techno") {
            return .electronic
        } else if identifier.contains("hip_hop") || identifier.contains("rap") {
            return .hiphop
        } else if identifier.contains("rock") || identifier.contains("metal") {
            return .rock
        } else if identifier.contains("classical") || identifier.contains("orchestra") {
            return .classical
        } else if identifier.contains("latin") || identifier.contains("salsa") {
            return .latin
        } else {
            return .pop  // Default
        }
    }
}

enum MusicGenre {
    case electronic, hiphop, pop, rock, classical, latin, jazz, country
}
```

---

### Enhanced Puzzle Generation with ML Classification

```swift
class MLEnhancedPuzzleGenerator {

    private let mlClassifier = MLMusicClassifier()
    private let audioAnalyzer = AudioAnalyzer()

    func generatePuzzles(for song: Song, userLevel: Int) async -> [PuzzleChallenge] {

        // Get both ML classification AND audio features
        async let genre = mlClassifier.classifyGenre(audioURL: song.assetURL)
        async let features = audioAnalyzer.analyze(audioURL: song.assetURL)

        let (detectedGenre, audioFeatures) = await (genre, features)

        // Combine ML + rule-based for best results
        let puzzles = generateStyleAwarePuzzles(
            genre: detectedGenre,
            features: audioFeatures,
            userLevel: userLevel
        )

        return puzzles
    }

    private func generateStyleAwarePuzzles(
        genre: MusicGenre,
        features: AudioFeatures,
        userLevel: Int
    ) -> [PuzzleChallenge] {

        // Genre-specific move preferences
        let moveProfile = getMoveProfileFor(genre)

        // Generate puzzles using preferred moves for this genre
        var puzzles: [PuzzleChallenge] = []

        // Intro puzzle (0-15 seconds)
        puzzles.append(createIntroPuzzle(
            preferredMoves: moveProfile.introMoves,
            features: features,
            difficulty: Float(userLevel)
        ))

        // Verse puzzles (15-60 seconds)
        puzzles.append(contentsOf: createVersePuzzles(
            preferredMoves: moveProfile.verseMoves,
            features: features,
            difficulty: Float(userLevel)
        ))

        // Chorus/drop puzzle (60-90 seconds)
        puzzles.append(createChorusPuzzle(
            preferredMoves: moveProfile.chorusMoves,
            features: features,
            difficulty: Float(userLevel)
        ))

        return puzzles
    }

    struct MoveProfile {
        let introMoves: [DetectedMove]
        let verseMoves: [DetectedMove]
        let chorusMoves: [DetectedMove]
        let tempo: PuzzleTempo
    }

    enum PuzzleTempo {
        case slow, moderate, fast, explosive
    }

    private func getMoveProfileFor(_ genre: MusicGenre) -> MoveProfile {
        switch genre {

        case .electronic:
            return MoveProfile(
                introMoves: [.armRaiseLeft, .armRaiseRight],
                verseMoves: [.jump, .sideStepLeft, .sideStepRight],
                chorusMoves: [.spin, .jump, .armRaiseLeft, .armRaiseRight],
                tempo: .explosive
            )

        case .hiphop:
            return MoveProfile(
                introMoves: [.sideStepLeft, .sideStepRight],
                verseMoves: [.squat, .sideStepLeft, .sideStepRight, .armRaiseLeft],
                chorusMoves: [.squat, .armRaiseLeft, .armRaiseRight],
                tempo: .moderate
            )

        case .classical:
            return MoveProfile(
                introMoves: [.armRaiseLeft, .armRaiseRight],
                verseMoves: [.armRaiseLeft, .armRaiseRight, .sideStepLeft],
                chorusMoves: [.armRaiseLeft, .armRaiseRight, .spin],
                tempo: .slow
            )

        case .latin:
            return MoveProfile(
                introMoves: [.sideStepLeft, .sideStepRight],
                verseMoves: [.sideStepLeft, .sideStepRight, .armRaiseLeft, .spin],
                chorusMoves: [.spin, .sideStepLeft, .sideStepRight, .jump],
                tempo: .fast
            )

        case .rock:
            return MoveProfile(
                introMoves: [.jump, .armRaiseLeft],
                verseMoves: [.jump, .squat, .armRaiseLeft, .armRaiseRight],
                chorusMoves: [.jump, .spin, .armRaiseLeft, .armRaiseRight],
                tempo: .fast
            )

        default:  // Pop
            return MoveProfile(
                introMoves: [.armRaiseLeft, .jump],
                verseMoves: [.jump, .squat, .sideStepLeft, .sideStepRight],
                chorusMoves: [.jump, .armRaiseLeft, .armRaiseRight, .spin],
                tempo: .moderate
            )
        }
    }
}
```

**v1.1 Outcome:**
- **Improved puzzle variety:** Each genre feels distinct
- **Zero cloud costs:** Everything runs on-device
- **Better retention:** Users notice songs feel "choreographed correctly"

---

## Phase 3: v1.5 (Month 6) - Custom Cloud ML Models

### Why Custom Models?

By Month 6, we have **real user data**:
- 50,000+ song analyses
- 500,000+ puzzle completions
- User ratings ("this puzzle fit the music perfectly" vs "this felt wrong")

**We can now train models that:**
1. Predict which puzzle types work best for specific songs
2. Learn user preferences (this player loves jumps, hates squats)
3. Optimize for engagement (which combos keep people playing?)

---

### Cloud ML Platform: Google Vertex AI

**Why Vertex AI (vs AWS SageMaker, Azure ML):**
- ✅ **AutoML** (no PhD required - point-and-click model training)
- ✅ **Pay-per-prediction** pricing (cheap at low scale)
- ✅ **Easy integration** with Firebase (same Google ecosystem)
- ✅ **Pre-built pipelines** for audio analysis

**Cost Estimates:**
- Training: $20-50 per model (one-time)
- Predictions: $0.01-0.05 per song analysis
- Monthly at 50K DAU: $150-300/mo (vs $0 for Core ML)

**Trade-off:** Spend $150-300/mo to get 15-25% better retention = $2K-5K extra monthly revenue.

---

### Custom Model #1: Puzzle-Song Matching Neural Network

**Goal:** Predict optimal puzzle characteristics for any song

**Architecture:**

```
Input Layer (Audio Features):
├─ BPM (float)
├─ Energy (float 0-1)
├─ Danceability (float 0-1)
├─ Spectral Centroid (float 0-1)
├─ Genre (one-hot encoded, 8 categories)
├─ Song Duration (float)
└─ Onset Density (float, beats per second)

Hidden Layers:
├─ Dense(128, activation='relu')
├─ Dropout(0.3)
├─ Dense(64, activation='relu')
└─ Dropout(0.2)

Output Layer (Puzzle Characteristics):
├─ Recommended Move Types (multi-label, 7 moves)
├─ Puzzle Tempo (classification: slow/moderate/fast/explosive)
├─ Combo Length (regression: 2-10)
├─ On-Beat Strictness (float 0-1)
└─ Puzzle Density (float, puzzles per minute)
```

**Training Data Collection:**

```swift
// During gameplay, log every puzzle completion
class TelemetryLogger {

    func logPuzzleCompletion(
        songFeatures: AudioFeatures,
        puzzleConfig: PuzzleChallenge,
        userRating: Float,  // Implicit: 1.0 = completed, 0.5 = partial, 0.0 = skipped
        sessionMetrics: SessionMetrics
    ) {

        // Send to Firebase for later ML training
        let trainingExample = [
            "song_bpm": songFeatures.bpm,
            "song_energy": songFeatures.energy,
            "song_danceability": songFeatures.danceability,
            "song_spectral_centroid": songFeatures.spectralCentroid,

            "puzzle_type": puzzleConfig.type.rawValue,
            "puzzle_moves": puzzleConfig.requirements.map { $0.move.rawValue },
            "puzzle_difficulty": puzzleConfig.difficultyMultiplier,
            "puzzle_on_beat_required": puzzleConfig.requirements.first?.mustBeOnBeat ?? false,

            "user_rating": userRating,
            "completion_time": sessionMetrics.completionTime,
            "combo_achieved": sessionMetrics.maxCombo,
            "user_level": sessionMetrics.userLevel,

            "timestamp": Date().timeIntervalSince1970
        ]

        // Log to Firebase (free tier: 10GB/month)
        Analytics.logEvent("ml_training_example", parameters: trainingExample)

        // Also log to BigQuery for ML training (costs $5/TB queried)
        // Vertex AI AutoML can ingest directly from BigQuery
    }
}
```

**Model Training (Vertex AI AutoML):**

```python
# Run this in Google Cloud Console or Colab (Month 6, when we have data)

from google.cloud import aiplatform

# Initialize Vertex AI
aiplatform.init(project='move-match', location='us-central1')

# Create dataset from BigQuery
dataset = aiplatform.TabularDataset.create(
    display_name='puzzle_song_matching_v1',
    bq_source='bq://move-match.analytics.puzzle_completions',
)

# Define training job (AutoML = easy mode)
job = aiplatform.AutoMLTabularTrainingJob(
    display_name='puzzle_predictor_model',
    optimization_prediction_type='classification',  # or 'regression' for continuous outputs
    optimization_objective='minimize-log-loss',
)

# Train model (takes 2-4 hours, costs $20-50)
model = job.run(
    dataset=dataset,
    target_column='user_rating',  # What we're predicting
    training_fraction_split=0.8,
    validation_fraction_split=0.1,
    test_fraction_split=0.1,
    budget_milli_node_hours=1000,  # $20-30 training cost
    model_display_name='puzzle_song_matcher_v1',
)

# Deploy model to endpoint (costs $0.50/hour uptime)
endpoint = model.deploy(
    machine_type='n1-standard-2',
    min_replica_count=1,
    max_replica_count=3,  # Auto-scales with traffic
)

print(f'Model deployed to: {endpoint.resource_name}')
```

**Using the Model in Production:**

```swift
class CloudMLPuzzleGenerator {

    private let vertexAIEndpoint = "https://us-central1-aiplatform.googleapis.com/v1/projects/move-match/locations/us-central1/endpoints/123456"

    func generatePuzzles(for song: Song, features: AudioFeatures) async -> [PuzzleChallenge] {

        // Call Vertex AI endpoint
        let prediction = await predictOptimalPuzzle(features)

        // Use ML predictions to guide puzzle generation
        let puzzles = buildPuzzlesFromPrediction(prediction, song: song)

        return puzzles
    }

    private func predictOptimalPuzzle(_ features: AudioFeatures) async -> PuzzlePrediction {

        let requestBody: [String: Any] = [
            "instances": [[
                "bpm": features.bpm,
                "energy": features.energy,
                "danceability": features.danceability,
                "spectral_centroid": features.spectralCentroid,
                // ... other features
            ]]
        ]

        // Call Vertex AI REST API
        let url = URL(string: vertexAIEndpoint + ":predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try! await URLSession.shared.data(for: request)
        let response = try! JSONDecoder().decode(VertexAIPredictionResponse.self, from: data)

        return PuzzlePrediction(
            recommendedMoves: response.predictions[0].moves,
            tempo: response.predictions[0].tempo,
            comboLength: response.predictions[0].comboLength,
            onBeatStrictness: response.predictions[0].onBeatStrictness
        )
    }
}

struct PuzzlePrediction {
    let recommendedMoves: [DetectedMove]
    let tempo: PuzzleTempo
    let comboLength: Int
    let onBeatStrictness: Float
}
```

**v1.5 Outcome:**
- **Puzzles feel "choreographed"** instead of random
- **15% retention improvement** (ML-generated puzzles fit better)
- **$150-300/mo cost** (but generates $2K+ extra revenue)

---

### Custom Model #2: User Preference Learning

**Goal:** Learn each user's personal preferences and adapt puzzles

**Architecture:**

```
Input Layer (User History):
├─ User Level (int)
├─ Total Songs Played (int)
├─ Favorite Genres (multi-hot, from listening history)
├─ Move Success Rates (7 floats, % success for each move type)
├─ Preferred Combo Length (int, average they complete)
├─ Play Style (derived: cautious/balanced/aggressive)
└─ Recent Session Metrics (array of last 10 sessions)

Embedding Layer:
└─ User Embedding (64 dimensions, learned representation)

Hidden Layers:
├─ LSTM(128) - for sequential pattern learning
├─ Dense(64, activation='relu')
└─ Dropout(0.3)

Output Layer:
├─ Personalized Difficulty Multiplier (regression, 0.5-2.0)
├─ Move Preferences (7 floats, weight for each move type)
└─ Optimal Puzzle Frequency (puzzles per minute for THIS user)
```

**Implementation:**

```swift
class PersonalizedDifficultyAdjuster {

    func getPersonalizedMultiplier(userId: String, song: Song) async -> Float {

        // Fetch user's historical performance
        let userHistory = await fetchUserHistory(userId)

        // Call ML model
        let prediction = await predictPersonalizedDifficulty(userHistory, song)

        return prediction.difficultyMultiplier
    }

    private func fetchUserHistory(_ userId: String) async -> UserHistory {
        // Query Firestore for user's past 100 sessions
        let db = Firestore.firestore()
        let snapshot = try! await db.collection("users/\(userId)/sessions")
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments()

        // Calculate aggregate stats
        var successRates: [DetectedMove: Float] = [:]
        var avgComboLength: Float = 0

        for doc in snapshot.documents {
            let data = doc.data()

            // Move success rates
            if let moves = data["moves_attempted"] as? [String: Int],
               let successes = data["moves_succeeded"] as? [String: Int] {
                for (move, attempts) in moves {
                    let success = Float(successes[move] ?? 0) / Float(attempts)
                    successRates[DetectedMove(rawValue: move)!] = success
                }
            }

            // Combo preferences
            if let combo = data["max_combo"] as? Int {
                avgComboLength += Float(combo)
            }
        }

        avgComboLength /= Float(snapshot.documents.count)

        return UserHistory(
            successRates: successRates,
            preferredComboLength: Int(avgComboLength),
            totalSongs: snapshot.documents.count,
            favoriteGenres: []  // TODO: infer from song history
        )
    }

    private func predictPersonalizedDifficulty(_ history: UserHistory, _ song: Song) async -> PersonalizationPrediction {

        // Call Vertex AI personalization model
        let requestBody: [String: Any] = [
            "instances": [[
                "user_level": history.totalSongs / 10,  // Rough level calculation
                "total_songs": history.totalSongs,
                "jump_success_rate": history.successRates[.jump] ?? 0.5,
                "squat_success_rate": history.successRates[.squat] ?? 0.5,
                "arms_success_rate": history.successRates[.armRaiseLeft] ?? 0.5,
                // ... other features
                "song_bpm": song.bpm,
                "song_genre": song.genre.rawValue
            ]]
        ]

        // Similar Vertex AI call as before...
        // Returns personalized difficulty multiplier

        return PersonalizationPrediction(
            difficultyMultiplier: 1.2,  // Example
            movePreferences: [.jump: 1.5, .squat: 0.8]  // User loves jumps, struggles with squats
        )
    }
}

struct PersonalizationPrediction {
    let difficultyMultiplier: Float
    let movePreferences: [DetectedMove: Float]  // Weight each move type
}
```

---

## Phase 4: v2.0 (Year 2) - Reinforcement Learning

### Advanced: RL Agent for Puzzle Generation

**Goal:** AI that learns to maximize user engagement through trial and error

**Concept:** Treat puzzle generation as a **Reinforcement Learning problem**:
- **State:** Song features + user history + current session context
- **Action:** Generate a puzzle with specific characteristics
- **Reward:** User engagement (did they complete it? rate it? keep playing?)
- **Goal:** Maximize long-term retention and session time

**Architecture: Deep Q-Network (DQN)**

```
State Representation (100 dimensions):
├─ Song features (10 dims)
├─ User embedding (64 dims)
├─ Session context (20 dims: time played, combos, energy level)
└─ Recent puzzle history (6 dims)

Q-Network (predicts value of each action):
├─ Dense(256, activation='relu')
├─ Dense(128, activation='relu')
└─ Output(Q-values for each possible puzzle configuration)

Action Space:
├─ Puzzle Type (5 types)
├─ Move Selection (7^3 = 343 possible 3-move combos)
├─ Difficulty (5 levels: 0.5, 0.75, 1.0, 1.5, 2.0)
└─ Timing Requirements (on-beat: yes/no)

Total Actions: ~8,500 possible puzzle configurations
```

**Why RL is Powerful:**
- Discovers **non-obvious patterns** (e.g., "users engage 20% more if jump puzzles come AFTER squat puzzles")
- **Optimizes for retention**, not just completion rate
- **Adapts in real-time** as user behavior changes

**Implementation (PyTorch + Vertex AI):**

```python
# RL training (runs on cloud, not in app)

import torch
import torch.nn as nn
import numpy as np

class PuzzleGeneratorDQN(nn.Module):
    def __init__(self, state_dim=100, action_dim=8500):
        super().__init__()

        self.network = nn.Sequential(
            nn.Linear(state_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, action_dim)
        )

    def forward(self, state):
        return self.network(state)

# Training loop (simplified)
def train_rl_agent(replay_buffer, episodes=10000):

    agent = PuzzleGeneratorDQN()
    optimizer = torch.optim.Adam(agent.parameters(), lr=0.001)

    for episode in range(episodes):

        # Sample batch from replay buffer (user sessions)
        batch = replay_buffer.sample(batch_size=64)

        states = torch.tensor(batch['states'], dtype=torch.float32)
        actions = torch.tensor(batch['actions'], dtype=torch.long)
        rewards = torch.tensor(batch['rewards'], dtype=torch.float32)
        next_states = torch.tensor(batch['next_states'], dtype=torch.float32)
        dones = torch.tensor(batch['dones'], dtype=torch.bool)

        # Q-learning update
        current_q = agent(states).gather(1, actions.unsqueeze(1))

        with torch.no_grad():
            next_q = agent(next_states).max(1)[0]
            next_q[dones] = 0.0
            target_q = rewards + 0.99 * next_q  # Gamma = 0.99

        loss = nn.MSELoss()(current_q.squeeze(), target_q)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        if episode % 100 == 0:
            print(f'Episode {episode}, Loss: {loss.item():.4f}')

    return agent

# Reward function (key to RL success)
def calculate_reward(puzzle_outcome):
    """
    Reward engineering: what behaviors do we want to encourage?
    """

    reward = 0.0

    # Base reward: did user complete puzzle?
    if puzzle_outcome.completed:
        reward += 1.0
    else:
        reward += puzzle_outcome.completion_percentage * 0.5

    # Bonus: kept playing after this puzzle
    if puzzle_outcome.continued_session:
        reward += 0.5

    # Bonus: high combo achieved
    if puzzle_outcome.max_combo > 10:
        reward += 0.3

    # Penalty: user quit immediately after
    if puzzle_outcome.rage_quit:
        reward -= 2.0

    # Long-term reward: did user return next day? (delayed reward)
    if puzzle_outcome.returned_next_day:
        reward += 1.0

    return reward
```

**Challenge:** RL requires **10K+ training episodes** (user sessions) to converge. This means:
- Need 100K+ active users before RL training is viable
- Takes 1-2 weeks of compute time ($500-1000 training cost)
- But outcome: **AI that generates better puzzles than human designers**

**v2.0 Outcome (If We Reach Scale):**
- **30%+ retention improvement** vs rule-based
- **50% longer session times** (optimal challenge keeps people in flow state)
- **Competitive moat** (very few indie games use RL)

---

## Implementation Roadmap & Costs

### Timeline

| Phase | Launch | Features | ML Cost | Dev Time |
|-------|--------|----------|---------|----------|
| **MVP (Launch)** | Week 21 | Rule-based, audio features | $0/mo | 0 weeks (already planned) |
| **v1.1 (Core ML)** | Month 3 | Genre classification, on-device | $0/mo | +2 weeks |
| **v1.5 (Cloud ML)** | Month 6 | Custom models, personalization | $150-300/mo | +3 weeks |
| **v2.0 (RL)** | Year 2 | Reinforcement learning | $500-1000/mo | +8 weeks |

---

### Cost Breakdown (Year 1)

**Months 1-3 (MVP + v1.1):**
- Infrastructure: $0 (on-device Core ML)
- Development: 2 extra weeks (already solo dev, no added cost)

**Months 4-6 (Transition to v1.5):**
- Vertex AI training: $50 one-time (train initial model)
- Vertex AI predictions: $150/mo (50K DAU × $0.003/prediction)
- Total: $500 over 3 months

**Months 7-12 (v1.5 in production):**
- Vertex AI predictions: $250/mo (100K DAU × $0.0025/prediction at scale)
- Model retraining: $50/quarter (4× per year)
- Total: $1,700

**Year 1 ML Total: ~$2,200**

**ROI Calculation:**
- ML cost: $2,200
- Retention improvement: 15-25% → +10% DAU stickiness
- Revenue impact: +$3K-8K monthly (conservative)
- **Year 1 ROI: 1,636% - 4,364%**

---

### Cost Breakdown (Year 2, if we add RL)

**RL Training:**
- Initial training: $800 (2 weeks on GPU cluster)
- Monthly retraining: $200/mo (as new data comes in)
- Inference costs: $500/mo (more complex models)

**Year 2 ML Total: ~$7,000**

But at Year 2 scale (200K+ DAU), revenue should be $100K+/mo, making $7K (7% of revenue) acceptable.

---

## Data Privacy & Compliance

### GDPR/CCPA Considerations

**What Data Are We Collecting for ML?**
- Song audio features (BPM, energy, etc.) - NOT the actual audio
- User gameplay patterns (moves attempted, puzzles completed)
- Implicit ratings (completion rates, session lengths)
- Device info (iPhone model, iOS version)

**What We're NOT Collecting:**
- ❌ Actual song files (users own their music)
- ❌ Video/photos from camera (ARKit data stays on-device)
- ❌ Personal info (names, emails only for auth)

**Compliance Strategy:**
1. **Anonymize user IDs** in ML training data (hash UUIDs)
2. **Aggregate at population level** (no individual targeting)
3. **Allow opt-out** ("Don't use my data to improve puzzles")
4. **On-device first** (Core ML = no data sent to servers)
5. **Transparent privacy policy** ("We analyze gameplay to create better puzzles")

**Update Privacy Policy:**
```
Machine Learning & Data Usage:

Move Match uses machine learning to create better puzzle experiences. We analyze:
✅ Song audio characteristics (tempo, energy, genre)
✅ Your gameplay patterns (which puzzles you enjoy)
✅ Anonymous gameplay data from all users

We never collect:
❌ Your camera video or photos
❌ Your actual music files
❌ Personal information beyond your email

You can opt out of ML data collection in Settings. This won't affect your gameplay, but puzzles may be less personalized.
```

---

## Measuring ML Success

### Key Metrics (A/B Test: ML vs Rule-Based)

**Primary Metrics:**
- **D1 Retention:** ML should improve by +3-5%
- **D7 Retention:** ML should improve by +5-10%
- **Session Length:** ML should improve by +10-20%
- **Puzzles Completed per Session:** ML should improve by +15-25%

**Secondary Metrics:**
- **User Ratings:** "This puzzle fit the music perfectly" (1-5 stars)
- **Viral Sharing:** Do ML-generated puzzles get shared to TikTok more?
- **Revenue:** Does better engagement → more IAP/ad views?

**A/B Test Setup:**
```swift
// Use Firebase Remote Config for A/B testing

class PuzzleGeneratorFactory {

    enum GeneratorType: String {
        case ruleBased = "rule_based"
        case coreMLA "core_ml"
        case cloudML = "cloud_ml"
    }

    func createGenerator() -> PuzzleGenerator {

        // Firebase assigns users to A/B test groups
        let generatorType = RemoteConfig.remoteConfig()["puzzle_generator_type"].stringValue ?? "rule_based"

        switch GeneratorType(rawValue: generatorType) {
        case .ruleBased:
            return RuleBasedPuzzleGenerator()
        case .coreML:
            return MLEnhancedPuzzleGenerator()
        case .cloudML:
            return CloudMLPuzzleGenerator()
        default:
            return RuleBasedPuzzleGenerator()
        }
    }
}
```

**Firebase A/B Test (Month 3):**
- Group A (50%): Rule-based puzzles
- Group B (50%): Core ML puzzles
- Run for 2 weeks, measure retention/engagement
- If Group B wins by +5% retention → roll out to 100%

---

## Technical Challenges & Solutions

### Challenge 1: Real-Time Audio Analysis is Slow

**Problem:** Analyzing a 3-minute song takes 5-10 seconds (bad UX)

**Solution:** Pre-compute features asynchronously
```swift
class SongLibraryManager {

    func preAnalyzeUserLibrary() async {
        // Run in background when app first opens
        let songs = fetchAllUserSongs()

        for song in songs {
            // Check if already analyzed
            if hasCachedFeatures(song) { continue }

            // Analyze and cache
            let features = await audioAnalyzer.analyze(audioURL: song.assetURL)
            cacheFeatures(song, features)
        }
    }

    private func cacheFeatures(_ song: Song, _ features: AudioFeatures) {
        // Save to UserDefaults or local SQLite
        let data = try! JSONEncoder().encode(features)
        UserDefaults.standard.set(data, forKey: "features_\(song.id)")
    }
}
```

**Result:** First song selection is instant (features pre-computed)

---

### Challenge 2: Core ML Models Are Large (50-100 MB)

**Problem:** App size bloat (guide says keep builds <30 MB)

**Solution:** Download models on-demand
```swift
import CoreML

class ModelManager {

    func downloadGenreClassifierIfNeeded() async {
        let localURL = getModelURL()

        // Check if already downloaded
        if FileManager.default.fileExists(atPath: localURL.path) {
            return
        }

        // Download from Firebase Storage
        let storage = Storage.storage()
        let modelRef = storage.reference(withPath: "ml_models/genre_classifier_v1.mlmodel")

        let downloadTask = modelRef.write(toFile: localURL)

        // Show progress to user
        downloadTask.observe(.progress) { snapshot in
            let percent = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Downloading ML model: \(percent * 100)%")
        }

        try! await downloadTask

        print("Model downloaded successfully")
    }
}
```

**Result:** App binary stays small, models downloaded on WiFi only

---

### Challenge 3: Vertex AI Cold Starts (1-2 Second Latency)

**Problem:** First cloud ML prediction is slow (bad UX)

**Solution:** Hybrid approach - start with Core ML, upgrade with cloud prediction
```swift
class HybridPuzzleGenerator {

    func generatePuzzles(for song: Song) async -> [PuzzleChallenge] {

        // Immediately use Core ML (fast, on-device)
        let quickPuzzles = await coreMLGenerator.generatePuzzles(for: song)

        // Return quickly so user can start playing
        Task {
            // In background, get better cloud ML prediction
            let improvedPuzzles = await cloudMLGenerator.generatePuzzles(for: song)

            // Update puzzles mid-session (smoothly)
            updatePuzzlesInBackground(improvedPuzzles)
        }

        return quickPuzzles
    }
}
```

**Result:** Instant start, seamlessly upgrades to better puzzles mid-song

---

## Alternative: Partner with Music AI APIs

### Option: Use Existing Music Analysis Services

Instead of building everything custom, **integrate with specialized music AI APIs**:

#### 1. **Spotify API** (Free, but requires Spotify Premium)
- Genre, mood, energy, danceability, valence
- Limitation: Only works for Spotify tracks

#### 2. **AcousticBrainz** (Free, open-source)
- Detailed audio features (100+ dimensions)
- Limitation: Limited coverage, older music

#### 3. **Essentia.js** (Free, runs in-app)
- JavaScript library for music analysis
- Can run on-device via WKWebView
- Limitation: Slower than native Swift

#### 4. **Music AI APIs** (Paid)
- **Musiio:** $0.01/track analysis (genre, mood, BPM)
- **Cyanite.ai:** $0.02/track (detailed emotional analysis)
- **Cyanite Pros:**
  - Professional-grade analysis
  - 1,500+ mood tags
  - "Danceability" score perfect for us
- **Cost at 50K DAU:** $500-1000/mo (if every user plays 5 songs)

**Recommendation:** Start with AVFoundation (free) → Add Cyanite.ai at Month 6 if revenue >$10K/mo

---

## Summary: ML Implementation Decision Tree

```
START: Launching Move Match
│
├─ MVP (Week 21): Rule-based generation
│  ├─ Cost: $0
│  ├─ Dev time: 0 weeks (already planned)
│  └─ Outcome: Good enough to validate market
│
├─ Month 3 Decision: Did we hit 10K downloads?
│  ├─ NO → Stay rule-based, focus on marketing
│  └─ YES → Add Core ML (v1.1)
│      ├─ Cost: $0 (on-device)
│      ├─ Dev time: 2 weeks
│      └─ Benefit: +5-10% retention
│
├─ Month 6 Decision: Did we hit 50K downloads + $10K/mo revenue?
│  ├─ NO → Stay Core ML, not worth cloud costs yet
│  └─ YES → Add Cloud ML (v1.5)
│      ├─ Cost: $150-300/mo
│      ├─ Dev time: 3 weeks
│      └─ Benefit: +15-25% retention, personalization
│
└─ Year 2 Decision: Did we hit 200K+ DAU?
   ├─ NO → Stay Cloud ML, RL not needed yet
   └─ YES → Add Reinforcement Learning (v2.0)
       ├─ Cost: $500-1000/mo
       ├─ Dev time: 8 weeks
       └─ Benefit: +30% retention, best-in-class experience
```

---

## Final Recommendation

### For Move Match MVP: **Start Rule-Based, Add ML Incrementally**

**Phase 1 (Launch):**
- Use AVFoundation audio analysis (free, fast)
- Rule-based puzzle generation with smart heuristics
- Collect user data for training
- **Timeline:** Already in 5-6 month plan
- **Cost:** $0

**Phase 2 (Month 3, if successful):**
- Add Core ML genre classification
- Improve move selection based on music style
- **Timeline:** +2 weeks development
- **Cost:** $0
- **Expected ROI:** +5-10% retention = $1K-3K extra monthly revenue

**Phase 3 (Month 6, if hitting targets):**
- Train custom Vertex AI models
- Personalized difficulty and move preferences
- **Timeline:** +3 weeks development
- **Cost:** $150-300/mo
- **Expected ROI:** +15-25% retention = $3K-8K extra monthly revenue

**Phase 4 (Year 2, if scaling):**
- Reinforcement learning for optimal engagement
- Real-time adaptation to user behavior
- **Timeline:** +8 weeks development
- **Cost:** $500-1000/mo
- **Expected ROI:** +30% retention = $10K-20K extra monthly revenue

---

## Updated Budget (With ML)

### Year 1 Costs (Original + ML):

| Category | Original | With ML | Increase |
|----------|----------|---------|----------|
| Development | $363 | $363 | $0 |
| Infrastructure | $850 | $1,350 | +$500 |
| Marketing | $8,500 | $8,500 | $0 |
| Legal | $1,250 | $1,250 | $0 |
| **ML Cloud Costs** | **$0** | **$2,200** | **+$2,200** |
| **TOTAL** | **$12,063** | **$14,263** | **+18%** |

### Year 1 Revenue (With ML):

| Scenario | Original | With ML | Improvement |
|----------|----------|---------|-------------|
| Conservative | $29,400 | $35,000 | +19% |
| Realistic | $60,000 | $75,000 | +25% |
| Best Case | $130,000 | $170,000 | +31% |

**ROI of ML Investment:** +$5.6K - $40K revenue for +$2.2K cost = **254% - 1,818% ROI**

---

## Conclusion: ML is a Force Multiplier

Adding machine learning to Move Match:
1. **Differentiates from competitors** (no other dance-puzzle game has AI choreography)
2. **Improves retention significantly** (+15-25% is massive)
3. **Creates competitive moat** (hard to copy, improves with data)
4. **Justifies premium positioning** ("AI-powered" in ASO = higher perceived value)
5. **Scales investment with growth** ($0 at launch → $300/mo at 50K DAU → $1K/mo at 200K DAU)

**Start simple (rule-based), add ML as you grow and have data to train on.**

By Year 2, if Move Match reaches scale, the ML system will generate better puzzles than any human designer could - because it learns from millions of user sessions.

**This is how you build a defensible indie game in 2025.** 🚀🤖🎵
