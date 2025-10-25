import Foundation
import FirebaseAnalytics
import FirebaseFirestore

/// Comprehensive analytics tracking for user behavior, engagement, and monetization
/// Integrates with Firebase Analytics for events and user properties
@MainActor
class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    // MARK: - User Properties

    func setUserProperties(userId: String, profile: UserProfile) {
        Analytics.setUserID(userId)

        // Skill level based on average stars
        let skillLevel: String
        if profile.level < 5 {
            skillLevel = "beginner"
        } else if profile.level < 15 {
            skillLevel = "intermediate"
        } else if profile.level < 30 {
            skillLevel = "advanced"
        } else {
            skillLevel = "expert"
        }
        Analytics.setUserProperty(skillLevel, forName: "skill_level")

        Analytics.setUserProperty("\(profile.level)", forName: "user_level")
        Analytics.setUserProperty(profile.hasSeasonPass ? "true" : "false", forName: "has_season_pass")
        Analytics.setUserProperty(profile.isVIP ? "true" : "false", forName: "is_vip")

        // Engagement tier
        let songsPlayed = profile.totalSongsPlayed ?? 0
        let tier: String
        if songsPlayed < 10 {
            tier = "new"
        } else if songsPlayed < 50 {
            tier = "casual"
        } else if songsPlayed < 200 {
            tier = "regular"
        } else {
            tier = "hardcore"
        }
        Analytics.setUserProperty(tier, forName: "engagement_tier")
    }

    func setFavoriteGenre(_ genre: MusicGenre) {
        Analytics.setUserProperty(genre.rawValue, forName: "favorite_genre")
    }

    func setAverageStars(_ stars: Float) {
        let rounded = String(format: "%.1f", stars)
        Analytics.setUserProperty(rounded, forName: "average_stars")
    }

    // MARK: - Onboarding Events

    func trackOnboardingStarted() {
        Analytics.logEvent("onboarding_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func trackOnboardingStep(step: OnboardingStep, completed: Bool) {
        let eventName = completed ? "onboarding_step_completed" : "onboarding_step_abandoned"

        Analytics.logEvent(eventName, parameters: [
            "step": step.rawValue,
            "step_number": step.stepNumber,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func trackOnboardingCompleted(timeTaken: TimeInterval) {
        Analytics.logEvent("onboarding_completed", parameters: [
            "time_taken_seconds": Int(timeTaken),
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - Gameplay Events

    func trackSongStarted(song: Song, difficulty: Float, userLevel: Int) {
        Analytics.logEvent("song_started", parameters: [
            "song_title": song.title,
            "song_artist": song.artist,
            "genre": song.genre?.rawValue ?? "unknown",
            "bpm": song.bpm,
            "difficulty": difficulty,
            "user_level": userLevel,
            "duration_seconds": song.duration
        ])
    }

    func trackPuzzleAttempted(puzzle: PuzzleChallenge, difficulty: Float) {
        Analytics.logEvent("puzzle_attempted", parameters: [
            "puzzle_type": puzzle.type.rawValue,
            "difficulty": difficulty,
            "duration": puzzle.duration,
            "required_moves": puzzle.requirements.count
        ])
    }

    func trackPuzzleCompleted(puzzle: PuzzleChallenge, accuracy: Float, timeTaken: TimeInterval) {
        Analytics.logEvent("puzzle_completed", parameters: [
            "puzzle_type": puzzle.type.rawValue,
            "accuracy": accuracy,
            "time_taken": timeTaken,
            "perfect": accuracy >= 0.95
        ])
    }

    func trackMovePerformed(move: DetectedMove, wasCorrect: Bool, onBeat: Bool, comboCount: Int) {
        Analytics.logEvent("move_performed", parameters: [
            "move_type": move.rawValue,
            "was_correct": wasCorrect,
            "on_beat": onBeat,
            "combo_count": comboCount
        ])
    }

    func trackComboAchieved(count: Int, maxCombo: Int) {
        Analytics.logEvent("combo_achieved", parameters: [
            "combo_count": count,
            "is_new_record": count > maxCombo
        ])
    }

    func trackSongCompleted(session: GameSession) {
        Analytics.logEvent("song_completed", parameters: [
            "score": session.score,
            "stars": session.starsEarned,
            "accuracy": session.accuracy,
            "max_combo": session.maxCombo,
            "moves_performed": session.movesPerformed.count,
            "calories_burned": session.caloriesBurned,
            "duration_seconds": session.duration,
            "xp_earned": session.xpEarned
        ])
    }

    func trackSongFailed(completionPercent: Float, timeIntoSong: TimeInterval, reason: String) {
        Analytics.logEvent("song_failed", parameters: [
            "completion_percent": completionPercent,
            "time_into_song": timeIntoSong,
            "reason": reason // "quit", "failed", "error"
        ])
    }

    func trackSongPaused(timeIntoSong: TimeInterval, score: Int) {
        Analytics.logEvent("song_paused", parameters: [
            "time_into_song": timeIntoSong,
            "current_score": score
        ])
    }

    // MARK: - Monetization Events

    func trackAdRequested(placement: AdPlacement) {
        Analytics.logEvent("ad_requested", parameters: [
            "placement": placement.rawValue
        ])
    }

    func trackAdLoaded(network: String, placement: AdPlacement) {
        Analytics.logEvent("ad_loaded", parameters: [
            "network": network,
            "placement": placement.rawValue
        ])
    }

    func trackAdImpression(placement: AdPlacement, reward: Int?) {
        var params: [String: Any] = [
            "placement": placement.rawValue
        ]
        if let reward = reward {
            params["reward_amount"] = reward
        }

        Analytics.logEvent("ad_impression", parameters: params)
    }

    func trackAdClicked(placement: AdPlacement) {
        Analytics.logEvent("ad_clicked", parameters: [
            "placement": placement.rawValue
        ])
    }

    func trackAdFailed(error: String, placement: AdPlacement) {
        Analytics.logEvent("ad_failed", parameters: [
            "error": error,
            "placement": placement.rawValue
        ])
    }

    func trackIAPInitiated(productId: String, price: Decimal) {
        Analytics.logEvent("iap_initiated", parameters: [
            "product_id": productId,
            "price": NSDecimalNumber(decimal: price).doubleValue
        ])
    }

    func trackIAPCompleted(productId: String, revenue: Decimal, currency: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterValue: NSDecimalNumber(decimal: revenue).doubleValue,
            AnalyticsParameterCurrency: currency
        ])
    }

    func trackIAPCancelled(productId: String, step: String) {
        Analytics.logEvent("iap_cancelled", parameters: [
            "product_id": productId,
            "step": step // "payment_sheet", "verification", "user_cancelled"
        ])
    }

    func trackIAPRestored(productsRestored: Int) {
        Analytics.logEvent("iap_restored", parameters: [
            "products_restored": productsRestored
        ])
    }

    // MARK: - Engagement Events

    func trackDailyQuestViewed() {
        Analytics.logEvent("daily_quest_viewed", parameters: [:])
    }

    func trackDailyQuestCompleted(questId: String, reward: Int) {
        Analytics.logEvent("daily_quest_completed", parameters: [
            "quest_id": questId,
            "reward_xp": reward
        ])
    }

    func trackProfileViewed() {
        Analytics.logEvent("profile_viewed", parameters: [:])
    }

    func trackShopViewed(tab: ShopTab) {
        Analytics.logEvent("shop_viewed", parameters: [
            "tab": tab.rawValue
        ])
    }

    func trackLeaderboardViewed(timeframe: LeaderboardTimeframe) {
        Analytics.logEvent("leaderboard_viewed", parameters: [
            "timeframe": timeframe.rawValue
        ])
    }

    func trackAchievementUnlocked(achievementId: String, rewardCoins: Int) {
        Analytics.logEvent("achievement_unlocked", parameters: [
            "achievement_id": achievementId,
            "reward_coins": rewardCoins
        ])
    }

    func trackLevelUp(newLevel: Int, xpEarned: Int, rewardCoins: Int) {
        Analytics.logEvent(AnalyticsEventLevelUp, parameters: [
            AnalyticsParameterLevel: newLevel,
            "xp_earned": xpEarned,
            "reward_coins": rewardCoins
        ])
    }

    func trackMoveUnlocked(move: DetectedMove, unlockMethod: String) {
        Analytics.logEvent("move_unlocked", parameters: [
            "move": move.rawValue,
            "unlock_method": unlockMethod // "level_up", "purchased", "season_pass"
        ])
    }

    // MARK: - Session Events

    func trackSessionStarted() {
        Analytics.logEvent("session_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    func trackSessionEnded(duration: TimeInterval, songsPlayed: Int, xpEarned: Int) {
        Analytics.logEvent("session_ended", parameters: [
            "duration_seconds": Int(duration),
            "songs_played": songsPlayed,
            "xp_earned": xpEarned
        ])
    }

    // MARK: - Retention Events

    func trackDayNRetention(day: Int, isReturning: Bool) {
        Analytics.logEvent("day_\(day)_retention", parameters: [
            "is_returning": isReturning,
            "retention_day": day
        ])
    }

    // MARK: - Social Events

    func trackTikTokShareAttempt(sessionId: String) {
        Analytics.logEvent("tiktok_share_attempted", parameters: [
            "session_id": sessionId
        ])
    }

    func trackTikTokShareCompleted(sessionId: String) {
        Analytics.logEvent("tiktok_share_completed", parameters: [
            "session_id": sessionId
        ])
    }

    // MARK: - Error Events

    func trackError(category: ErrorCategory, message: String, isCritical: Bool) {
        Analytics.logEvent("app_error", parameters: [
            "category": category.rawValue,
            "message": message,
            "is_critical": isCritical
        ])
    }

    // MARK: - Custom Conversion Events

    func trackFirstSongCompleted(timeSinceInstall: TimeInterval) {
        Analytics.logEvent("first_song_completed", parameters: [
            "time_since_install_seconds": Int(timeSinceInstall)
        ])
    }

    func trackFirstPurchase(productId: String, daysSinceInstall: Int) {
        Analytics.logEvent("first_purchase", parameters: [
            "product_id": productId,
            "days_since_install": daysSinceInstall
        ])
    }

    func trackCalibrationCompleted(attempts: Int, timeTaken: TimeInterval) {
        Analytics.logEvent("calibration_completed", parameters: [
            "attempts": attempts,
            "time_taken": timeTaken
        ])
    }

    func trackPermissionGranted(permission: PermissionType) {
        Analytics.logEvent("permission_granted", parameters: [
            "permission": permission.rawValue
        ])
    }

    func trackPermissionDenied(permission: PermissionType) {
        Analytics.logEvent("permission_denied", parameters: [
            "permission": permission.rawValue
        ])
    }
}

// MARK: - Supporting Types

enum OnboardingStep: String {
    case welcome = "welcome"
    case permissions = "permissions"
    case calibration = "calibration"
    case firstSong = "first_song"
    case completion = "completion"

    var stepNumber: Int {
        switch self {
        case .welcome: return 1
        case .permissions: return 2
        case .calibration: return 3
        case .firstSong: return 4
        case .completion: return 5
        }
    }
}

enum AdPlacement: String {
    case resultsScreen = "results_screen"
    case levelUp = "level_up"
    case shopOffer = "shop_offer"
}

enum ShopTab: String {
    case gems = "gems"
    case moves = "moves"
    case vip = "vip"
}

enum ErrorCategory: String {
    case arkit = "arkit"
    case audio = "audio"
    case firebase = "firebase"
    case iap = "iap"
    case network = "network"
    case general = "general"
}

enum PermissionType: String {
    case camera = "camera"
    case music = "music"
    case microphone = "microphone"
    case photos = "photos"
}

// MARK: - Funnel Tracking Helper

extension AnalyticsManager {
    /// Track complete onboarding funnel
    func trackOnboardingFunnel(userId: String, installDate: Date) {
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0

        // Set user properties for cohort analysis
        Analytics.setUserProperty(installDate.formatted(), forName: "install_date")
        Analytics.setUserProperty("\(daysSinceInstall)", forName: "days_since_install")
    }

    /// Track monetization funnel
    func trackMonetizationFunnel(step: MonetizationStep, productId: String? = nil) {
        var params: [String: Any] = [
            "step": step.rawValue
        ]
        if let productId = productId {
            params["product_id"] = productId
        }

        Analytics.logEvent("monetization_funnel", parameters: params)
    }

    enum MonetizationStep: String {
        case shopViewed = "shop_viewed"
        case productViewed = "product_viewed"
        case purchaseInitiated = "purchase_initiated"
        case paymentShown = "payment_shown"
        case purchaseCompleted = "purchase_completed"
    }
}
