//
//  ProgressionManager.swift
//  MoveMatch
//
//  Handle XP, leveling, unlocks, and progression
//

import Foundation

class ProgressionManager {

    // MARK: - XP and Leveling

    func calculateXPForLevel(_ level: Int) -> Int {
        return level * 1000 // Level 1 = 1000 XP, Level 2 = 2000 XP, etc.
    }

    func checkLevelUp(currentXP: Int, currentLevel: Int) -> (newLevel: Int, leveledUp: Bool) {
        var level = currentLevel
        var xp = currentXP
        var leveledUp = false

        while xp >= calculateXPForLevel(level) {
            level += 1
            leveledUp = true
        }

        return (level, leveledUp)
    }

    func getRewardsForLevel(_ level: Int) -> [Reward] {
        var rewards: [Reward] = []

        // Every level: coins
        rewards.append(.coins(100 * level))

        // Every 5 levels: gems
        if level % 5 == 0 {
            rewards.append(.gems(50))
        }

        // Every 10 levels: power-up
        if level % 10 == 0 {
            let powerUps: [PowerUp] = [.beatSync, .slowMo, .freePass, .calorieBurst, .starBoost]
            let powerUp = powerUps[level / 10 % powerUps.count]
            rewards.append(.powerUp(powerUp))
        }

        // Special milestone rewards
        switch level {
        case 5:
            rewards.append(.move(.spin))
        case 10:
            rewards.append(.character("Fitness Fanatic"))
        case 15:
            rewards.append(.move(.sideStepLeft))
            rewards.append(.move(.sideStepRight))
        case 20:
            rewards.append(.character("Rhythm Master"))
        case 25:
            rewards.append(.gems(200))
        default:
            break
        }

        return rewards
    }

    // MARK: - Daily Quests

    func generateDailyQuests(for date: Date = Date()) -> [DailyQuest] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!

        return [
            DailyQuest(
                id: "daily_1_\(date.timeIntervalSince1970)",
                title: "Complete 3 Songs",
                description: "Play and complete any 3 songs",
                requirement: 3,
                progress: 0,
                rewardXP: 50,
                rewardCoins: 100,
                expiresAt: endOfDay
            ),
            DailyQuest(
                id: "daily_2_\(date.timeIntervalSince1970)",
                title: "Hit 50 Perfect Moves",
                description: "Hit 50 moves on-beat with perfect timing",
                requirement: 50,
                progress: 0,
                rewardXP: 100,
                rewardCoins: 200,
                expiresAt: endOfDay
            ),
            DailyQuest(
                id: "daily_3_\(date.timeIntervalSince1970)",
                title: "Burn 100 Calories",
                description: "Burn 100 calories through gameplay",
                requirement: 100,
                progress: 0,
                rewardXP: 150,
                rewardCoins: 300,
                expiresAt: endOfDay
            )
        ]
    }

    // MARK: - Season Pass

    func generateSeasonPass(seasonNumber: Int) -> SeasonPass {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!

        var tiers: [SeasonTier] = []

        for tier in 1...30 {
            let xpRequired = tier * 1000

            // Free tier rewards
            var freeReward: Reward?
            if tier % 5 == 0 {
                freeReward = .coins(500)
            } else if tier % 10 == 0 {
                freeReward = .gems(50)
            }

            // Premium tier rewards
            var premiumReward: Reward?
            if tier == 5 {
                premiumReward = .move(.spin)
            } else if tier == 10 {
                premiumReward = .powerUp(.beatSync)
            } else if tier == 15 {
                premiumReward = .character("Viral Star")
            } else if tier == 20 {
                premiumReward = .gems(200)
            } else if tier == 25 {
                premiumReward = .cosmetic("Gold Particle Effect")
            } else if tier == 30 {
                premiumReward = .character("Dance Legend")
            } else if tier % 3 == 0 {
                premiumReward = .coins(1000)
            }

            tiers.append(SeasonTier(
                id: tier,
                xpRequired: xpRequired,
                freeReward: freeReward,
                premiumReward: premiumReward
            ))
        }

        return SeasonPass(
            id: "season_\(seasonNumber)",
            seasonNumber: seasonNumber,
            startDate: startDate,
            endDate: endDate,
            tiers: tiers
        )
    }

    // MARK: - Achievement Tracking

    func checkAchievements(for session: GameSession, userProfile: UserProfile) -> [Achievement] {
        var achievements: [Achievement] = []

        // First song achievement
        if userProfile.totalSongsPlayed == 1 {
            achievements.append(Achievement(
                id: "first_song",
                title: "First Steps",
                description: "Complete your first song",
                icon: "music.note",
                rewardGems: 50
            ))
        }

        // 100 songs achievement
        if userProfile.totalSongsPlayed == 100 {
            achievements.append(Achievement(
                id: "century",
                title: "Century Club",
                description: "Complete 100 songs",
                icon: "star.fill",
                rewardGems: 500
            ))
        }

        // High combo achievement
        if session.maxCombo >= 50 {
            achievements.append(Achievement(
                id: "combo_master",
                title: "Combo Master",
                description: "Achieve a 50x combo",
                icon: "flame.fill",
                rewardGems: 100
            ))
        }

        // Calorie milestone
        if userProfile.totalCaloriesBurned >= 1000 {
            achievements.append(Achievement(
                id: "calorie_crusher",
                title: "Calorie Crusher",
                description: "Burn 1,000 total calories",
                icon: "heart.fill",
                rewardGems: 200
            ))
        }

        // Perfect score achievement
        if session.stars == 3 {
            achievements.append(Achievement(
                id: "perfectionist",
                title: "Perfectionist",
                description: "Get 3 stars on a song",
                icon: "star.circle.fill",
                rewardGems: 75
            ))
        }

        return achievements
    }
}

// MARK: - Achievement Model

struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rewardGems: Int
}
