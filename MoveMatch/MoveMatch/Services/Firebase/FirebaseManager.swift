//
//  FirebaseManager.swift
//  MoveMatch
//
//  Firebase authentication, Firestore, and analytics
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseRemoteConfig
import AuthenticationServices

class FirebaseManager {

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let remoteConfig = RemoteConfig.remoteConfig()

    // MARK: - Authentication

    func getCurrentUserId() async -> String? {
        return auth.currentUser?.uid
    }

    func signInWithApple() async throws -> String {
        // This would use AuthenticationServices in production
        // For now, anonymous sign-in as fallback

        do {
            let result = try await auth.signInAnonymously()
            return result.user.uid
        } catch {
            throw error
        }
    }

    func signOut() {
        try? auth.signOut()
    }

    // MARK: - Firestore - User Profiles

    func getUserProfile(userId: String) async throws -> UserProfile? {
        let docRef = db.collection("users").document(userId)

        do {
            let document = try await docRef.getDocument()

            guard document.exists,
                  let data = document.data() else {
                return nil
            }

            return try Firestore.Decoder().decode(UserProfile.self, from: data)
        } catch {
            throw error
        }
    }

    func saveUserProfile(profile: UserProfile) async throws {
        let docRef = db.collection("users").document(profile.id)

        do {
            let data = try Firestore.Encoder().encode(profile)
            try await docRef.setData(data)
        } catch {
            throw error
        }
    }

    // MARK: - Firestore - Game Sessions

    func saveSession(session: GameSession) async throws {
        let docRef = db.collection("sessions").document(session.id.uuidString)

        do {
            let data = try Firestore.Encoder().encode(session)
            try await docRef.setData(data)

            // Also save to user's sessions subcollection
            let userSessionRef = db.collection("users")
                .document(session.userId)
                .collection("sessions")
                .document(session.id.uuidString)

            try await userSessionRef.setData(data)

            // Log analytics event
            logEvent("song_completed", parameters: [
                "song_id": session.songId,
                "score": session.score,
                "stars": session.stars,
                "puzzles_completed": session.puzzlesCompleted
            ])

        } catch {
            throw error
        }
    }

    func getUserSessions(userId: String, limit: Int = 20) async throws -> [GameSession] {
        let query = db.collection("users")
            .document(userId)
            .collection("sessions")
            .order(by: "startTime", descending: true)
            .limit(to: limit)

        do {
            let snapshot = try await query.getDocuments()

            return snapshot.documents.compactMap { doc in
                try? Firestore.Decoder().decode(GameSession.self, from: doc.data())
            }
        } catch {
            throw error
        }
    }

    // MARK: - Leaderboards (using Firestore, not Redis for MVP)

    func updateLeaderboard(userId: String, displayName: String, score: Int, timeframe: LeaderboardTimeframe) async throws {

        let leaderboardId = "leaderboard_\(timeframe.rawValue)"
        let docRef = db.collection(leaderboardId).document(userId)

        let data: [String: Any] = [
            "userId": userId,
            "displayName": displayName,
            "score": score,
            "timestamp": FieldValue.serverTimestamp()
        ]

        try await docRef.setData(data, merge: true)
    }

    func getLeaderboard(timeframe: LeaderboardTimeframe, limit: Int = 100) async throws -> [LeaderboardEntry] {

        let leaderboardId = "leaderboard_\(timeframe.rawValue)"

        let query = db.collection(leaderboardId)
            .order(by: "score", descending: true)
            .limit(to: limit)

        do {
            let snapshot = try await query.getDocuments()

            return snapshot.documents.enumerated().compactMap { index, doc in
                guard let userId = doc.data()["userId"] as? String,
                      let displayName = doc.data()["displayName"] as? String,
                      let score = doc.data()["score"] as? Int,
                      let timestamp = (doc.data()["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }

                return LeaderboardEntry(
                    id: userId,
                    userId: userId,
                    displayName: displayName,
                    score: score,
                    rank: index + 1,
                    timestamp: timestamp
                )
            }
        } catch {
            throw error
        }
    }

    // MARK: - Remote Config

    func fetchRemoteConfig() async {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings

        // Set defaults
        remoteConfig.setDefaults([
            "season_pass_price_usd": 4.99,
            "base_difficulty_multiplier": 1.0,
            "enable_spin_move": true,
            "double_xp_event_active": false,
            "rewarded_ad_frequency": 2
        ])

        do {
            try await remoteConfig.fetch()
            try await remoteConfig.activate()
        } catch {
            print("❌ Remote config fetch failed: \(error)")
        }
    }

    func getRemoteConfigValue<T>(_ key: String, defaultValue: T) -> T {
        let configValue = remoteConfig[key]

        if T.self == Bool.self {
            return configValue.boolValue as! T
        } else if T.self == Int.self {
            return Int(configValue.numberValue) as! T
        } else if T.self == Float.self {
            return Float(configValue.numberValue) as! T
        } else if T.self == String.self {
            return configValue.stringValue as! T
        }

        return defaultValue
    }

    // MARK: - Analytics

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
