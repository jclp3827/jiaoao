import Foundation

struct TunerDiagnosticsRecorder {
    func clearCaptureHistory(in diagnostics: inout TunerDiagnostics) {
        diagnostics.rawFrequencyHistory.removeAll(keepingCapacity: true)
        diagnostics.acceptedFrequencyHistory.removeAll(keepingCapacity: true)
        diagnostics.lockedFrequencyHistory.removeAll(keepingCapacity: true)
        diagnostics.recentEvents.removeAll(keepingCapacity: true)
        diagnostics.currentPluckSnapshot = nil
    }

    func clearAutoState(in diagnostics: inout TunerDiagnostics) {
        diagnostics.autoDetectedStringName = nil
        diagnostics.autoCandidateSummary = []
        diagnostics.currentPluckSnapshot = nil
    }

    func clearAutoCandidates(in diagnostics: inout TunerDiagnostics) {
        diagnostics.autoDetectedStringName = nil
        diagnostics.autoCandidateSummary = []
    }

    func updateActivity(
        level: Double,
        activeFrameCount: Int,
        isActiveFrame: Bool,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics.activityLevel = level
        diagnostics.activeFrameCount = activeFrameCount
        diagnostics.captureState = isActiveFrame
            ? TunerDiagnosticsCaptureState.active
            : TunerDiagnosticsCaptureState.idle
    }

    func updateCaptureState(_ state: String, in diagnostics: inout TunerDiagnostics) {
        diagnostics.captureState = state
    }

    func recordRawDetection(_ detection: PitchDetectionResult, in diagnostics: inout TunerDiagnostics) {
        diagnostics.rawFrequency = detection.frequency
        diagnostics.rawConfidence = detection.confidence
        appendHistoryValue(detection.frequency, to: \.rawFrequencyHistory, in: &diagnostics)
    }

    func recordAcceptedDetection(
        _ detection: PitchDetectionResult,
        string: PipaString,
        tuningMode: TuningMode,
        acceptedDetectionCount: Int,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics.acceptedFrequency = detection.frequency
        diagnostics.acceptedConfidence = detection.confidence
        diagnostics.acceptedDetectionCount = acceptedDetectionCount
        ensureCurrentSnapshot(for: string, tuningMode: tuningMode, in: &diagnostics)
        diagnostics.currentPluckSnapshot?.acceptedFrequency = detection.frequency
        diagnostics.currentPluckSnapshot?.acceptedConfidence = detection.confidence
        appendHistoryValue(detection.frequency, to: \.acceptedFrequencyHistory, in: &diagnostics)
    }

    func recordLockedDetection(
        _ detection: PitchDetectionResult,
        string: PipaString,
        tuningMode: TuningMode,
        autoDetectedString: PipaString?,
        result: TuningResult,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics.lockedFrequency = detection.frequency
        diagnostics.lockedConfidence = detection.confidence
        diagnostics.captureState = TunerDiagnosticsCaptureState.locked
        appendHistoryValue(detection.frequency, to: \.lockedFrequencyHistory, in: &diagnostics)
        diagnostics.currentPluckSnapshot?.lockedFrequency = detection.frequency
        diagnostics.currentPluckSnapshot?.lockedConfidence = detection.confidence
        finalizeCurrentSnapshot(
            lockedString: string,
            tuningMode: tuningMode,
            autoDetectedString: autoDetectedString,
            result: result,
            captureState: TunerDiagnosticsCaptureState.locked,
            lockedDetection: detection,
            in: &diagnostics
        )
    }

    func recordResult(_ result: TuningResult, in diagnostics: inout TunerDiagnostics) {
        diagnostics.detectedFrequency = result.detectedFrequency
        diagnostics.centsOffset = result.centsOffset
        diagnostics.direction = result.direction.rawValue
        diagnostics.targetFrequency = result.targetFrequency
    }

    func updateTarget(_ string: PipaString, in diagnostics: inout TunerDiagnostics) {
        diagnostics.selectedStringName = string.shortName
        diagnostics.targetFrequency = string.targetFrequency
    }

    func updateAutoCandidates(
        _ candidates: [AutoStringCandidate],
        formatter: (AutoStringCandidate) -> String,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics.autoCandidateSummary = candidates.map(formatter)
    }

