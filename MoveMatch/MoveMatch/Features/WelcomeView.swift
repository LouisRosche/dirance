//
//  WelcomeView.swift
//  MoveMatch
//
//  Onboarding and sign-in screen
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject var appState: AppState
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "figure.dance")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .accessibilityLabel("Dance icon")

                    Text("Move Match")
                        .font(.gameTitle())
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)

                    Text("Dance to your music,\nsolve puzzles, get fit")
                        .font(.gameBody())
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "camera.fill", text: "Uses your iPhone camera")
                    FeatureRow(icon: "music.note", text: "Play any song from your library")
                    FeatureRow(icon: "flame.fill", text: "Burn calories while gaming")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Level up and unlock moves")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign in button
                Button {
                    signIn()
                } label: {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Image(systemName: "applelogo")
                            Text("Sign in with Apple")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .disabled(isSigningIn)
                .minimumTouchTarget()
                .accessibilityLabel("Sign in with Apple")
                .accessibilityHint("Authenticate to start playing Move Match")

                Text("By signing in, you agree to our Terms of Service")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
    }

    private func signIn() {
        isSigningIn = true

        // Track analytics: onboarding started
        AnalyticsManager.shared.trackOnboardingStarted()

        // Haptic feedback
        HapticManager.shared.buttonTap()

        Task {
            do {
                await appState.signIn()

                // Track analytics: onboarding completed
                AnalyticsManager.shared.trackOnboardingStep(step: .completion, completed: true)

                // Haptic feedback for success
                HapticManager.shared.success()
            } catch {
                // Handle error
                ErrorHandler.shared.handle(.firebase(.authenticationFailed)) {
                    signIn() // Retry
                }
            }
            isSigningIn = false
        }
    }
}

// MARK: - Onboarding Entry Point

extension WelcomeView {
    func onAppear() {
        // Track screen view
        AnalyticsManager.shared.trackOnboardingStarted()
    }
}

struct FeatureRow: View {

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}
