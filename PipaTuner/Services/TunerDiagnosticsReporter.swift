import Foundation

struct TunerDiagnosticsRefreshContext {
    let activeString: PipaString
    let tuningMode: TuningMode
    let autoDetectedString: PipaString?
    let isListening: Bool
    let recognitionStatusText: String
    let microphoneStatusText: String
    let activeFrameCount: Int
    let acceptedDetectionCount: Int
}

struct TunerDiagnosticsReporter {
    private let recorder = TunerDiagnosticsRecorder()
    private let formatter = TunerPresentationFormatter()

    func clearCaptureHistory(in diagnostics: inout TunerDiagnostics) {
        recorder.clearCaptureHistory(in: &diagnostics)
    }

    func clearAutoState(in diagnostics: inout TunerDiagnostics) {
        recorder.clearAutoState(in: &diagnostics)
    }

    func updateActivity(
        level: Double,
        activeFrameCount: Int,
        isActiveFrame: Bool,
        in diagnostics: inout TunerDiagnostics
    ) {
        recorder.updateActivity(
            level: level,
            activeFrameCount: activeFrameCount,
            isActiveFrame: isActiveFrame,
            in: &diagnostics
        )
    }

    func recordAnalysisReason(_ reason: PitchAnalysisReason, in diagnostics: inout TunerDiagnostics) {
        recorder.appendEvent(formatter.eventText(for: reason), in: &diagnostics)
    }

    func recordAudioLifecycleEvent(_ event: TunerAudioLifecycleEvent, in diagnostics: inout TunerDiagnostics) {
        recorder.appendEvent(event.text, in: &diagnostics)
    }

    func recordRawDetection(_ detection: PitchDetectionResult, in diagnostics: inout TunerDiagnostics) {
        recorder.recordRawDetection(detection, in: &diagnostics)
        recorder.appendEvent(
            formatter.detectionEventText(label: formatter.rawDetectionLabel, detection: detection),
            in: &diagnostics
        )
    }

    func recordAssistedDetection(_ detection: PitchDetectionResult, in diagnostics: inout TunerDiagnostics) {
        recorder.appendEvent(
            formatter.detectionEventText(label: formatter.assistedDetectionLabel, detection: detection),
            in: &diagnostics
        )
    }

    func recordRejectedDetection(_ reason: TuningFrameRejectionReason, in diagnostics: inout TunerDiagnostics) {
        recorder.appendEvent(formatter.rejectedDetectionEventText(for: reason), in: &diagnostics)
    }

    func recordAcceptedDetection(
        _ accepted: TuningFrameAcceptedDetection,
        string: PipaString,
        tuningMode: TuningMode,
        acceptedDetectionCount: Int,
        in diagnostics: inout TunerDiagnostics
    ) {
        recorder.recordAcceptedDetection(
            accepted.detection,
            string: string,
            tuningMode: tuningMode,
            acceptedDetectionCount: acceptedDetectionCount,
            in: &diagnostics
        )
        recorder.appendEvent(formatter.acceptedDetectionEventText(accepted), in: &diagnostics)
    }

    func recordUnstablePluck(
        lockedString: PipaString,
        tuningMode: TuningMode,
        autoDetectedString: PipaString?,
        eventText: String,
        in diagnostics: inout TunerDiagnostics
    ) {
        recorder.updateCaptureState(TunerDiagnosticsCaptureState.unstable, in: &diagnostics)
        recorder.appendEvent(eventText, in: &diagnostics)
        recorder.finalizeCurrentSnapshot(
            lockedString: lockedString,
            tuningMode: tuningMode,
            autoDetectedString: autoDetectedString,
            result: nil,
            captureState: TunerDiagnosticsCaptureState.unstable,
            in: &diagnostics
        )
    }

    func recordReadoutResult(_ result: TuningResult, in diagnostics: inout TunerDiagnostics) {
        recorder.recordResult(result, in: &diagnostics)
    }

    func updateTarget(_ string: PipaString, in diagnostics: inout TunerDiagnostics) {
        recorder.updateTarget(string, in: &diagnostics)
    }

    func applyAutoTargetSelection(
        _ selection: AutoTuningTargetSelection,
        rawDetection: PitchDetectionResult,
        tuningMode: TuningMode,
        in diagnostics: inout TunerDiagnostics
    ) {
        if selection.shouldClearAutoCandidates {
            recorder.clearAutoCandidates(in: &diagnostics)
        }

        if let classification = selection.classification {
            recorder.updateAutoCandidates(
                classification.rankedCandidates,
                formatter: formatter.autoCandidateSummary(for:),
                in: &diagnostics
            )
        }

        if let snapshotString = selection.snapshotString {
            recorder.updateCurrentSnapshotRaw(
                rawDetection,
                string: snapshotString,
                tuningMode: tuningMode,
                in: &diagnostics
            )
        }

        if let autoDetectedString = selection.autoDetectedString {
            recorder.updateAutoDetectedString(autoDetectedString, in: &diagnostics)
        }

        selection.events.forEach { recorder.appendEvent($0, in: &diagnostics) }
    }

    func recordLockedDetection(
        _ detection: PitchDetectionResult,
        string: PipaString,
        tuningMode: TuningMode,
        autoDetectedString: PipaString?,
        eventLabel: String,
        result: TuningResult,
        in diagnostics: inout TunerDiagnostics
    ) {
        recorder.appendEvent(
            formatter.lockedDetectionEventText(label: eventLabel, detection: detection),
            in: &diagnostics
        )
        recorder.recordLockedDetection(
            detection,
            string: string,
            tuningMode: tuningMode,
            autoDetectedString: autoDetectedString,
            result: result,
            in: &diagnostics
        )
    }

    func refresh(_ context: TunerDiagnosticsRefreshContext, in diagnostics: inout TunerDiagnostics) {
        recorder.refresh(
            activeString: context.activeString,
            tuningMode: context.tuningMode,
            autoDetectedString: context.autoDetectedString,
            isListening: context.isListening,
            statusText: context.recognitionStatusText,
            microphoneText: context.microphoneStatusText,
            activeFrameCount: context.activeFrameCount,
            acceptedDetectionCount: context.acceptedDetectionCount,
            in: &diagnostics
        )
    }
}

enum TunerAudioLifecycleEvent {
    case startRequested
    case permissionGranted
    case permissionDenied
    case startSucceeded
    case startFailed
    case startTimedOut
    case stopRequested

    var text: String {
        switch self {
        case .startRequested:
            return "音频: 请求启动"
        case .permissionGranted:
            return "音频: 麦克风权限已允许"
        case .permissionDenied:
            return "音频: 麦克风权限受限"
        case .startSucceeded:
            return "音频: 启动成功"
        case .startFailed:
            return "音频: 启动失败"
        case .startTimedOut:
            return "音频: 启动超时"
        case .stopRequested:
            return "音频: 停止监听"
        }
    }
}
