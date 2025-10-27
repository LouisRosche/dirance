import Foundation
import SwiftUI

/// Comprehensive error types for the app with user-friendly messages
enum AppError: LocalizedError, Identifiable {
    case arkit(ARKitError)
    case audio(AudioError)
    case firebase(FirebaseError)
    case iap(IAPError)
    case network(NetworkError)
    case general(String)

    var id: String {
        errorDescription ?? "unknown_error"
    }

    var errorDescription: String? {
        switch self {
        case .arkit(let error):
            return error.userMessage
        case .audio(let error):
            return error.userMessage
        case .firebase(let error):
            return error.userMessage
        case .iap(let error):
            return error.userMessage
        case .network(let error):
            return error.userMessage
        case .general(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .arkit(let error):
            return error.recoverySuggestion
        case .audio(let error):
            return error.recoverySuggestion
        case .firebase(let error):
            return error.recoverySuggestion
        case .iap(let error):
            return error.recoverySuggestion
        case .network(let error):
            return error.recoverySuggestion
        case .general:
            return "Please try again or contact support if the problem persists."
        }
    }

    var icon: String {
        switch self {
        case .arkit: return "camera.fill"
        case .audio: return "music.note"
        case .firebase: return "cloud.fill"
        case .iap: return "cart.fill"
        case .network: return "wifi.slash"
        case .general: return "exclamationmark.triangle.fill"
        }
    }

    var isCritical: Bool {
        switch self {
        case .arkit(.deviceNotSupported), .arkit(.cameraPermissionDenied):
            return true
        case .network(.offline):
            return false // App can work offline
        default:
            return false
        }
    }
}

// MARK: - ARKit Errors

enum ARKitError {
    case deviceNotSupported
    case cameraPermissionDenied
    case trackingFailed
    case calibrationFailed
    case sessionInterrupted

    var userMessage: String {
        switch self {
        case .deviceNotSupported:
            return "Your device doesn't support AR body tracking. Move Match requires iPhone XS or newer."
        case .cameraPermissionDenied:
            return "Camera access is required for body tracking. Please enable it in Settings."
        case .trackingFailed:
            return "Having trouble tracking your movements. Try improving lighting or moving to a clearer space."
        case .calibrationFailed:
            return "Calibration failed. Make sure you're standing 2-3 meters from your device with good lighting."
        case .sessionInterrupted:
            return "AR session was interrupted. The game will resume automatically."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .deviceNotSupported:
            return "Upgrade to iPhone XS or newer to use Move Match."
        case .cameraPermissionDenied:
            return "Go to Settings → Move Match → Camera and enable access."
        case .trackingFailed:
            return "Improve lighting and ensure your full body is visible in the camera frame."
        case .calibrationFailed:
            return "Stand still facing your device and try calibration again."
        case .sessionInterrupted:
            return "The game will automatically resume when ready."
        }
    }
}

// MARK: - Audio Errors

enum AudioError {
    case noSongsInLibrary
    case musicPermissionDenied
    case songNotFound
    case analysisFailed
    case playbackFailed
    case drmRestricted

    var userMessage: String {
        switch self {
        case .noSongsInLibrary:
            return "No songs found in your library. Add some music to get started!"
        case .musicPermissionDenied:
            return "Music library access is required. Please enable it in Settings."
        case .songNotFound:
            return "Couldn't find that song. It may have been removed from your library."
        case .analysisFailed:
            return "Failed to analyze this song. It might be corrupted or in an unsupported format."
        case .playbackFailed:
            return "Couldn't play this song. Try another one."
        case .drmRestricted:
            return "This song is protected and can't be analyzed. Try a different song or purchased music."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .noSongsInLibrary:
            return "Add music through the Music app or Apple Music."
        case .musicPermissionDenied:
            return "Go to Settings → Move Match → Media & Apple Music and enable access."
        case .songNotFound:
            return "Try selecting a different song."
        case .analysisFailed:
            return "Skip this song and try another one."
        case .playbackFailed:
            return "Select a different song to continue."
        case .drmRestricted:
            return "Use songs purchased from iTunes or DRM-free files."
        }
    }
}

// MARK: - Firebase Errors

enum FirebaseError {
    case notInitialized
    case authenticationFailed
    case saveFailed
    case loadFailed
    case networkTimeout

