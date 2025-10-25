//
//  GameEngine.swift
//  MoveMatch
//
//  Core game engine coordinating ARKit, Audio, and Puzzle systems
//

import Foundation
import AVFoundation
import Combine

@MainActor
class GameEngine: ObservableObject {

    // MARK: - Published State

    @Published var gameState: GameState = .idle
    @Published var currentSong: Song?
    @Published var activePuzzle: PuzzleChallenge?
    @Published var score: Int = 0
    @Published var currentCombo: Int = 0
    @Published var maxCombo: Int = 0
    @Published var puzzlesCompleted: Int = 0
    @Published var songProgress: Float = 0.0 // 0-1
    @Published var caloriesBurned: Int = 0
    @Published var sessionTime: TimeInterval = 0

    // MARK: - Dependencies

    private let bodyTracker: BodyTrackingManager
    private let audioEngine: AudioPlaybackEngine
    private let puzzleGenerator: PuzzleGenerator
    private let difficultyAdjuster: DifficultyAdjuster

    // MARK: - Private State

    private var allPuzzles: [PuzzleChallenge] = []
    private var puzzleResults: [PuzzleResult] = []
    private var session: GameSession?
    private var startTime: Date?
    private var currentPuzzleProgress: PuzzleProgress?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        bodyTracker: BodyTrackingManager,
        audioEngine: AudioPlaybackEngine,
        puzzleGenerator: PuzzleGenerator,
        difficultyAdjuster: DifficultyAdjuster
    ) {
        self.bodyTracker = bodyTracker
        self.audioEngine = audioEngine
        self.puzzleGenerator = puzzleGenerator
        self.difficultyAdjuster = difficultyAdjuster

        setupObservers()
    }

    // MARK: - Public Methods

    func startGame(song: Song, userId: String, userLevel: Int) async {
        // Reset state
        score = 0
        currentCombo = 0
        maxCombo = 0
        puzzlesCompleted = 0
        caloriesBurned = 0
        sessionTime = 0
        puzzleResults = []

        currentSong = song
        gameState = .calibrating

        // Generate puzzles
        allPuzzles = puzzleGenerator.generatePuzzles(for: song, userLevel: userLevel)

        // Create session
        session = GameSession(
            id: UUID(),
            songId: song.id,
            userId: userId,
            startTime: Date(),
            totalPuzzles: allPuzzles.count
        )

        // Start ARKit calibration
        bodyTracker.startTracking()

        // Wait for calibration
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

        // Start music
        if let url = song.assetURL {
            await audioEngine.loadSong(url: url, bpm: song.bpm ?? 120)
            audioEngine.play()
        }

        startTime = Date()
        gameState = .playing

        // Start game loop
        startGameLoop()
    }

    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        audioEngine.pause()
    }

    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        audioEngine.resume()
    }

    func endGame() {
        gameState = .finished
        audioEngine.stop()
        bodyTracker.stopTracking()

        // Finalize session
        if var session = session {
            session.endTime = Date()
            session.score = score
            session.maxCombo = maxCombo
            session.puzzlesCompleted = puzzlesCompleted
            session.caloriesBurned = caloriesBurned
            session.stars = calculateStars()
            self.session = session
        }
    }

    func getSessionResults() -> GameSession? {
        return session
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Listen to detected moves
        bodyTracker.$lastDetectedMove
            .compactMap { $0 }
            .sink { [weak self] move in
                self?.handleDetectedMove(move)
            }
            .store(in: &cancellables)

        // Listen to audio progress
        audioEngine.$currentTime
            .sink { [weak self] time in
                guard let self = self,
                      let song = self.currentSong else { return }
                self.songProgress = Float(time / song.duration)
                self.sessionTime = time
                self.updateActivePuzzle(time: time)
            }
            .store(in: &cancellables)
    }

    private func startGameLoop() {
        Task {
            while gameState == .playing {
                // Update calories (rough estimate: 5 cal/min active gameplay)
                if currentCombo > 0 {
                    let minutesPlayed = sessionTime / 60.0
                    caloriesBurned = Int(minutesPlayed * 5)
                }

                // Check if song ended
                if let song = currentSong,
                   sessionTime >= song.duration {
                    endGame()
                    break
                }

                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }

    private func updateActivePuzzle(time: TimeInterval) {
        // Find active puzzle based on current time
        let currentPuzzle = allPuzzles.first { puzzle in
            time >= puzzle.startTime && time < puzzle.startTime + puzzle.duration
        }

        if currentPuzzle?.id != activePuzzle?.id {
            // Puzzle changed
            if let previous = activePuzzle {
                finalizePuzzle(previous)
            }

            if let new = currentPuzzle {
                startPuzzle(new)
            }
        }

        activePuzzle = currentPuzzle
    }

    private func startPuzzle(_ puzzle: PuzzleChallenge) {
        currentPuzzleProgress = PuzzleProgress(
            puzzleId: puzzle.id,
            startTime: Date(),
            requirements: Dictionary(
                uniqueKeysWithValues: puzzle.requirements.map { ($0.move, 0) }
            )
        )
    }

    private func finalizePuzzle(_ puzzle: PuzzleChallenge) {
        guard let progress = currentPuzzleProgress else { return }

        let completed = checkPuzzleCompletion(puzzle, progress: progress)
        let stars = calculatePuzzleStars(puzzle, progress: progress)

        let result = PuzzleResult(
            puzzleId: puzzle.id,
            completed: completed,
            stars: stars,
            completionPercentage: calculateCompletionPercentage(puzzle, progress: progress)
        )

        puzzleResults.append(result)

        if completed {
            puzzlesCompleted += 1

            // Award bonus points for completion
            score += Int(1000 * puzzle.difficultyMultiplier)
        }

        currentPuzzleProgress = nil
    }

    private func handleDetectedMove(_ move: DetectedMove) {
        guard gameState == .playing,
              let puzzle = activePuzzle,
              var progress = currentPuzzleProgress else { return }

        let isCorrectMove = checkMoveCorrectness(move, for: puzzle, progress: progress)
        let isOnBeat = checkIfOnBeat()

        if isCorrectMove {
            // Update progress
            progress.requirements[move, default: 0] += 1
            currentPuzzleProgress = progress

            // Increase combo
            currentCombo += 1
            maxCombo = max(maxCombo, currentCombo)

            // Calculate points
            var points = 100 * currentCombo
            if isOnBeat {
                points *= 2 // Double points for on-beat moves
            }

            score += Int(Float(points) * puzzle.difficultyMultiplier)

        } else {
            // Wrong move - reset combo
            currentCombo = 0
        }

        // Update session move stats
        session?.movesAttempted[move, default: 0] += 1
        if isCorrectMove {
            session?.movesSucceeded[move, default: 0] += 1
        }
    }

    private func checkMoveCorrectness(_ move: DetectedMove, for puzzle: PuzzleChallenge, progress: PuzzleProgress) -> Bool {
        switch puzzle.type {
        case .simpleRepetition:
            // Need this specific move
            return puzzle.requirements.first?.move == move

        case .comboSequence:
            // Check if this is the next move in sequence
            let totalMoves = progress.requirements.values.reduce(0, +)
            let expectedMove = puzzle.requirements[totalMoves % puzzle.requirements.count].move
            return move == expectedMove

        case .timingChallenge:
            // Any of the required moves
            return puzzle.requirements.contains { $0.move == move }

        case .endurance:
            // Any move works
            return true

        case .countingChallenge:
            // Any of the allowed moves
            return puzzle.requirements.contains { $0.move == move }
        }
    }

    private func checkIfOnBeat() -> Bool {
        return audioEngine.isOnBeat(tolerance: 0.15) // ±150ms
    }

    private func checkPuzzleCompletion(_ puzzle: PuzzleChallenge, progress: PuzzleProgress) -> Bool {
        switch puzzle.type {
        case .simpleRepetition, .timingChallenge, .countingChallenge:
            // Check if all requirements met
            return puzzle.requirements.allSatisfy { req in
                progress.requirements[req.move, default: 0] >= req.count
            }

        case .comboSequence:
            // Check if sequence completed enough times
            let totalMoves = progress.requirements.values.reduce(0, +)
            let sequenceLength = puzzle.requirements.count
            return totalMoves >= sequenceLength * 3 // Complete sequence 3 times

        case .endurance:
            // Just need to maintain combo
            return currentCombo >= 10
        }
    }

    private func calculateCompletionPercentage(_ puzzle: PuzzleChallenge, progress: PuzzleProgress) -> Float {
        let totalRequired = puzzle.requirements.reduce(0) { $0 + $1.count }
        let totalAchieved = progress.requirements.values.reduce(0, +)

        guard totalRequired > 0 else { return 1.0 }
        return min(1.0, Float(totalAchieved) / Float(totalRequired))
    }

    private func calculatePuzzleStars(_ puzzle: PuzzleChallenge, progress: PuzzleProgress) -> Int {
        let completion = calculateCompletionPercentage(puzzle, progress: progress)

        if completion >= 0.9 {
            return 3
        } else if completion >= 0.6 {
            return 2
        } else if completion >= 0.3 {
            return 1
        } else {
            return 0
        }
    }

    private func calculateStars() -> Int {
        let avgCompletion = puzzleResults.map { $0.completionPercentage }.reduce(0, +) / Float(max(1, puzzleResults.count))

        if avgCompletion >= 0.8 && maxCombo >= 20 {
            return 3
        } else if avgCompletion >= 0.6 && maxCombo >= 10 {
            return 2
        } else if avgCompletion >= 0.3 {
            return 1
        } else {
            return 0
        }
    }
}

// MARK: - Game State

enum GameState {
    case idle
    case calibrating
    case playing
    case paused
    case finished
}

// MARK: - Puzzle Progress

struct PuzzleProgress {
    let puzzleId: UUID
    let startTime: Date
    var requirements: [DetectedMove: Int] // Move -> count achieved
}

// MARK: - Audio Playback Engine

@MainActor
class AudioPlaybackEngine: ObservableObject {

    @Published var currentTime: TimeInterval = 0
    @Published var isPlaying = false

    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var bpm: Float = 120
    private var startTime: TimeInterval = 0
    private var displayLink: CADisplayLink?

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        try? audioEngine.start()
    }

    func loadSong(url: URL, bpm: Float) async {
        self.bpm = bpm

        do {
            audioFile = try AVAudioFile(forReading: url)

            if let file = audioFile {
                playerNode.scheduleFile(file, at: nil)
            }
        } catch {
            print("❌ Failed to load audio: \(error)")
        }
    }

    func play() {
        guard let audioFile = audioFile else { return }

        startTime = CACurrentMediaTime()
        playerNode.play()
        isPlaying = true

        // Start display link for smooth progress updates
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    func pause() {
        playerNode.pause()
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
    }

    func resume() {
        playerNode.play()
        isPlaying = true

        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateProgress() {
        currentTime = CACurrentMediaTime() - startTime
    }

    func isOnBeat(tolerance: TimeInterval) -> Bool {
        let beatDuration = 60.0 / Double(bpm)
        let beatPhase = currentTime.truncatingRemainder(dividingBy: beatDuration)

        return beatPhase < tolerance || beatPhase > (beatDuration - tolerance)
    }
}
