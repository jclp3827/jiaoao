import Foundation

struct AutoTuningTargetSelection {
    let targetString: PipaString?
    let classification: AutoStringClassification?
    let snapshotString: PipaString?
    let autoDetectedString: PipaString?
    let events: [String]
    let activeString: PipaString?
    let shouldClearAutoCandidates: Bool
}

struct AutoTuningTargetSelector {
    private let classifier = AutoStringClassifier()
    private let resolver = AutoTargetResolver()
    private let formatter = TunerPresentationFormatter()

    func selectTarget(
        for rawDetection: PitchDetectionResult,
        mode: TuningMode,
        selectedString: PipaString,
        activeString: PipaString,
        session: TuningSessionCoordinator
    ) -> AutoTuningTargetSelection {
        guard mode == .auto else {
            return AutoTuningTargetSelection(
                targetString: activeString,
                classification: nil,
                snapshotString: nil,
                autoDetectedString: nil,
                events: [],
                activeString: nil,
                shouldClearAutoCandidates: true
            )
        }

        let classification = classifier.classify(
            detection: rawDetection,
            fallbackString: selectedString,
            preferredString: selectedString
        )
        let candidate = classification.bestCandidate.string

        if let capturedPluckString = session.capturedPluckString {
            return applyCapturedResolution(
                resolver.resolve(classification: classification, capturedString: capturedPluckString),
                classification: classification,
                capturedString: capturedPluckString,
                session: session
            )
        }

        return applyInitialResolution(
            resolver.resolve(classification: classification, capturedString: nil),
            classification: classification,
            candidate: candidate,
            session: session
        )
    }

    private func applyCapturedResolution(
        _ resolution: AutoTargetResolution,
        classification: AutoStringClassification,
        capturedString: PipaString,
        session: TuningSessionCoordinator
    ) -> AutoTuningTargetSelection {
        switch resolution {
        case .keepCaptured(let string):
            return autoSelection(
                targetString: string,
                classification: classification,
                snapshotString: capturedString
            )

        case .decisiveRecapture(let string):
            session.restartActivePluck()
            return captureSelection(
                string,
                classification: classification,
                snapshotString: string,
                eventLabel: formatter.decisiveRecaptureLabel,
                session: session
            )

        case .needsStableRecapture(let string):
            guard let stableCandidate = session.registerAutoCandidate(string) else {
                return autoSelection(
                    targetString: nil,
                    classification: classification,
                    snapshotString: capturedString,
                    autoDetectedString: string,
                    events: [formatter.autoStringEventText(label: formatter.recaptureCandidateLabel, string: string)]
                )
            }

            session.restartActivePluck()
            return captureSelection(
                stableCandidate,
                classification: classification,
                snapshotString: capturedString,
                eventLabel: formatter.stableRecaptureLabel,
                session: session
            )

        case .decisiveInitial, .needsStableInitial:
            return autoSelection(
                targetString: nil,
                classification: classification,
                snapshotString: capturedString
            )
        }
    }

    private func applyInitialResolution(
        _ resolution: AutoTargetResolution,
        classification: AutoStringClassification,
        candidate: PipaString,
        session: TuningSessionCoordinator
    ) -> AutoTuningTargetSelection {
        switch resolution {
        case .decisiveInitial(let string):
            return captureSelection(
                string,
                classification: classification,
                snapshotString: string,
                eventLabel: formatter.autoDetectionLabel,
                session: session
            )

        case .needsStableInitial(let string):
            guard let stableCandidate = session.registerAutoCandidate(string) else {
                return autoSelection(
                    targetString: nil,
                    classification: classification,
                    snapshotString: candidate,
                    autoDetectedString: string,
                    events: [formatter.autoStringEventText(label: formatter.autoCandidateLabel, string: string)]
                )
            }

            return captureSelection(
                stableCandidate,
                classification: classification,
                snapshotString: stableCandidate,
                eventLabel: formatter.autoDetectionLabel,
                session: session
            )

        case .keepCaptured(let string):
            return autoSelection(
                targetString: string,
                classification: classification,
                snapshotString: candidate
            )

        case .decisiveRecapture, .needsStableRecapture:
            return autoSelection(
                targetString: nil,
                classification: classification,
                snapshotString: candidate
            )
        }
    }

    private func captureSelection(
        _ string: PipaString,
        classification: AutoStringClassification,
        snapshotString: PipaString,
        eventLabel: String,
        session: TuningSessionCoordinator
    ) -> AutoTuningTargetSelection {
        session.captureAutoDetectedString(string)
        return autoSelection(
            targetString: string,
            classification: classification,
            snapshotString: snapshotString,
            autoDetectedString: string,
            events: [formatter.autoStringEventText(label: eventLabel, string: string)],
            activeString: string
        )
    }

    private func autoSelection(
        targetString: PipaString?,
        classification: AutoStringClassification,
        snapshotString: PipaString,
        autoDetectedString: PipaString? = nil,
        events: [String] = [],
        activeString: PipaString? = nil
    ) -> AutoTuningTargetSelection {
        AutoTuningTargetSelection(
            targetString: targetString,
            classification: classification,
            snapshotString: snapshotString,
            autoDetectedString: autoDetectedString,
            events: events,
            activeString: activeString,
            shouldClearAutoCandidates: false
        )
    }
}
