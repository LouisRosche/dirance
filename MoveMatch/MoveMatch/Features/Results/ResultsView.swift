//
//  ResultsView.swift
//  MoveMatch
//
//  Post-game results screen
//

import SwiftUI

struct ResultsView: View {

    let session: GameSession
    let song: Song

    @Environment(\.dismiss) var dismiss
    @State private var showingAdOffer = false
    @State private var rewardMultiplier: Float = 1.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    // Stars
                    AccessibleStarRating(stars: session.stars)

                    Text(session.stars == 3 ? "Perfect!" : session.stars == 2 ? "Great!" : session.stars == 1 ? "Good!" : "Keep trying!")
                        .font(.title.bold())

                    Text(song.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Stats grid
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatBox(label: "Score", value: "\(session.score)", icon: "star.fill")
                        StatBox(label: "Max Combo", value: "\(session.maxCombo)x", icon: "flame.fill")
                    }

                    HStack(spacing: 16) {
                        StatBox(label: "Puzzles", value: "\(session.puzzlesCompleted)/\(session.totalPuzzles)", icon: "puzzlepiece.fill")
                        StatBox(label: "Calories", value: "\(session.caloriesBurned)", icon: "heart.fill")
                    }
                }
                .padding(.horizontal)

                // XP earned
                VStack(spacing: 8) {
                    Text("XP Earned")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.purple)

                        Text("+\(Int(Float(session.score) / 10 * rewardMultiplier))")
                            .font(.title.bold())
                            .foregroundColor(.purple)
                    }

                    if rewardMultiplier > 1.0 {
                        Text("Bonus applied! (\(Int((rewardMultiplier - 1.0) * 100))%)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Ad offer (if not already watched)
                    if !showingAdOffer && rewardMultiplier == 1.0 {
                        Button {
                            showAdOffer()
                        } label: {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text("Watch Ad to Double XP")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .minimumTouchTarget()
                        .accessibilityLabel("Watch advertisement to double experience points")
                        .hapticFeedback(.selection)
                    }

                    // Continue button
                    Button {
                        continueToMenu()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .minimumTouchTarget()
                    .accessibilityLabel("Continue to main menu")
                    .hapticFeedback(.selection)

                }
                .padding(.bottom, 20)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            // Track analytics: results screen viewed
            AnalyticsManager.shared.trackSongCompleted(session: session)

            // Haptic feedback based on stars
            HapticManager.shared.sessionCompleted(stars: session.stars)

            // Announce results to VoiceOver
            let starsText = session.stars == 1 ? "one star" : "\(session.stars) stars"
            AccessibilityAnnouncer.announce("Song completed with \(starsText). Score: \(session.score)")
        }
    }

    private func showAdOffer() {
        showingAdOffer = true

        // Track analytics: ad requested
        AnalyticsManager.shared.trackAdRequested(placement: .resultsScreen)

        // Haptic feedback
        HapticManager.shared.buttonTap()

        // Show rewarded ad
        Task {
            let adManager = AdManager.shared
            adManager.loadRewardedAd()

            // Wait for ad to load
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            if adManager.isAdReady {
                // Track ad impression
                AnalyticsManager.shared.trackAdImpression(placement: .resultsScreen, reward: 2)

                // Simulate ad showing (in real implementation, would call AdMob)
                try? await Task.sleep(nanoseconds: 3_000_000_000)

                // Apply reward
                rewardMultiplier = 2.0

                // Haptic feedback for reward
                HapticManager.shared.success()

                // Announce reward to VoiceOver
                AccessibilityAnnouncer.announce("Bonus applied! XP doubled")
            } else {
                // Track ad failure
                AnalyticsManager.shared.trackAdFailed(error: "no_fill", placement: .resultsScreen)

                // Graceful fallback: give reward anyway
                rewardMultiplier = 2.0

                // Haptic feedback
                HapticManager.shared.warning()
            }

            showingAdOffer = false
        }
    }

    private func continueToMenu() {
        // Haptic feedback
        HapticManager.shared.buttonTap()

        dismiss()
    }
}

struct StatBox: View {

    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
