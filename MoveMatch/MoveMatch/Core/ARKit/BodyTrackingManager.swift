//
//  BodyTrackingManager.swift
//  MoveMatch
//
//  ARKit body tracking and move detection
//

import Foundation
import ARKit
import Combine

@MainActor
class BodyTrackingManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isTracking = false
    @Published var currentPose: BodyPose?
    @Published var calibrationProgress: Float = 0.0
    @Published var trackingQuality: TrackingQuality = .unknown
    @Published var lastDetectedMove: DetectedMove?

    // MARK: - Private Properties

    private let arSession = ARSession()
    private var baselinePose: BodyPose?
    private var moveDetector: MoveDetector?
    private let calibrationDuration: TimeInterval = 5.0
    private var calibrationStartTime: Date?
    private var poseHistory: [BodyPose] = []
    private let historySize = 60 // 1 second at 60 FPS

    // MARK: - Configuration

    enum TrackingQuality {
        case unknown, poor, fair, good, excellent

        var displayText: String {
            switch self {
            case .unknown: return "Initializing..."
            case .poor: return "Poor lighting or too far"
            case .fair: return "Fair - move closer"
            case .good: return "Good"
            case .excellent: return "Excellent!"
            }
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
        arSession.delegate = self
    }

    // MARK: - Public Methods

    func startTracking() {
        guard ARBodyTrackingConfiguration.isSupported else {
            print("⚠️ ARKit body tracking not supported on this device")
            return
        }

        let configuration = ARBodyTrackingConfiguration()
        configuration.automaticImageScaleEstimation = false
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        isTracking = true
        startCalibration()
    }

    func stopTracking() {
        arSession.pause()
        isTracking = false
        baselinePose = nil
        poseHistory.removeAll()
    }

    private func startCalibration() {
        calibrationStartTime = Date()
        calibrationProgress = 0.0
    }

    func resetCalibration() {
        baselinePose = nil
        startCalibration()
    }

    // MARK: - Private Methods

    private func processBodyPose(_ bodyAnchor: ARBodyAnchor) {
        let skeleton = bodyAnchor.skeleton
        var joints: [JointType: JointData] = [:]

        // Extract key joints
        let keyJoints: [(JointType, ARSkeleton.JointName)] = [
            (.head, .head),
            (.neck, .neck1Joint),
            (.leftShoulder, .leftShoulder1Joint),
            (.rightShoulder, .rightShoulder1Joint),
            (.leftElbow, .leftForearmJoint),
            (.rightElbow, .rightForearmJoint),
            (.leftWrist, .leftHandJoint),
            (.rightWrist, .rightHandJoint),
            (.hips, .hipsJoint),
            (.leftKnee, .leftLegJoint),
            (.rightKnee, .rightLegJoint),
            (.leftAnkle, .leftFootJoint),
            (.rightAnkle, .rightFootJoint)
        ]

        for (jointType, jointName) in keyJoints {
            if let joint = skeleton.joint(named: jointName) {
                let position = simd_float3(joint.anchorFromJointTransform.columns.3.x,
                                          joint.anchorFromJointTransform.columns.3.y,
                                          joint.anchorFromJointTransform.columns.3.z)
                joints[jointType] = JointData(position: position, confidence: 1.0)
            }
        }

        let pose = BodyPose(
            timestamp: Date().timeIntervalSince1970,
            joints: joints,
            confidence: calculatePoseConfidence(joints)
        )

        currentPose = pose
        updatePoseHistory(pose)
        updateTrackingQuality(pose)
        handleCalibration(pose)
        detectMoveIfReady(pose)
    }

    private func calculatePoseConfidence(_ joints: [JointType: JointData]) -> Float {
        // Confidence based on number of tracked joints
        let requiredJoints: [JointType] = [.head, .hips, .leftShoulder, .rightShoulder]
        let trackedRequired = requiredJoints.filter { joints[$0] != nil }.count
        return Float(trackedRequired) / Float(requiredJoints.count)
    }

    private func updatePoseHistory(_ pose: BodyPose) {
        poseHistory.append(pose)
        if poseHistory.count > historySize {
            poseHistory.removeFirst()
        }
    }

    private func updateTrackingQuality(_ pose: BodyPose) {
        guard let headJoint = pose.joints[.head],
              let hipsJoint = pose.joints[.hips] else {
            trackingQuality = .poor
            return
        }

        // Check distance (optimal: 2-3 meters)
        let distanceToCamera = abs(headJoint.position.z)

        if distanceToCamera < 1.5 {
            trackingQuality = .fair // Too close
        } else if distanceToCamera > 3.5 {
            trackingQuality = .poor // Too far
        } else if pose.confidence > 0.9 {
            trackingQuality = .excellent
        } else if pose.confidence > 0.7 {
            trackingQuality = .good
        } else {
            trackingQuality = .fair
        }
    }

    private func handleCalibration(_ pose: BodyPose) {
        guard baselinePose == nil else { return }
        guard let startTime = calibrationStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        calibrationProgress = min(1.0, Float(elapsed / calibrationDuration))

        if elapsed >= calibrationDuration && pose.confidence > 0.8 {
            baselinePose = pose
            moveDetector = MoveDetector(baseline: pose)
            print("✅ Calibration complete!")
        }
    }

    private func detectMoveIfReady(_ pose: BodyPose) {
        guard let detector = moveDetector,
              let baseline = baselinePose,
              poseHistory.count >= 30 else { return }

        if let move = detector.detectMove(from: pose, history: poseHistory, baseline: baseline) {
            lastDetectedMove = move
            print("🎯 Detected move: \(move.displayName)")
        }
    }
}

// MARK: - ARSessionDelegate