    func updateAutoDetectedString(_ string: PipaString?, in diagnostics: inout TunerDiagnostics) {
        diagnostics.autoDetectedStringName = string?.shortName
        diagnostics.currentPluckSnapshot?.autoDetectedStringName = string?.shortName
    }

    func refresh(
        activeString: PipaString,
        tuningMode: TuningMode,
        autoDetectedString: PipaString?,
        isListening: Bool,
        statusText: String,
        microphoneText: String,
        activeFrameCount: Int,
        acceptedDetectionCount: Int,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics.selectedStringName = activeString.shortName
        diagnostics.targetFrequency = activeString.targetFrequency
        diagnostics.tuningModeName = tuningMode.title
        diagnostics.autoDetectedStringName = autoDetectedString?.shortName
        diagnostics.isListening = isListening
        diagnostics.statusText = statusText
        diagnostics.microphoneText = microphoneText
        diagnostics.activeFrameCount = activeFrameCount
        diagnostics.acceptedDetectionCount = acceptedDetectionCount
    }

    func appendEvent(_ event: String, in diagnostics: inout TunerDiagnostics) {
        diagnostics.recentEvents.append(event)
        if diagnostics.recentEvents.count > TunerConfiguration.Diagnostics.eventLimit {
            diagnostics.recentEvents.removeFirst(
                diagnostics.recentEvents.count - TunerConfiguration.Diagnostics.eventLimit
            )
        }
    }

    func ensureCurrentSnapshot(
        for string: PipaString,
        tuningMode: TuningMode,
        in diagnostics: inout TunerDiagnostics
    ) {
        if diagnostics.currentPluckSnapshot == nil {
            diagnostics.currentPluckSnapshot = TuningSnapshot(
                selectedStringName: string.shortName,
                targetFrequency: string.targetFrequency,
                tuningModeName: tuningMode.title,
                autoDetectedStringName: nil,
                captureState: TunerDiagnosticsCaptureState.active
            )
        } else {
            diagnostics.currentPluckSnapshot?.selectedStringName = string.shortName
            diagnostics.currentPluckSnapshot?.targetFrequency = string.targetFrequency
            diagnostics.currentPluckSnapshot?.tuningModeName = tuningMode.title
        }
    }

    func updateCurrentSnapshotRaw(
        _ detection: PitchDetectionResult,
        string: PipaString,
        tuningMode: TuningMode,
        in diagnostics: inout TunerDiagnostics
    ) {
        ensureCurrentSnapshot(for: string, tuningMode: tuningMode, in: &diagnostics)
        diagnostics.currentPluckSnapshot?.rawFrequency = detection.frequency
        diagnostics.currentPluckSnapshot?.rawConfidence = detection.confidence
    }

    func finalizeCurrentSnapshot(
        lockedString: PipaString,
        tuningMode: TuningMode,
        autoDetectedString: PipaString?,
        result: TuningResult?,
        captureState: String,
        lockedDetection: PitchDetectionResult? = nil,
        in diagnostics: inout TunerDiagnostics
    ) {
        ensureCurrentSnapshot(for: lockedString, tuningMode: tuningMode, in: &diagnostics)
        diagnostics.currentPluckSnapshot?.captureState = captureState
        diagnostics.currentPluckSnapshot?.autoDetectedStringName = autoDetectedString?.shortName
        if let lockedDetection {
            diagnostics.currentPluckSnapshot?.lockedFrequency = lockedDetection.frequency
            diagnostics.currentPluckSnapshot?.lockedConfidence = lockedDetection.confidence
        }
        if let result {
            diagnostics.currentPluckSnapshot?.detectedFrequency = result.detectedFrequency
            diagnostics.currentPluckSnapshot?.centsOffset = result.centsOffset
            diagnostics.currentPluckSnapshot?.direction = result.direction.rawValue
        }
        diagnostics.lastLockedSnapshot = diagnostics.currentPluckSnapshot
    }

    private func appendHistoryValue(
        _ value: Double,
        to keyPath: WritableKeyPath<TunerDiagnostics, [Double]>,
        in diagnostics: inout TunerDiagnostics
    ) {
        diagnostics[keyPath: keyPath].append(value)
        if diagnostics[keyPath: keyPath].count > TunerConfiguration.Diagnostics.historyLimit {
            diagnostics[keyPath: keyPath].removeFirst(
                diagnostics[keyPath: keyPath].count - TunerConfiguration.Diagnostics.historyLimit
            )
        }
    }
}
