import AVFoundation
import Combine
import Foundation

@MainActor
final class TunerViewModel: ObservableObject {
    @Published var tuningMode: TuningMode = .manual
    @Published var selectedString: PipaString = .first
    @Published private(set) var activeString: PipaString = .first
    @Published var detectedFrequencyText: String = "--"
    @Published var targetFrequencyText: String = PipaString.first.targetDisplayText
    @Published var centsText: String = "--"
    @Published var directionText: String = "点击开始，准备调弦"
    @Published var confidenceText: String = "0%"
    @Published var statusColorName: String = "secondary"
    @Published var isListening: Bool = false
    @Published var microphoneStatusText: String = "麦克风尚未启动"
    @Published var centsOffset: Double?
    @Published var inputActivityLevel: Double = 0
    @Published var recognitionStatusText: String = "准备调弦"
    @Published var showsDiagnostics: Bool = false
    @Published private(set) var diagnostics = TunerDiagnostics()
    @Published private(set) var autoStatusText: String = "等待判弦"
    @Published private(set) var isStartingAudio = false

    private let audioController = TunerAudioController()
    private let statusPresenter = TunerStatusPresenter()
    private let session = TuningSessionCoordinator()
    private let autoTargetSelector = AutoTuningTargetSelector()
    private let diagnosticsReporter = TunerDiagnosticsReporter()
    private let frameProcessor = TuningFrameProcessor()
    private let readoutPresenter = TuningReadoutPresenter()
    private var cancellables: Set<AnyCancellable> = []
    private var lastDetectedFrequency: Double?
    private var lastConfidence: Double = 0
    private var audioStartRequestID = UUID()
    private var audioStartTimeoutTask: Task<Void, Never>?

    init() {
        audioController.onAudioFrame = { [weak self] frame in
            DispatchQueue.main.async {
                self?.handleAudioFrame(frame)
            }
        }

        $selectedString
            .dropFirst()
            .sink { [weak self] string in
                self?.handleSelectedStringChanged(string)
            }
            .store(in: &cancellables)

        $tuningMode
            .dropFirst()
            .sink { [weak self] mode in
                self?.handleTuningModeChanged(mode)
            }
            .store(in: &cancellables)

        updateTargetLabels()
        refreshDiagnostics()
    }

    func startListening() {
        guard !isListening, !isStartingAudio else {
            return
        }

        isStartingAudio = true
        let requestID = UUID()
        audioStartRequestID = requestID
        microphoneStatusText = statusPresenter.requestingPermissionText
        recognitionStatusText = statusPresenter.startingRecognitionText
        directionText = statusPresenter.requestingPermissionText
        statusColorName = "secondary"
        diagnosticsReporter.recordAudioLifecycleEvent(.startRequested, in: &diagnostics)
        refreshDiagnostics()

        switch audioController.recordPermission {
        case .granted:
            recordPermissionGranted()
            beginAuthorizedAudioStart(requestID: requestID)

        case .denied:
            handleAudioStartResult(.permissionDenied, requestID: requestID)

        case .undetermined:
            audioController.requestRecordPermission { [weak self] granted in
                guard let self else { return }
                guard audioStartRequestID == requestID, isStartingAudio else { return }

                if granted {
                    recordPermissionGranted()
                    beginAuthorizedAudioStart(requestID: requestID)
                } else {
                    handleAudioStartResult(.permissionDenied, requestID: requestID)
                }
            }
        }
    }

    private func recordPermissionGranted() {
        microphoneStatusText = statusPresenter.startingMicrophoneText
        directionText = statusPresenter.startingMicrophoneText
        diagnosticsReporter.recordAudioLifecycleEvent(.permissionGranted, in: &diagnostics)
        refreshDiagnostics()
    }

    private func beginAuthorizedAudioStart(requestID: UUID) {
        scheduleAudioStartTimeout(for: requestID)
        audioController.start(
            targetFrequency: recorderTargetFrequency,
            completion: { [weak self] result in
                self?.handleAudioStartResult(result, requestID: requestID)
            }
        )
    }

