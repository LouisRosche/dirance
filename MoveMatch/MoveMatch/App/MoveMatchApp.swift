//
//  MoveMatchApp.swift
//  MoveMatch
//
//  Main app entry point
//

import SwiftUI
import FirebaseCore

@main
struct MoveMatchApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Configure Firebase
        FirebaseApp.configure()

        // Configure audio session
        configureAudioSession()

        return true
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var songs: [Song] = []
    @Published var isLoadingSongs = false

    // Managers
    let firebaseManager = FirebaseManager()
    let musicLibrary = MusicLibraryManager()
    let progressionManager = ProgressionManager()

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        Task {
            if let userId = await firebaseManager.getCurrentUserId() {
                isAuthenticated = true
                await loadUserProfile(userId: userId)
                await loadSongs()
            }
        }
    }

    func signIn() async {
        do {
            let userId = try await firebaseManager.signInWithApple()
            isAuthenticated = true
            await loadUserProfile(userId: userId)
            await loadSongs()
        } catch {
            print("❌ Sign in failed: \(error)")
        }
    }

    func signOut() {
        firebaseManager.signOut()
        isAuthenticated = false
        currentUser = nil
        songs = []
    }

    private func loadUserProfile(userId: String) async {
        do {
            if let profile = try await firebaseManager.getUserProfile(userId: userId) {
                currentUser = profile
            } else {
                // Create new profile
                let newProfile = UserProfile(id: userId, displayName: "Player")
                try await firebaseManager.saveUserProfile(profile: newProfile)
                currentUser = newProfile
            }
        } catch {
            print("❌ Failed to load profile: \(error)")
        }
    }

    private func loadSongs() async {
        isLoadingSongs = true

        // Request authorization
        let authorized = await musicLibrary.requestAuthorization()
        guard authorized else {
            isLoadingSongs = false
            return
        }

        // Fetch songs
        songs = musicLibrary.fetchUserSongs()

        isLoadingSongs = false
    }

    func analyzeSong(_ song: Song) async -> Song {
        do {
            return try await musicLibrary.analyzeSong(song)
        } catch {
            print("❌ Song analysis failed: \(error)")
            return song
        }
    }
}

// MARK: - Content View

struct ContentView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainMenuView()
            } else {
                WelcomeView()
            }
        }
    }
}
