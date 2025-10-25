import SwiftUI

// MARK: - Skeleton Loading Views
// Provides placeholder UI while content loads to improve perceived performance

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Skeleton Song Card

struct SkeletonSongCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork placeholder
            SkeletonView()
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                // Title
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(4)

                // Artist
                SkeletonView()
                    .frame(height: 12)
                    .frame(width: 120)
                    .cornerRadius(4)

                // Metadata (BPM, duration)
                HStack(spacing: 8) {
                    SkeletonView()
                        .frame(width: 60, height: 10)
                        .cornerRadius(4)

                    SkeletonView()
                        .frame(width: 40, height: 10)
                        .cornerRadius(4)
                }
            }

            Spacer()

            // Chevron
            SkeletonView()
                .frame(width: 20, height: 20)
                .cornerRadius(10)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .accessibilityLabel("Loading song")
    }
}

// MARK: - Skeleton Song List

struct SkeletonSongList: View {
    let count: Int

    init(count: Int = 10) {
        self.count = count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonSongCard()
                }
            }
            .padding()
        }
        .accessibilityLabel("Loading songs")
    }
}

// MARK: - Skeleton Profile View

struct SkeletonProfileView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Avatar
            SkeletonView()
                .frame(width: 100, height: 100)
                .clipShape(Circle())

            // Display name
            SkeletonView()
                .frame(width: 150, height: 24)
                .cornerRadius(8)

            // Level badge
            SkeletonView()
                .frame(width: 80, height: 80)
                .clipShape(Circle())

            // XP Progress
            VStack(spacing: 8) {
                SkeletonView()
                    .frame(height: 12)
                    .cornerRadius(6)

                SkeletonView()
                    .frame(width: 100, height: 10)
                    .cornerRadius(4)
            }
            .padding(.horizontal)

            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonView()
                            .frame(height: 32)
                            .cornerRadius(8)

                        SkeletonView()
                            .frame(height: 14)
                            .cornerRadius(4)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
        .accessibilityLabel("Loading profile")
    }
}

// MARK: - Skeleton Leaderboard

struct SkeletonLeaderboard: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<10, id: \.self) { index in
                HStack(spacing: 12) {
                    // Rank
                    SkeletonView()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())

                    // Avatar
                    SkeletonView()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                    // Name
                    SkeletonView()
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(4)

                    // Score
                    SkeletonView()
                        .frame(width: 60, height: 20)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .accessibilityLabel("Loading leaderboard")
    }
}

// MARK: - Loading Progress View

struct LoadingProgressView: View {
    let title: String
    let subtitle: String?
    let progress: Double? // 0.0 to 1.0, nil for indeterminate

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            if let progress = progress {
                // Determinate progress
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.purple,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: progress)

                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(width: 80, height: 80)
            } else {
                // Indeterminate progress
                if reduceMotion {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }

            // Title
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle ?? "")")
        .if(progress != nil) { view in
            view.accessibilityValue("\(Int(progress! * 100))% complete")
        }
    }
}

// MARK: - Song Analysis Loading View

struct SongAnalysisLoadingView: View {
    let song: Song
    @State private var currentStep = 0

    let steps = [
        "Loading audio file...",
        "Detecting BPM...",
        "Analyzing energy...",
        "Classifying genre...",
        "Generating puzzles..."
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Album art with loading overlay
            ZStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)

                ProgressView()
                    .scaleEffect(1.5)
            }

            // Song info
            VStack(spacing: 8) {
                Text(song.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress steps
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        if index < currentStep {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if index == currentStep {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }

                        Text(steps[index])
                            .font(.caption)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(32)
        .onAppear {
            startStepAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing \(song.title) by \(song.artist)")
        .accessibilityValue(steps[currentStep])
    }

    private func startStepAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(40)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)

                Text("You're offline - progress will sync when reconnected")
                    .font(.caption)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding()
            .background(Color.orange)
            .transition(.move(edge: .top))
            .accessibilityLabel("Offline mode active")
        }
    }
}

// MARK: - Conditional View Extension

extension View {
    @ViewBuilder
    func skeleton(when loading: Bool, @ViewBuilder skeleton: () -> some View) -> some View {
        if loading {
            skeleton()
        } else {
            self
        }
    }
}

// MARK: - Usage Examples in Comments

/*
 USAGE EXAMPLES:

 1. Song List with Skeleton:
 ```
 if isLoading {
     SkeletonSongList()
 } else {
     SongList(songs)
 }
 ```

 2. Song Analysis Progress:
 ```
 SongAnalysisLoadingView(song: selectedSong)
 ```

 3. Generic Loading:
 ```
 LoadingProgressView(
     title: "Loading Profile",
     subtitle: "Please wait...",
     progress: 0.7
 )
 ```

 4. Empty State:
 ```
 EmptyStateView(
     icon: "music.note.list",
     title: "No Songs Found",
     message: "Add music to your library to get started!",
     actionTitle: "Open Music App",
     action: { openMusicApp() }
 )
 ```

 5. Offline Banner:
 ```
 VStack {
     OfflineBanner()
     MainContent()
 }
 ```
 */
