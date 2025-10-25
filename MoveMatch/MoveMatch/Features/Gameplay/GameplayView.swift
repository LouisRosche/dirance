//
//  GameplayView.swift
//  MoveMatch
//
//  Main gameplay screen with AR tracking and puzzles
//

import SwiftUI
import ARKit

struct GameplayView: View {

    let song: Song

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @StateObject private var gameEngine: GameEngine
    @StateObject private var bodyTracker = BodyTrackingManager()

    @State private var showingResults = false
    @State private var showingPauseMenu = false

    init(song: Song) {
        self.song = song

        // Initialize game engine with dependencies
        let audioEngine = AudioPlaybackEngine()
        let puzzleGenerator = PuzzleGenerator()
        let difficultyAdjuster = DifficultyAdjuster()

        _gameEngine = StateObject(wrappedValue: GameEngine(
            bodyTracker: bodyTracker,
            audioEngine: audioEngine,
            puzzleGenerator: puzzleGenerator,
            difficultyAdjuster: difficultyAdjuster
        ))
    }

    var body: some View {
        ZStack {
            // AR Camera view
            ARViewContainer(bodyTracker: bodyTracker)
                .ignoresSafeArea()

            // Game UI overlay
            VStack {
                // Top HUD
                GameHUD(
                    score: gameEngine.score,
                    combo: gameEngine.currentCombo,
                    progress: gameEngine.songProgress
                )
                .padding()

                Spacer()

                // Active puzzle display
                if let puzzle = gameEngine.activePuzzle {
                    PuzzlePrompt(puzzle: puzzle)
                        .padding()
                }

                Spacer()

                // Calibration or game state messages
                if gameEngine.gameState == .calibrating {
                    CalibrationOverlay(
                        progress: bodyTracker.calibrationProgress,
                        quality: bodyTracker.trackingQuality
                    )
                } else if gameEngine.gameState == .paused {
                    PauseOverlay(
                        onResume: { gameEngine.resumeGame() },
                        onQuit: { endGame() }
                    )
                }
            }

            // Pause button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        if gameEngine.gameState == .playing {
                            gameEngine.pauseGame()
                        }
                    } label: {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }

                Spacer()
            }
        }
        .onAppear {
            startGame()
        }
        .onChange(of: gameEngine.gameState) { oldValue, newValue in
            if newValue == .finished {
                showResults()
            }
        }
        .sheet(isPresented: $showingResults) {
            if let session = gameEngine.getSessionResults() {
                ResultsView(session: session, song: song)
            }
        }
    }

    private func startGame() {
        guard let userId = appState.currentUser?.id else { return }

        Task {
            await gameEngine.startGame(
                song: song,
                userId: userId,
                userLevel: appState.currentUser?.level ?? 1
            )
        }
    }

    private func endGame() {
        gameEngine.endGame()
        dismiss()
    }

    private func showResults() {
        // Save session to Firebase
        if let session = gameEngine.getSessionResults() {
            Task {
                try? await appState.firebaseManager.saveSession(session: session)

                // Update user stats
                if var user = appState.currentUser {
                    user.totalSongsPlayed += 1
                    user.totalCaloriesBurned += session.caloriesBurned
                    user.totalComboStreak = max(user.totalComboStreak, session.maxCombo)

                    // Calculate new average stars
                    let totalStars = user.averageStars * Float(user.totalSongsPlayed - 1) + Float(session.stars)
                    user.averageStars = totalStars / Float(user.totalSongsPlayed)

                    // Award XP
                    user.addXP(session.score / 10) // 1 XP per 10 points

                    try? await appState.firebaseManager.saveUserProfile(profile: user)
                    appState.currentUser = user
                }
            }
        }

        showingResults = true
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {

    let bodyTracker: BodyTrackingManager

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session = bodyTracker.arSession
        arView.automaticallyUpdatesLighting = true
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed
    }
}

// MARK: - Game HUD

struct GameHUD: View {

    let score: Int
    let combo: Int
    let progress: Float

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)

            // Score and combo
            HStack {
                // Score
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text("\(score)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                Spacer()

                // Combo
                if combo > 0 {
                    VStack(spacing: 4) {
                        Text("\(combo)x")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.yellow)

                        Text("COMBO")
                            .font(.caption)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Puzzle Prompt

struct PuzzlePrompt: View {

    let puzzle: PuzzleChallenge

    var body: some View {
        VStack(spacing: 12) {
            Text(puzzle.displayTitle)
                .font(.title2.bold())
                .foregroundColor(.white)

            // Show move sequence for combos
            if puzzle.type == .comboSequence {
                HStack(spacing: 8) {
                    ForEach(puzzle.requirements, id: \.move) { req in
                        Text(req.move.emoji)
                            .font(.system(size: 40))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.purple.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

// MARK: - Calibration Overlay

struct CalibrationOverlay: View {

    let progress: Float
    let quality: BodyTrackingManager.TrackingQuality

    var body: some View {
        VStack(spacing: 20) {
            Text("Calibrating...")
                .font(.title.bold())
                .foregroundColor(.white)

            Text(quality.displayText)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.green, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            Text("Stand 2-3 meters from camera")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
    }
}

// MARK: - Pause Overlay

struct PauseOverlay: View {

    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Paused")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Button {
                    onResume()
                } label: {
                    Text("Resume")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }

                Button {
                    onQuit()
                } label: {
                    Text("Quit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}
