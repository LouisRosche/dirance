//
//  GameModels.swift
//  MoveMatch
//
//  Core data models for the game
//

import Foundation
import simd

// MARK: - Move Detection

enum DetectedMove: String, Codable, CaseIterable {
    case jump
    case squat
    case armRaiseLeft
    case armRaiseRight
    case sideStepLeft
    case sideStepRight
    case spin

    var displayName: String {
        switch self {
        case .jump: return "Jump"
        case .squat: return "Squat"
        case .armRaiseLeft: return "Left Arm Up"
        case .armRaiseRight: return "Right Arm Up"
        case .sideStepLeft: return "Step Left"
        case .sideStepRight: return "Step Right"
        case .spin: return "Spin"
        }
    }

    var emoji: String {
        switch self {
        case .jump: return "🦘"
        case .squat: return "🦵"
        case .armRaiseLeft, .armRaiseRight: return "🙌"
        case .sideStepLeft, .sideStepRight: return "👟"
        case .spin: return "🌀"
        }
    }
}

struct BodyPose {
    let timestamp: TimeInterval
    let joints: [JointType: JointData]
    let confidence: Float
}

enum JointType: String {
    case head, neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case hips
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
}

struct JointData {
    let position: simd_float3
    let confidence: Float
}

// MARK: - Audio Analysis

struct AudioFeatures: Codable {
    let bpm: Float
    let energy: Float              // 0-1
    let danceability: Float        // 0-1
    let spectralCentroid: Float    // 0-1 (bass=0, treble=1)
    let onsets: [TimeInterval]
    let duration: TimeInterval

    var estimatedGenre: MusicGenre {
        // Rule-based classification
        if energy > 0.7 && bpm > 120 && spectralCentroid > 0.6 {
            return .electronic
        } else if bpm > 80 && bpm < 110 && spectralCentroid < 0.4 && danceability > 0.6 {
            return .hiphop
        } else if energy < 0.4 && danceability < 0.4 {
            return .classical
        } else if bpm > 100 && bpm < 130 && danceability > 0.7 {
            return .latin
        } else if energy > 0.6 && bpm > 110 && bpm < 150 {
            return .rock
        } else {
            return .pop
        }
    }
}

enum MusicGenre: String, Codable {
    case electronic, hiphop, pop, rock, classical, latin, jazz, country

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Song

struct Song: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let duration: TimeInterval
    let assetURL: URL?
    var bpm: Float?
    var genre: MusicGenre?
    var features: AudioFeatures?

    var displayDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Puzzles

struct PuzzleChallenge: Identifiable, Codable {
    let id: UUID
    let type: PuzzleType
    let startTime: TimeInterval
    let duration: TimeInterval
    let requirements: [MoveRequirement]
    let difficultyMultiplier: Float

    var displayTitle: String {
        switch type {
        case .simpleRepetition:
            let move = requirements.first!.move
            let count = requirements.first!.count
            return "Do \(count) \(move.displayName)s"
        case .comboSequence:
            let moves = requirements.map { $0.move.emoji }.joined()
            return "Combo: \(moves)"
        case .timingChallenge:
            return "Hit \(requirements.first!.count) On-Beat Moves"
        case .endurance:
            return "Keep Dancing for \(Int(duration))s"
        case .countingChallenge:
            return "\(requirements.first!.count) Total Moves"
        }
    }
}

enum PuzzleType: String, Codable {
    case simpleRepetition
    case comboSequence
    case timingChallenge
    case endurance
    case countingChallenge
}

struct MoveRequirement: Codable {
    let move: DetectedMove
    let count: Int
    let mustBeOnBeat: Bool
}

// MARK: - Game Session

struct GameSession: Codable {
    let id: UUID
    let songId: String
    let userId: String
    let startTime: Date
    var endTime: Date?
    var score: Int = 0
    var maxCombo: Int = 0
    var puzzlesCompleted: Int = 0
    var totalPuzzles: Int = 0
    var caloriesBurned: Int = 0
    var stars: Int = 0
    var movesAttempted: [DetectedMove: Int] = [:]
    var movesSucceeded: [DetectedMove: Int] = [:]

