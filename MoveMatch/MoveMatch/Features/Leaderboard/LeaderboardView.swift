//
//  LeaderboardView.swift
//  MoveMatch
//
//  Global and friend leaderboards
//

import SwiftUI

struct LeaderboardView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LeaderboardViewModel()

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Leaderboard Type", selection: $selectedTab) {
                    Text("Global").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    GlobalLeaderboardView(entries: viewModel.globalLeaderboard)
                        .tag(0)

                    FriendsLeaderboardView(entries: viewModel.friendsLeaderboard)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadLeaderboards(userId: appState.currentUser?.id ?? "")
            }
        }
    }
}

// MARK: - Global Leaderboard

struct GlobalLeaderboardView: View {

    let entries: [LeaderboardEntry]

    var body: some View {
        ScrollView {
            if entries.isEmpty {
                EmptyLeaderboardView(message: "No entries yet. Be the first!")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        LeaderboardRow(
                            rank: index + 1,
                            entry: entry,
                            isCurrentUser: false
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Friends Leaderboard

struct FriendsLeaderboardView: View {

    let entries: [LeaderboardEntry]

    var body: some View {
        ScrollView {
            if entries.isEmpty {
                EmptyLeaderboardView(message: "Add friends to compete!")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        LeaderboardRow(
                            rank: index + 1,
                            entry: entry,
                            isCurrentUser: false
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {

    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 40, height: 40)

                    Text(rankEmoji)
                        .font(.title3)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text("#\(rank)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .purple : .primary)

                Text("Level \(entry.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.totalScore)")
                    .font(.title3.bold())
                    .foregroundColor(.purple)

                Text("\(entry.songsCompleted) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.purple.opacity(0.1) : Color.white)
                .shadow(radius: 2)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .gray
        }
    }

    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

// MARK: - Empty State

struct EmptyLeaderboardView: View {

    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View Model

@MainActor
class LeaderboardViewModel: ObservableObject {

    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var friendsLeaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false

    func loadLeaderboards(userId: String) async {
        isLoading = true

        // Track analytics
        AnalyticsManager.shared.trackScreenView(screen: "leaderboard")

        // Load global leaderboard from Firebase
        do {
            // TODO: Implement Firebase Firestore query
            // For now, use sample data
            globalLeaderboard = generateSampleLeaderboard()
            friendsLeaderboard = generateSampleFriendsLeaderboard()
        }

        isLoading = false
    }

    private func generateSampleLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(id: "1", username: "DanceMaster", level: 25, totalScore: 125000, songsCompleted: 150),
            LeaderboardEntry(id: "2", username: "GrooveQueen", level: 23, totalScore: 118000, songsCompleted: 142),
            LeaderboardEntry(id: "3", username: "RhythmKing", level: 22, totalScore: 112000, songsCompleted: 138),
            LeaderboardEntry(id: "4", username: "BeatStar", level: 20, totalScore: 105000, songsCompleted: 125),
            LeaderboardEntry(id: "5", username: "MoveNinja", level: 19, totalScore: 98000, songsCompleted: 118)
        ]
    }

    private func generateSampleFriendsLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(id: "f1", username: "YourBestFriend", level: 15, totalScore: 75000, songsCompleted: 90),
            LeaderboardEntry(id: "f2", username: "WorkoutBuddy", level: 12, totalScore: 62000, songsCompleted: 75)
        ]
    }
}

// MARK: - Models

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let username: String
    let level: Int
    let totalScore: Int
    let songsCompleted: Int
}