extension BodyTrackingManager: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            processBodyPose(bodyAnchor)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR Session failed: \(error.localizedDescription)")
        isTracking = false
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ AR Session interrupted")
        isTracking = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ AR Session resumed")
        startTracking()
    }
}

// MARK: - Move Detector

class MoveDetector {

    private let baseline: BodyPose
    private var lastDetectionTime: TimeInterval = 0
    private let cooldownDuration: TimeInterval = 0.3 // 300ms between detections

    init(baseline: BodyPose) {
        self.baseline = baseline
    }

    func detectMove(from pose: BodyPose, history: [BodyPose], baseline: BodyPose) -> DetectedMove? {

        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastDetectionTime > cooldownDuration else { return nil }

        // Try detection algorithms in priority order
        if detectJump(pose, baseline: baseline) {
            lastDetectionTime = currentTime
            return .jump
        }

        if detectSquat(pose, baseline: baseline) {
            lastDetectionTime = currentTime
            return .squat
        }

        if detectArmRaise(pose, baseline: baseline, side: .left) {
            lastDetectionTime = currentTime
            return .armRaiseLeft
        }

        if detectArmRaise(pose, baseline: baseline, side: .right) {
            lastDetectionTime = currentTime
            return .armRaiseRight
        }

        if detectSideStep(pose, baseline: baseline, side: .left) {
            lastDetectionTime = currentTime
            return .sideStepLeft
        }

        if detectSideStep(pose, baseline: baseline, side: .right) {
            lastDetectionTime = currentTime
            return .sideStepRight
        }

        if detectSpin(history) {
            lastDetectionTime = currentTime
            return .spin
        }

        return nil
    }

    // MARK: - Detection Algorithms

    private func detectJump(_ pose: BodyPose, baseline: BodyPose) -> Bool {
        guard let currentHips = pose.joints[.hips],
              let baselineHips = baseline.joints[.hips],
              let currentHead = pose.joints[.head] else { return false }

        // Calculate frame height for relative threshold
        let frameHeight = abs(currentHead.position.y - currentHips.position.y)

        // Jump = hip rises by 20%+ of body height
        let threshold = frameHeight * 0.2
        let displacement = currentHips.position.y - baselineHips.position.y

        return displacement > threshold
    }

    private func detectSquat(_ pose: BodyPose, baseline: BodyPose) -> Bool {
        guard let hips = pose.joints[.hips],
              let knee = pose.joints[.leftKnee],
              let ankle = pose.joints[.leftAnkle],
              let baselineHips = baseline.joints[.hips] else { return false }

        // Calculate hip-knee-ankle angle
        let angle = calculateAngle(point1: hips.position,
                                   vertex: knee.position,
                                   point2: ankle.position)

        // Squat = knee angle 45-110 degrees AND hip dropped
        let isSquatAngle = angle > 45 && angle < 110
        let hipDropped = hips.position.y < baselineHips.position.y - 0.1 // 10cm threshold

        return isSquatAngle && hipDropped
    }

    private func detectArmRaise(_ pose: BodyPose, baseline: BodyPose, side: Side) -> Bool {
        let wristKey: JointType = (side == .left) ? .leftWrist : .rightWrist
        let shoulderKey: JointType = (side == .left) ? .leftShoulder : .rightShoulder

        guard let wrist = pose.joints[wristKey],
              let shoulder = pose.joints[shoulderKey],
              let head = pose.joints[.head] else { return false }

        // Arm raised = wrist is above shoulder AND near head height
        let wristAboveShoulder = wrist.position.y > shoulder.position.y + 0.15 // 15cm clearance

        // Verify wrist reached at least 70% to head height
        let shoulderToHead = head.position.y - shoulder.position.y
        let shoulderToWrist = wrist.position.y - shoulder.position.y
        let percentToHead = shoulderToWrist / shoulderToHead

        return wristAboveShoulder && percentToHead > 0.7
    }

    private func detectSideStep(_ pose: BodyPose, baseline: BodyPose, side: Side) -> Bool {
        guard let currentHips = pose.joints[.hips],
              let baselineHips = baseline.joints[.hips] else { return false }

        // Side step = horizontal displacement of hips
        let displacement = currentHips.position.x - baselineHips.position.x
        let threshold: Float = 0.2 // 20cm

        if side == .left {
            return displacement < -threshold
        } else {
            return displacement > threshold
        }
    }

    private func detectSpin(_ history: [BodyPose]) -> Bool {
        guard history.count >= 30 else { return false } // Need 0.5sec data

        var rotationAccumulation: Float = 0

        for i in 1..<history.count {
            let prevAngle = shoulderLineAngle(history[i-1])
            let currentAngle = shoulderLineAngle(history[i])

            var delta = currentAngle - prevAngle

            // Handle 360-degree wraparound
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }

            rotationAccumulation += delta
        }

        // Full spin = 270+ degrees rotation
        return abs(rotationAccumulation) > 270
    }

    // MARK: - Utilities

    private func shoulderLineAngle(_ pose: BodyPose) -> Float {
        guard let left = pose.joints[.leftShoulder],
              let right = pose.joints[.rightShoulder] else { return 0 }

        let dx = right.position.x - left.position.x
        let dz = right.position.z - left.position.z

        return atan2(dz, dx) * 180 / .pi
    }

    private func calculateAngle(point1: simd_float3, vertex: simd_float3, point2: simd_float3) -> Float {
        let vector1 = point1 - vertex
        let vector2 = point2 - vertex

        let dotProduct = simd_dot(vector1, vector2)
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)

        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(cosAngle)

        return angleRadians * 180 / .pi
    }

    enum Side {
        case left, right
    }
}
