//
//  MainMenuView.swift
//  MoveMatch
//
//  Main navigation hub
//

import SwiftUI

struct MainMenuView: View {

    @EnvironmentObject var appState: AppState
    @State private var showingSongSelection = false
    @State private var showingProfile = false
    @State private var showingShop = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {

                    // Header with user info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(appState.currentUser?.displayName ?? "Player")
                                .font(.title2.bold())
                        }

                        Spacer()

                        // Level badge
                        VStack {
                            Text("Level")
                                .font(.caption)
                            Text("\(appState.currentUser?.level ?? 1)")
                                .font(.title.bold())
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Stats cards
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "music.note",
                            value: "\(appState.currentUser?.totalSongsPlayed ?? 0)",
                            label: "Songs"
                        )

                        StatCard(
                            icon: "flame.fill",
                            value: "\(appState.currentUser?.totalCaloriesBurned ?? 0)",
                            label: "Calories"
                        )

                        StatCard(
                            icon: "star.fill",
                            value: String(format: "%.1f", appState.currentUser?.averageStars ?? 0),
                            label: "Avg Stars"
                        )
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Main play button
                    Button {
                        showingSongSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                            Text("Play Now")
                                .font(.title2.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(radius: 8)
                    }
                    .padding(.horizontal, 40)

                    // Secondary actions
                    HStack(spacing: 16) {
                        MenuButton(icon: "person.fill", title: "Profile") {
                            showingProfile = true
                        }

                        MenuButton(icon: "cart.fill", title: "Shop") {
                            showingShop = true
                        }

                        MenuButton(icon: "chart.bar.fill", title: "Leaderboard") {
                            // TODO: Show leaderboard
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showingSongSelection) {
                SongSelectionView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingShop) {
                ShopView()
            }
        }
    }
}

struct StatCard: View {

    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)

            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct MenuButton: View {

    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}
