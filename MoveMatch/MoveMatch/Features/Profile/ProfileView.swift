//
//  ProfileView.swift
//  MoveMatch
//
//  User profile and statistics
//

import SwiftUI

struct ProfileView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    var user: UserProfile? {
        appState.currentUser
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Profile header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Text(String(user?.displayName.prefix(1) ?? "P"))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text(user?.displayName ?? "Player")
                            .font(.title2.bold())

                        // Level progress
                        VStack(spacing: 8) {
                            HStack {
                                Text("Level \(user?.level ?? 1)")
                                    .font(.headline)

                                Spacer()

                                Text("\(user?.totalXP ?? 0) / \(user?.xpToNextLevel ?? 1000) XP")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(user?.xpProgress ?? 0))
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()

                    // Stats section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            StatRow(
                                icon: "music.note",
                                label: "Songs Played",
                                value: "\(user?.totalSongsPlayed ?? 0)"
                            )

                            StatRow(
                                icon: "flame.fill",
                                label: "Calories Burned",
                                value: "\(user?.totalCaloriesBurned ?? 0)"
                            )

                            StatRow(
                                icon: "bolt.fill",
                                label: "Max Combo",
                                value: "\(user?.totalComboStreak ?? 0)"
                            )

                            StatRow(
                                icon: "star.fill",
                                label: "Average Stars",
                                value: String(format: "%.1f", user?.averageStars ?? 0)
                            )
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Unlocks section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Unlocked Moves")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                            ForEach(user?.unlockedMoves ?? [.jump, .squat], id: \.self) { move in
                                VStack(spacing: 8) {
                                    Text(move.emoji)
                                        .font(.system(size: 40))

                                    Text(move.displayName)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Currency
                    HStack(spacing: 16) {
                        CurrencyBox(icon: "dollarsign.circle.fill", label: "Coins", amount: user?.coins ?? 0, color: .yellow)
                        CurrencyBox(icon: "gem.fill", label: "Gems", amount: user?.gems ?? 0, color: .cyan)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {

    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
        }
    }
}

struct CurrencyBox: View {

    let icon: String
    let label: String
    let amount: Int
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(amount)")
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