    private func handleAudioStartResult(_ result: TunerAudioStartResult, requestID: UUID) {
        guard audioStartRequestID == requestID, isStartingAudio else {
            audioController.stop()
            return
        }

        audioStartTimeoutTask?.cancel()
        audioStartTimeoutTask = nil
        isStartingAudio = false

        switch result {
        case .started:
            isListening = true
            microphoneStatusText = statusPresenter.microphoneListeningText
            recognitionStatusText = statusPresenter.waitingPluckText
            directionText = statusPresenter.listeningPrompt(for: activeString, mode: tuningMode)
            statusColorName = "secondary"
            diagnosticsReporter.recordAudioLifecycleEvent(.startSucceeded, in: &diagnostics)

        case .permissionDenied:
            isListening = false
            microphoneStatusText = statusPresenter.permissionDeniedText
            recognitionStatusText = statusPresenter.unableToStartTuningText
            directionText = statusPresenter.permissionDirectionText
            statusColorName = "red"
            diagnosticsReporter.recordAudioLifecycleEvent(.permissionDenied, in: &diagnostics)

        case .failed:
            isListening = false
            microphoneStatusText = statusPresenter.startFailedText
            recognitionStatusText = statusPresenter.unableToStartTuningText
            directionText = statusPresenter.startFailedDirectionText
            statusColorName = "red"
            diagnosticsReporter.recordAudioLifecycleEvent(.startFailed, in: &diagnostics)
        }
        refreshDiagnostics()
    }

    func stopListening() {
        guard isListening else {
            return
        }

        audioStartRequestID = UUID()
        audioStartTimeoutTask?.cancel()
        audioStartTimeoutTask = nil

        if isListening {
            publishLockedCurrentPluckIfNeeded()
        }
        audioController.stop()
        isStartingAudio = false
        isListening = false
        microphoneStatusText = statusPresenter.microphoneStoppedText
        recognitionStatusText = statusPresenter.recognitionStoppedText
        inputActivityLevel = 0
        directionText = activeString.tuningHint
        statusColorName = "secondary"
        diagnosticsReporter.recordAudioLifecycleEvent(.stopRequested, in: &diagnostics)
        refreshDiagnostics()
    }