    var userMessage: String {
        switch self {
        case .notInitialized:
            return "App initialization failed. Please restart the app."
        case .authenticationFailed:
            return "Couldn't sign you in. Please try again."
        case .saveFailed:
            return "Failed to save your progress. Don't worry, it's saved locally and will sync when possible."
        case .loadFailed:
            return "Couldn't load your data. You may see outdated information."
        case .networkTimeout:
            return "Connection timed out. Check your internet connection."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .notInitialized:
            return "Restart the app. If the problem continues, reinstall the app."
        case .authenticationFailed:
            return "Check your internet connection and try signing in again."
        case .saveFailed:
            return "Your progress is safe locally. It will sync automatically when online."
        case .loadFailed:
            return "Check your internet connection. Your local data is still available."
        case .networkTimeout:
            return "Connect to WiFi or cellular data and try again."
        }
    }
}

// MARK: - IAP Errors

enum IAPError {
    case productsNotLoaded
    case purchaseFailed
    case verificationFailed
    case networkRequired
    case userCancelled
    case unknownProduct
    case grantFailed

    var userMessage: String {
        switch self {
        case .productsNotLoaded:
            return "Shop is temporarily unavailable. Please try again in a moment."
        case .purchaseFailed:
            return "Purchase failed. Your payment method was not charged."
        case .verificationFailed:
            return "Couldn't verify your purchase. Please contact support with your receipt."
        case .networkRequired:
            return "Internet connection required to make purchases."
        case .userCancelled:
            return "Purchase cancelled."
        case .unknownProduct:
            return "This product is no longer available."
        case .grantFailed:
            return "Purchase succeeded but couldn't grant items. Contact support."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .productsNotLoaded:
            return "Wait a moment and try opening the shop again."
        case .purchaseFailed:
            return "Check your payment method in Settings and try again."
        case .verificationFailed:
            return "Try 'Restore Purchases' or contact support@movematch.com"
        case .networkRequired:
            return "Connect to the internet to complete purchases."
        case .userCancelled:
            return "You can purchase anytime from the Shop."
        case .unknownProduct:
            return "The app may need an update. Check the App Store."
        case .grantFailed:
            return "Contact support@movematch.com with your receipt for assistance."
        }
    }
}

// MARK: - Network Errors

enum NetworkError {
    case offline
    case slow
    case timeout

    var userMessage: String {
        switch self {
        case .offline:
            return "You're offline. You can still play, but progress won't sync until you reconnect."
        case .slow:
            return "Slow connection detected. Some features may be delayed."
        case .timeout:
            return "Connection timed out. Check your internet."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .offline:
            return "Connect to WiFi or cellular data to sync your progress."
        case .slow:
            return "Switch to a faster WiFi network if available."
        case .timeout:
            return "Check your connection and try again."
        }
    }
}

// MARK: - Error Banner View

struct ErrorBanner: View {
    let error: AppError
    let retry: (() -> Void)?
    let dismiss: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: error.icon)
                    .font(.title2)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.errorDescription ?? "An error occurred")
                        .font(.headline)
                        .foregroundColor(.white)

                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                }
                .accessibilityLabel("Dismiss error")
            }

            if let retry = retry {
                Button(action: retry) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Retry operation")
            }
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: AppError?
    @Published var showError = false

    private var retryAction: (() -> Void)?

    func handle(_ error: AppError, retry: (() -> Void)? = nil) {
        currentError = error
        retryAction = retry
        showError = true

        // Log to analytics
        AnalyticsManager.shared.trackError(
            category: errorCategory(for: error),
            message: error.errorDescription ?? "Unknown error",
            isCritical: error.isCritical
        )

        // Auto-dismiss non-critical errors after 5 seconds
        if !error.isCritical {
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                dismiss()
            }
        }
    }

    func dismiss() {
        showError = false
        currentError = nil
        retryAction = nil
    }

    func retry() {
        retryAction?()
        dismiss()
    }

    private func errorCategory(for error: AppError) -> ErrorCategory {
        switch error {
        case .arkit: return .arkit
        case .audio: return .audio
        case .firebase: return .firebase
        case .iap: return .iap
        case .network: return .network
        case .general: return .general
        }
    }
}
