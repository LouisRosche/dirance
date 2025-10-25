import Foundation
import Network
import Combine

/// Monitors network connectivity and provides offline mode support
/// Allows app to function gracefully when internet is unavailable
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false // Cellular data

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }

        if isConnected {
            print("✅ Network connected (\(connectionType))")
        } else {
            print("⚠️ Network disconnected - entering offline mode")
        }
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - Offline Queue Manager

/// Queues operations when offline and syncs when connection returns
@MainActor
class OfflineQueueManager: ObservableObject {
    static let shared = OfflineQueueManager()

    @Published var pendingOperations: [QueuedOperation] = []

    private let userDefaults = UserDefaults.standard
    private let queueKey = "offline_queue"

    init() {
        loadQueue()
        observeNetworkChanges()
    }

    func enqueue(_ operation: QueuedOperation) {
        pendingOperations.append(operation)
        saveQueue()
        print("📥 Queued offline operation: \(operation.type)")
    }

    func processPendingOperations() async {
        guard NetworkMonitor.shared.isConnected else {
            print("⚠️ Still offline - cannot process queue")
            return
        }

        print("🔄 Processing \(pendingOperations.count) pending operations...")

        for operation in pendingOperations {
            do {
                try await execute(operation)
                removeOperation(operation)
                print("✅ Completed: \(operation.type)")
            } catch {
                print("❌ Failed: \(operation.type) - \(error)")
                // Keep in queue to retry later
            }
        }
    }

    private func execute(_ operation: QueuedOperation) async throws {
        switch operation.type {
        case .saveSession:
            if let sessionData = operation.data,
               let session = try? JSONDecoder().decode(GameSession.self, from: sessionData) {
                try await FirebaseManager.shared.saveSession(session: session)
            }

        case .updateProfile:
            if let profileData = operation.data,
               let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
                try await FirebaseManager.shared.updateUserProfile(userId: profile.id, profile: profile)
            }

        case .logEvent:
            // Analytics events are queued by Firebase SDK automatically
            break
        }
    }

    private func removeOperation(_ operation: QueuedOperation) {
        pendingOperations.removeAll { $0.id == operation.id }
        saveQueue()
    }

    private func saveQueue() {
        if let encoded = try? JSONEncoder().encode(pendingOperations) {
            userDefaults.set(encoded, forKey: queueKey)
        }
    }

    private func loadQueue() {
        if let data = userDefaults.data(forKey: queueKey),
           let decoded = try? JSONDecoder().decode([QueuedOperation].self, from: data) {
            pendingOperations = decoded
        }
    }

    private func observeNetworkChanges() {
        // Process queue when network becomes available
        Task {
            for await _ in NotificationCenter.default.notifications(named: .networkDidBecomeReachable) {
                await processPendingOperations()
            }
        }
    }
}

struct QueuedOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let data: Data?
    let timestamp: Date

    enum OperationType: String, Codable {
        case saveSession
        case updateProfile
        case logEvent
    }
}

extension Notification.Name {
    static let networkDidBecomeReachable = Notification.Name("networkDidBecomeReachable")
    static let networkDidBecomeUnreachable = Notification.Name("networkDidBecomeUnreachable")
}
