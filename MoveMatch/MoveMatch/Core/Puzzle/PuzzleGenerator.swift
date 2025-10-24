//
//  PuzzleGenerator.swift
//  MoveMatch
//
//  Rule-based and ML-enhanced puzzle generation
//

import Foundation

class PuzzleGenerator {

    // MARK: - Public Methods

    func generatePuzzles(for song: Song, userLevel: Int) -> [PuzzleChallenge] {
        guard let features = song.features else {
            return generateDefaultPuzzles(for: song, userLevel: userLevel)
        }

        let style = features.estimatedGenre
        let difficulty = calculateDifficulty(userLevel: userLevel, intensity: features.energy)

        return generateStyleAwarePuzzles(
            genre: style,
            features: features,
            difficulty: difficulty,
            duration: song.duration
        )
    }

    // MARK: - Private Methods

    private func calculateDifficulty(userLevel: Int, intensity: Float) -> Float {
        let baseDifficulty = Float(userLevel) / 10.0 // Level 10 = 1.0x difficulty
        let intensityMultiplier = 0.5 + (intensity * 0.5) // 0.5-1.0x based on energy

        return max(0.5, min(2.0, baseDifficulty * intensityMultiplier))
    }

    private func generateDefaultPuzzles(for song: Song, userLevel: Int) -> [PuzzleChallenge] {
        let difficulty = Float(userLevel) / 10.0

        return [
            PuzzleChallenge(
                id: UUID(),
                type: .simpleRepetition,
                startTime: 0,
                duration: 30,
                requirements: [
                    MoveRequirement(move: .jump, count: Int(5 * difficulty), mustBeOnBeat: false)
                ],
                difficultyMultiplier: difficulty
            ),
            PuzzleChallenge(
                id: UUID(),
                type: .comboSequence,
                startTime: 45,
                duration: 30,
                requirements: [
                    MoveRequirement(move: .squat, count: 1, mustBeOnBeat: false),
                    MoveRequirement(move: .armRaiseLeft, count: 1, mustBeOnBeat: false),
                    MoveRequirement(move: .jump, count: 1, mustBeOnBeat: false)
                ],
                difficultyMultiplier: difficulty
            )
        ]
    }

    private func generateStyleAwarePuzzles(
        genre: MusicGenre,
        features: AudioFeatures,
        difficulty: Float,
        duration: TimeInterval
    ) -> [PuzzleChallenge] {

        let moveProfile = getMoveProfileFor(genre)
        var puzzles: [PuzzleChallenge] = []

        // Intro puzzle (0-15 seconds)
        puzzles.append(createIntroPuzzle(
            moves: moveProfile.introMoves,
            difficulty: difficulty
        ))

        // Verse puzzles (15-60 seconds)
        if duration > 30 {
            puzzles.append(createVersePuzzle(
                moves: moveProfile.verseMoves,
                difficulty: difficulty,
                startTime: 15
            ))
        }

        // Chorus/drop puzzle
        if duration > 60 {
            let dropTime = findDrop(features.onsets, songDuration: duration)
            puzzles.append(createChorusPuzzle(
                moves: moveProfile.chorusMoves,
                difficulty: difficulty,
                startTime: dropTime
            ))
        }

        // Bridge puzzle (if long song)
        if duration > 120 {
            puzzles.append(createBridgePuzzle(
                moves: moveProfile.verseMoves,
                difficulty: difficulty,
                startTime: duration * 0.65
            ))
        }

        return puzzles
    }

    // MARK: - Move Profiles by Genre

    struct MoveProfile {
        let introMoves: [DetectedMove]
        let verseMoves: [DetectedMove]
        let chorusMoves: [DetectedMove]
    }