    func toggleListening() {
        guard !isStartingAudio else {
            return
        }

        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func scheduleAudioStartTimeout(for requestID: UUID) {
        audioStartTimeoutTask?.cancel()
        audioStartTimeoutTask = Task { [weak self] in
            let nanoseconds = UInt64(TunerConfiguration.AudioInput.startupTimeoutSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.handleAudioStartTimeout(requestID: requestID)
        }
    }

    private func handleAudioStartTimeout(requestID: UUID) {
        guard audioStartRequestID == requestID, isStartingAudio else {
            return
        }

        audioStartRequestID = UUID()
        audioStartTimeoutTask?.cancel()
        audioStartTimeoutTask = nil
        audioController.stop()
        isStartingAudio = false
        isListening = false
        inputActivityLevel = 0
        microphoneStatusText = statusPresenter.startTimeoutText
        recognitionStatusText = statusPresenter.retryStartTuningText
        directionText = statusPresenter.startTimeoutDirectionText
        statusColorName = "red"
        diagnosticsReporter.recordAudioLifecycleEvent(.startTimedOut, in: &diagnostics)
        refreshDiagnostics()
    }

    func toggleDiagnostics() {
        guard TunerConfiguration.Diagnostics.isEnabled else {
            return
        }
        showsDiagnostics.toggle()
    }

    func toggleTuningMode() {
        tuningMode = tuningMode == .manual ? .auto : .manual
    }

    func recalculateLastResult() {
        recalculateLastResult(for: effectiveTargetString)
    }

    private func recalculateLastResult(for string: PipaString) {
        updateTargetLabels(for: string)

        guard let lastDetectedFrequency else {
            clearReadout(directionText: string.tuningHint)
            return
        }

        let result = TuningGuide.evaluate(
            detectedFrequency: lastDetectedFrequency,
            targetFrequency: string.targetFrequency,
            confidence: lastConfidence
        )
        apply(result, for: string)
    }

    private func handleSelectedStringChanged(_ string: PipaString) {
        guard tuningMode == .manual else {
            handleAutoModeSelectionChange(string)
            refreshDiagnostics()
            return
        }

        resetManualSelectionState(to: string)
        diagnosticsReporter.clearCaptureHistory(in: &diagnostics)
        refreshDiagnostics()
    }

    private func handleAutoModeSelectionChange(_ string: PipaString) {
        configureRecorderTarget()
        if session.lastAutoDetectedString == nil, session.capturedPluckString == nil {
            syncActiveString(with: string)
        }
    }

    private func resetManualSelectionState(to string: PipaString) {
        syncActiveString(with: string)
        updateTargetLabels(for: string)
        configureRecorderTarget()
        lastDetectedFrequency = nil
        lastConfidence = 0
        session.resetForManualSelectionChange()
        clearReadout(directionText: statusPresenter.listeningPrompt(for: string, mode: tuningMode))
        updateWaitingStatus(for: string, mode: tuningMode)
    }

    func handleAudioFrame(_ frame: AudioAnalysisFrame) {
        inputActivityLevel = frame.activityLevel
        let isActiveFrame = frame.activityLevel > TunerConfiguration.AudioInput.activeFrameLevel
        guard isActiveFrame else {
            handleInactiveAudioFrame(frame)
            return
        }

        beginActiveAudioFrame(frame)

        if let rawDetection = frame.rawDetection {
            handleRawDetectionFrame(frame, rawDetection: rawDetection)
        } else if tuningMode == .auto, let assistedDetection = frame.assistedDetection {
            handleAssistedOnlyFrame(frame, assistedDetection: assistedDetection)
        } else {
            diagnosticsReporter.recordAnalysisReason(frame.rawAnalysisReason, in: &diagnostics)
            recognitionStatusText = statusPresenter.findingStablePitchText
            microphoneStatusText = statusPresenter.microphoneListeningText
        }
        refreshDiagnostics()
    }

    private func handleInactiveAudioFrame(_ frame: AudioAnalysisFrame) {
        recognitionStatusText = statusPresenter.waitingNextPluckText
        diagnosticsReporter.updateActivity(
            level: frame.activityLevel,
            activeFrameCount: session.activeFrameCount,
            isActiveFrame: false,
            in: &diagnostics
        )

        let didPublishResult = publishLockedCurrentPluckIfNeeded()
        guard !didPublishResult else {
            return
        }

        if lastDetectedFrequency != nil {
            microphoneStatusText = statusPresenter.microphoneListeningText
        } else {
            directionText = statusPresenter.lightPluckText
            statusColorName = "secondary"
        }
        refreshDiagnostics()
    }

    private func beginActiveAudioFrame(_ frame: AudioAnalysisFrame) {
        recognitionStatusText = statusPresenter.activeRecognizingText
        statusColorName = "gold"
        diagnosticsReporter.updateActivity(
            level: frame.activityLevel,
            activeFrameCount: session.activeFrameCount,
            isActiveFrame: true,
            in: &diagnostics
        )
        session.beginActiveFrame()
        diagnosticsReporter.updateActivity(
            level: frame.activityLevel,
            activeFrameCount: session.activeFrameCount,
            isActiveFrame: true,
            in: &diagnostics
        )
    }

    private func handleRawDetectionFrame(
        _ frame: AudioAnalysisFrame,
        rawDetection: PitchDetectionResult
    ) {
        diagnosticsReporter.recordRawDetection(rawDetection, in: &diagnostics)

        let targetString = resolveTargetString(for: rawDetection)

        if let assistedDetection = frame.assistedDetection,
           abs(assistedDetection.frequency - rawDetection.frequency) > 0.5 {
            diagnosticsReporter.recordAssistedDetection(assistedDetection, in: &diagnostics)
        }

        if let targetString {
            collectDetection(rawDetection, for: targetString)
        }
        markFrameAnalyzing()
    }

    private func handleAssistedOnlyFrame(
        _ frame: AudioAnalysisFrame,
        assistedDetection: PitchDetectionResult
    ) {
        diagnosticsReporter.recordAnalysisReason(frame.rawAnalysisReason, in: &diagnostics)
        diagnosticsReporter.recordAssistedDetection(assistedDetection, in: &diagnostics)
        collectDetection(assistedDetection, for: effectiveTargetString)
        markFrameAnalyzing()
    }

    private func markFrameAnalyzing() {
        recognitionStatusText = statusPresenter.recognizingUntilReleaseText
        microphoneStatusText = statusPresenter.microphoneListeningText
        statusColorName = "gold"
    }

    private func collectDetection(_ detection: PitchDetectionResult, for string: PipaString) {
        switch frameProcessor.process(detection, for: string, mode: tuningMode) {
        case .rejected(let reason):
            handleRejectedDetection(reason)
            return

        case .accepted(let accepted):
            recordAcceptedDetection(accepted, for: string)
        }
    }

    private func handleRejectedDetection(_ reason: TuningFrameRejectionReason) {
        diagnosticsReporter.recordRejectedDetection(reason, in: &diagnostics)
        switch reason {
        case .manualHighHarmonic:
            recognitionStatusText = statusPresenter.highHarmonicText
            microphoneStatusText = statusPresenter.microphoneListeningText
            statusColorName = "orange"
        case .lowConfidence, .outsideTargetRange:
            break
        }
        refreshDiagnostics()
    }

    private func recordAcceptedDetection(_ accepted: TuningFrameAcceptedDetection, for string: PipaString) {
        let acceptedDetection = accepted.detection
        session.recordAcceptedDetection(acceptedDetection)
        diagnosticsReporter.recordAcceptedDetection(
            accepted,
            string: string,
            tuningMode: tuningMode,
            acceptedDetectionCount: session.acceptedDetectionCount,
            in: &diagnostics
        )
        let result = TuningGuide.evaluate(
            detectedFrequency: acceptedDetection.frequency,
            targetFrequency: string.targetFrequency,
            confidence: acceptedDetection.confidence
        )
        apply(result, for: string)
    }

    @discardableResult
    private func publishLockedCurrentPluckIfNeeded() -> Bool {
        guard session.isCollectingPluck else {
            return false
        }

        let targetString = effectiveTargetString
        let hadActiveFrames = session.activeFrameCount > 0

        guard let lockedDetection = session.finishPluck() else {
            if hadActiveFrames {
                showUnstablePitch()
                return true
            }

            return false
        }

        lastDetectedFrequency = lockedDetection.frequency
        lastConfidence = lockedDetection.confidence

        let result = TuningGuide.evaluate(
            detectedFrequency: lockedDetection.frequency,
            targetFrequency: targetString.targetFrequency,
            confidence: lockedDetection.confidence
        )
        publishLockedDetection(
            lockedDetection,
            for: targetString,
            eventLabel: statusPresenter.lockedEventLabel,
            microphoneStatus: statusPresenter.lockedMicrophoneText,
            recognitionStatus: statusPresenter.lockedRecognitionText,
            result: result
        )
        return true
    }

    private func showUnstablePitch() {
        clearReadout(directionText: statusPresenter.unstableDirectionText)
        microphoneStatusText = statusPresenter.unstableMicrophoneText
        recognitionStatusText = statusPresenter.unstableRecognitionText
        diagnosticsReporter.recordUnstablePluck(
            lockedString: effectiveTargetString,
            tuningMode: tuningMode,
            autoDetectedString: currentAutoDetectedString,
            eventText: statusPresenter.unstableEventText,
            in: &diagnostics
        )
        refreshDiagnostics()
    }

    private func clearReadout(directionText: String) {
        detectedFrequencyText = "--"
        centsText = "--"
        centsOffset = nil
        confidenceText = "0%"
        self.directionText = directionText
        statusColorName = "secondary"
    }

    private func updateWaitingStatus(for string: PipaString, mode: TuningMode) {
        recognitionStatusText = isListening ? statusPresenter.waitingPluckText : statusPresenter.recognitionNotStartedText
        microphoneStatusText = isListening
            ? statusPresenter.waitingMicrophoneText(for: string, mode: mode)
            : statusPresenter.microphoneNotStartedText
    }

    private func apply(_ result: TuningResult, for string: PipaString) {
        let readout = readoutPresenter.readout(for: result, string: string)
        detectedFrequencyText = readout.detectedFrequencyText
        centsText = readout.centsText
        centsOffset = readout.centsOffset
        confidenceText = readout.confidenceText
        directionText = readout.directionText
        statusColorName = readout.statusColorName
        diagnosticsReporter.recordReadoutResult(result, in: &diagnostics)
        refreshDiagnostics()
    }

    private func updateTargetLabels() {
        updateTargetLabels(for: activeString)
    }

    private func updateTargetLabels(for string: PipaString) {
        targetFrequencyText = string.targetDisplayText
        diagnosticsReporter.updateTarget(string, in: &diagnostics)
    }

    private func refreshDiagnostics() {
        diagnosticsReporter.refresh(
            TunerDiagnosticsRefreshContext(
                activeString: activeString,
                tuningMode: tuningMode,
                autoDetectedString: currentAutoDetectedString,
                isListening: isListening,
                recognitionStatusText: recognitionStatusText,
                microphoneStatusText: microphoneStatusText,
                activeFrameCount: session.activeFrameCount,
                acceptedDetectionCount: session.acceptedDetectionCount
            ),
            in: &diagnostics
        )
        autoStatusText = statusPresenter.autoStatusText(
            mode: tuningMode,
            autoDetectedString: currentAutoDetectedString,
            selectedString: selectedString
        )
    }

    private func handleTuningModeChanged(_ mode: TuningMode) {
        session.resetForModeChange()
        configureRecorderTarget()
        diagnosticsReporter.clearAutoState(in: &diagnostics)
        syncActiveString(with: selectedString)
        directionText = statusPresenter.listeningPrompt(for: activeString, mode: mode)
        updateWaitingStatus(for: selectedString, mode: mode)
        refreshDiagnostics()
    }

    private func configureRecorderTarget() {
        audioController.updateTargetFrequency(recorderTargetFrequency)
    }

    private var recorderTargetFrequency: Double? {
        tuningMode == .manual ? selectedString.targetFrequency : nil
    }

    private var effectiveTargetString: PipaString {
        session.effectiveTargetString(fallback: activeString)
    }

    private var currentAutoDetectedString: PipaString? {
        session.capturedPluckString ?? session.lastAutoDetectedString
    }

    private func resolveTargetString(for rawDetection: PitchDetectionResult) -> PipaString? {
        let selection = autoTargetSelector.selectTarget(
            for: rawDetection,
            mode: tuningMode,
            selectedString: selectedString,
            activeString: activeString,
            session: session
        )

        diagnosticsReporter.applyAutoTargetSelection(
            selection,
            rawDetection: rawDetection,
            tuningMode: tuningMode,
            in: &diagnostics
        )
        if let activeString = selection.activeString {
            syncActiveString(with: activeString)
        }
        return selection.targetString
    }

    private func publishLockedDetection(
        _ detection: PitchDetectionResult,
        for string: PipaString,
        eventLabel: String,
        microphoneStatus: String,
        recognitionStatus: String,
        result: TuningResult? = nil
    ) {
        let resolvedResult = result ?? TuningGuide.evaluate(
            detectedFrequency: detection.frequency,
            targetFrequency: string.targetFrequency,
            confidence: detection.confidence
        )
        apply(resolvedResult, for: string)
        microphoneStatusText = microphoneStatus
        recognitionStatusText = recognitionStatus
        diagnosticsReporter.recordLockedDetection(
            detection,
            string: string,
            tuningMode: tuningMode,
            autoDetectedString: currentAutoDetectedString,
            eventLabel: eventLabel,
            result: resolvedResult,
            in: &diagnostics
        )
        refreshDiagnostics()
    }

    private func syncActiveString(with string: PipaString) {
        guard activeString != string else {
            return
        }

        activeString = string
        updateTargetLabels(for: string)
        refreshDiagnostics()
    }

}
