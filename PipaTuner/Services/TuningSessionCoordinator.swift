import Foundation

final class TuningSessionCoordinator {
    private(set) var currentPluckDetections: [PitchDetectionResult] = []
    private(set) var activeFrameCount = 0
    private(set) var acceptedDetectionCount = 0
    private(set) var isCollectingPluck = false
    private(set) var capturedPluckString: PipaString?
    private(set) var lastAutoDetectedString: PipaString?

    private var pendingAutoCandidate: PipaString?
    private var pendingAutoCandidateCount = 0

    func beginActiveFrame() {
        isCollectingPluck = true
        activeFrameCount += 1
    }

    func recordAcceptedDetection(_ detection: PitchDetectionResult) {
        guard currentPluckDetections.count < TunerConfiguration.Tuning.maxAcceptedDetectionsPerPluck else {
            return
        }

        currentPluckDetections.append(detection)
        acceptedDetectionCount += 1
    }

    func registerAutoCandidate(_ string: PipaString) -> PipaString? {
        if pendingAutoCandidate == string {
            pendingAutoCandidateCount += 1
        } else {
            pendingAutoCandidate = string
            pendingAutoCandidateCount = 1
        }

        if pendingAutoCandidateCount >= 2 {
            return string
        }

        return nil
    }

    func captureAutoDetectedString(_ string: PipaString) {
        lastAutoDetectedString = string
        capturedPluckString = string
    }

    func effectiveTargetString(fallback activeString: PipaString) -> PipaString {
        capturedPluckString ?? lastAutoDetectedString ?? activeString
    }

    func finishPluck() -> PitchDetectionResult? {
        defer {
            clearFrameState()
        }

        return lockedDetection(from: currentPluckDetections)
    }

    func resetForManualSelectionChange() {
        clearFrameState()
        lastAutoDetectedString = nil
    }

    func resetForModeChange() {
        clearFrameState()
        lastAutoDetectedString = nil
    }

    func clearPendingAutoState() {
        pendingAutoCandidate = nil
        pendingAutoCandidateCount = 0
    }

    func restartActivePluck() {
        clearFrameState()
        isCollectingPluck = true
        activeFrameCount = 1
    }

    private func clearFrameState() {
        isCollectingPluck = false
        currentPluckDetections.removeAll(keepingCapacity: true)
        activeFrameCount = 0
        acceptedDetectionCount = 0
        capturedPluckString = nil
        clearPendingAutoState()
    }

    private func lockedDetection(from detections: [PitchDetectionResult]) -> PitchDetectionResult? {
        guard !detections.isEmpty else {
            return nil
        }

        let medianFrequency = median(detections.map(\.frequency))
        let stableWindow = detections.filter {
            abs(TunerConfiguration.Tuning.centsOctaveUnit * log2($0.frequency / medianFrequency))
                <= TunerConfiguration.Tuning.centsStableWindow
        }
        let stableDetections = stableWindow.isEmpty ? detections : stableWindow
        let totalWeight = stableDetections.reduce(0.0) { $0 + max(TunerConfiguration.Tuning.weightingFloor, $1.confidence) }

        guard totalWeight > 0 else {
            return nil
        }

        let weightedFrequency = stableDetections.reduce(0.0) { partialResult, detection in
            partialResult + detection.frequency * max(TunerConfiguration.Tuning.weightingFloor, detection.confidence)
        } / totalWeight
        let averageConfidence = stableDetections.reduce(0.0) { $0 + $1.confidence } / Double(stableDetections.count)
        let averageRMS = stableDetections.reduce(0.0) { $0 + $1.rms } / Double(stableDetections.count)

        return PitchDetectionResult(
            frequency: weightedFrequency,
            confidence: averageConfidence,
            rms: averageRMS
        )
    }

    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else {
            return 0
        }

        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2.0
        }

        return sorted[middle]
    }
}