    var completionPercentage: Float {
        guard totalPuzzles > 0 else { return 0 }
        return Float(puzzlesCompleted) / Float(totalPuzzles)
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    var displayName: String
    var level: Int = 1
    var totalXP: Int = 0
    var coins: Int = 0
    var gems: Int = 0
    var createdAt: Date = Date()
    var lastPlayedAt: Date = Date()

    // Stats
    var totalSongsPlayed: Int = 0
    var totalCaloriesBurned: Int = 0
    var totalComboStreak: Int = 0
    var averageStars: Float = 0.0

    // Unlocks
    var unlockedMoves: [DetectedMove] = [.jump, .squat, .armRaiseLeft, .armRaiseRight]
    var unlockedCharacters: [String] = ["starter"]
    var unlockedPowerUps: [String] = []
    var unlockedSongs: [String] = []

    // Progression
    var hasSeasonPass: Bool = false
    var seasonPassTier: Int = 0
    var seasonPassXP: Int = 0
    var isVIP: Bool = false
    var vipExpiry: Date?

    // Calculated properties
    var xpToNextLevel: Int {
        return level * 1000 // 1000 XP for level 1, 2000 for level 2, etc.
    }

    var xpProgress: Float {
        let currentLevelXP = (level - 1) * 1000
        let xpIntoLevel = totalXP - currentLevelXP
        return Float(xpIntoLevel) / Float(xpToNextLevel)
    }

    mutating func addXP(_ amount: Int) {
        totalXP += amount
        while totalXP >= xpToNextLevel {
            levelUp()
        }
    }

    mutating func levelUp() {
        level += 1
        // Award coins for leveling up
        coins += 100 * level
    }

    mutating func addCoins(_ amount: Int) {
        coins += amount
    }

    mutating func addGems(_ amount: Int) {
        gems += amount
    }

    mutating func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    mutating func spendGems(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        return true
    }
}

// MARK: - Power-Ups

enum PowerUp: String, Codable, CaseIterable {
    case beatSync
    case slowMo
    case freePass
    case calorieBurst
    case starBoost

    var displayName: String {
        switch self {
        case .beatSync: return "Beat Sync"
        case .slowMo: return "Slow-Mo"
        case .freePass: return "Free Pass"
        case .calorieBurst: return "Calorie Burst"
        case .starBoost: return "Star Boost"
        }
    }

    var description: String {
        switch self {
        case .beatSync: return "Visual metronome for perfect timing"
        case .slowMo: return "5 seconds of 0.5x speed"
        case .freePass: return "1 wrong move doesn't break combo"
        case .calorieBurst: return "2x fitness tracking this session"
        case .starBoost: return "Easier 3-star requirements"
        }
    }

    var gemCost: Int {
        switch self {
        case .beatSync: return 50
        case .slowMo: return 75
        case .freePass: return 100
        case .calorieBurst: return 50
        case .starBoost: return 100
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let score: Int
    let rank: Int
    let timestamp: Date
}

enum LeaderboardTimeframe: String, CaseIterable {
    case daily, weekly, allTime

    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Season Pass

struct SeasonPass: Codable {
    let id: String
    let seasonNumber: Int
    let startDate: Date
    let endDate: Date
    let tiers: [SeasonTier]

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(0, components.day ?? 0)
    }
}

struct SeasonTier: Codable, Identifiable {
    let id: Int
    let xpRequired: Int
    let freeReward: Reward?
    let premiumReward: Reward?
}

enum Reward: Codable {
    case coins(Int)
    case gems(Int)
    case move(DetectedMove)
    case character(String)
    case powerUp(PowerUp)
    case cosmetic(String)

    var displayName: String {
        switch self {
        case .coins(let amount): return "\(amount) Coins"
        case .gems(let amount): return "\(amount) Gems"
        case .move(let move): return move.displayName
        case .character(let name): return name
        case .powerUp(let powerUp): return powerUp.displayName
        case .cosmetic(let name): return name
        }
    }
}

// MARK: - Daily Quests

struct DailyQuest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let requirement: Int
    var progress: Int = 0
    let rewardXP: Int
    let rewardCoins: Int
    let expiresAt: Date

    var isCompleted: Bool {
        progress >= requirement
    }

    var progressPercentage: Float {
        Float(progress) / Float(requirement)
    }
}

// MARK: - In-App Purchase Products

enum IAPProduct: String, CaseIterable {
    case gems100 = "com.movematch.gems100"
    case gems500 = "com.movematch.gems500"
    case gems1500 = "com.movematch.gems1500"
    case seasonPass = "com.movematch.seasonpass"
    case vipMonthly = "com.movematch.vip.monthly"
    case noAds24h = "com.movematch.noads24"
    case fitnessPack = "com.movematch.fitnesspack"

    var displayName: String {
        switch self {
        case .gems100: return "Starter Pack"
        case .gems500: return "Popular Pack"
        case .gems1500: return "Mega Pack"
        case .seasonPass: return "Season Pass"
        case .vipMonthly: return "VIP Membership"
        case .noAds24h: return "Ad-Free Day"
        case .fitnessPack: return "Fitness Pack"
        }
    }

    var price: Decimal {
        switch self {
        case .gems100: return 0.99
        case .gems500: return 2.99
        case .gems1500: return 9.99
        case .seasonPass: return 4.99
        case .vipMonthly: return 9.99
        case .noAds24h: return 1.99
        case .fitnessPack: return 3.99
        }
    }
}