    private func getMoveProfileFor(_ genre: MusicGenre) -> MoveProfile {
        switch genre {
        case .electronic:
            return MoveProfile(
                introMoves: [.armRaiseLeft, .armRaiseRight],
                verseMoves: [.jump, .sideStepLeft, .sideStepRight],
                chorusMoves: [.spin, .jump, .armRaiseLeft, .armRaiseRight]
            )

        case .hiphop:
            return MoveProfile(
                introMoves: [.sideStepLeft, .sideStepRight],
                verseMoves: [.squat, .sideStepLeft, .sideStepRight],
                chorusMoves: [.squat, .armRaiseLeft, .armRaiseRight]
            )

        case .classical:
            return MoveProfile(
                introMoves: [.armRaiseLeft, .armRaiseRight],
                verseMoves: [.armRaiseLeft, .armRaiseRight],
                chorusMoves: [.armRaiseLeft, .armRaiseRight, .spin]
            )

        case .latin:
            return MoveProfile(
                introMoves: [.sideStepLeft, .sideStepRight],
                verseMoves: [.sideStepLeft, .sideStepRight, .spin],
                chorusMoves: [.spin, .sideStepLeft, .sideStepRight, .jump]
            )

        case .rock:
            return MoveProfile(
                introMoves: [.jump, .armRaiseLeft],
                verseMoves: [.jump, .squat, .armRaiseLeft],
                chorusMoves: [.jump, .spin, .armRaiseLeft, .armRaiseRight]
            )

        default: // Pop
            return MoveProfile(
                introMoves: [.armRaiseLeft, .jump],
                verseMoves: [.jump, .squat, .sideStepLeft],
                chorusMoves: [.jump, .armRaiseLeft, .armRaiseRight, .spin]
            )
        }
    }

    // MARK: - Puzzle Creation

    private func createIntroPuzzle(moves: [DetectedMove], difficulty: Float) -> PuzzleChallenge {
        let move = moves.randomElement() ?? .jump

        return PuzzleChallenge(
            id: UUID(),
            type: .simpleRepetition,
            startTime: 0,
            duration: 15,
            requirements: [
                MoveRequirement(move: move, count: Int(5 * difficulty), mustBeOnBeat: false)
            ],
            difficultyMultiplier: difficulty
        )
    }

    private func createVersePuzzle(moves: [DetectedMove], difficulty: Float, startTime: TimeInterval) -> PuzzleChallenge {
        let selectedMoves = moves.prefix(3).map { move in
            MoveRequirement(move: move, count: 1, mustBeOnBeat: false)
        }

        return PuzzleChallenge(
            id: UUID(),
            type: .comboSequence,
            startTime: startTime,
            duration: 30,
            requirements: Array(selectedMoves),
            difficultyMultiplier: difficulty
        )
    }

    private func createChorusPuzzle(moves: [DetectedMove], difficulty: Float, startTime: TimeInterval) -> PuzzleChallenge {
        let move = moves.randomElement() ?? .jump

        return PuzzleChallenge(
            id: UUID(),
            type: .timingChallenge,
            startTime: startTime,
            duration: 30,
            requirements: [
                MoveRequirement(move: move, count: Int(10 * difficulty), mustBeOnBeat: true)
            ],
            difficultyMultiplier: difficulty
        )
    }

    private func createBridgePuzzle(moves: [DetectedMove], difficulty: Float, startTime: TimeInterval) -> PuzzleChallenge {
        return PuzzleChallenge(
            id: UUID(),
            type: .endurance,
            startTime: startTime,
            duration: 20,
            requirements: [],
            difficultyMultiplier: difficulty
        )
    }

    private func findDrop(_ onsets: [TimeInterval], songDuration: TimeInterval) -> TimeInterval {
        // Find the "drop" - typically 50-70% through the song
        let searchStart = songDuration * 0.4
        let searchEnd = songDuration * 0.7

        let candidateOnsets = onsets.filter { $0 > searchStart && $0 < searchEnd }

        return candidateOnsets.first ?? (searchStart + searchEnd) / 2
    }
}

// MARK: - Adaptive Difficulty

class DifficultyAdjuster {

    private var recentResults: [PuzzleResult] = []
    private let historySize = 5

    func adjustDifficulty(after result: PuzzleResult, currentDifficulty: Float) -> Float {
        recentResults.append(result)
        if recentResults.count > historySize {
            recentResults.removeFirst()
        }

        let failures = recentResults.filter { !$0.completed }.count
        let perfectRuns = recentResults.filter { $0.stars == 3 }.count

        if failures >= 3 {
            // Make easier
            return max(0.5, currentDifficulty - 0.2)
        }

        if perfectRuns >= 5 {
            // Make harder
            return min(2.0, currentDifficulty + 0.3)
        }

        return currentDifficulty
    }
}

struct PuzzleResult {
    let puzzleId: UUID
    let completed: Bool
    let stars: Int
    let completionPercentage: Float
}
