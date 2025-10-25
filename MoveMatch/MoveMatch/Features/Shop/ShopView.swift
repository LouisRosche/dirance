//
//  ShopView.swift
//  MoveMatch
//
//  In-app purchase shop
//

import SwiftUI

struct ShopView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack {
                // Tab picker
                Picker("Shop Category", selection: $selectedTab) {
                    Text("Gems").tag(0)
                    Text("Moves").tag(1)
                    Text("VIP").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    GemsShopView()
                        .tag(0)

                    MovesShopView()
                        .tag(1)

                    VIPShopView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Shop")
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

// MARK: - Gems Shop

struct GemsShopView: View {

    @EnvironmentObject var appState: AppState

    let products: [(String, Int, String, String)] = [
        ("Starter Pack", 100, "$0.99", "gem.fill"),
        ("Popular Pack", 500, "$2.99", "sparkles"),
        ("Mega Pack", 1500, "$9.99", "star.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(products, id: \.0) { product in
                    ProductCard(
                        title: product.0,
                        subtitle: "\(product.1) Gems",
                        price: product.2,
                        icon: product.3,
                        iconColor: .cyan
                    ) {
                        purchaseProduct(product)
                    }
                }

                Text("Gems can be used to unlock moves, power-ups, and more!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding()
        }
    }

    private func purchaseProduct(_ product: (String, Int, String, String)) {
        // TODO: Integrate StoreKit
        print("Purchasing: \(product.0)")

        // Simulate purchase
        if var user = appState.currentUser {
            user.addGems(product.1)
            appState.currentUser = user
        }
    }
}

// MARK: - Moves Shop

struct MovesShopView: View {

    @EnvironmentObject var appState: AppState

    let moves: [(DetectedMove, Int, String)] = [
        (.spin, 100, "Advanced spinning move"),
        (.sideStepLeft, 50, "Side step moves"),
        (.sideStepRight, 50, "Side step moves")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(moves, id: \.0) { move in
                    MoveCard(
                        move: move.0,
                        cost: move.1,
                        description: move.2,
                        isUnlocked: appState.currentUser?.unlockedMoves.contains(move.0) ?? false
                    ) {
                        unlockMove(move.0, cost: move.1)
                    }
                }
            }
            .padding()
        }
    }

    private func unlockMove(_ move: DetectedMove, cost: Int) {
        guard var user = appState.currentUser else { return }

        guard user.spendGems(cost) else {
            // Show "not enough gems" alert
            return
        }

        if !user.unlockedMoves.contains(move) {
            user.unlockedMoves.append(move)
        }

        appState.currentUser = user

        // Save to Firebase
        Task {
            try? await appState.firebaseManager.saveUserProfile(profile: user)
        }
    }
}

// MARK: - VIP Shop

struct VIPShopView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // VIP benefits
                VStack(alignment: .leading, spacing: 16) {
                    Text("VIP Membership")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(icon: "xmark.circle.fill", text: "No ads ever", color: .green)
                        BenefitRow(icon: "star.fill", text: "2x XP on all songs", color: .purple)
                        BenefitRow(icon: "music.note", text: "Exclusive weekly songs", color: .pink)
                        BenefitRow(icon: "crown.fill", text: "VIP badge on profile", color: .yellow)
                        BenefitRow(icon: "sparkles", text: "Premium AR filters", color: .cyan)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)

                // Subscribe button
                if !(appState.currentUser?.isVIP ?? false) {
                    Button {
                        subscribeToVIP()
                    } label: {
                        VStack(spacing: 8) {
                            Text("Subscribe to VIP")
                                .font(.headline)

                            Text("$9.99/month • Cancel anytime")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("You're a VIP Member!")
                            .font(.headline)
                            .foregroundColor(.purple)

                        if let expiry = appState.currentUser?.vipExpiry {
                            Text("Renews: \(expiry, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Button("Manage Subscription") {
                            // Open App Store subscriptions
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private func subscribeToVIP() {
        // TODO: Integrate StoreKit subscriptions
        print("Subscribing to VIP...")

        // Simulate subscription
        if var user = appState.currentUser {
            user.isVIP = true
            user.vipExpiry = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            appState.currentUser = user
        }
    }
}

// MARK: - Supporting Views

struct ProductCard: View {

    let title: String
    let subtitle: String
    let price: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
                    .foregroundColor(.purple)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}

struct MoveCard: View {

    let move: DetectedMove
    let cost: Int
    let description: String
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(move.emoji)
                .font(.system(size: 40))
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(move.displayName)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: "gem.fill")
                            .foregroundColor(.cyan)

                        Text("\(cost)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(isUnlocked ? 0.5 : 1.0)
    }
}

struct BenefitRow: View {

    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }
}
