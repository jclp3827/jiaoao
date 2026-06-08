import Foundation

struct AutoTargetResolver {
    func resolve(
        classification: AutoStringClassification,
        capturedString: PipaString?
    ) -> AutoTargetResolution {
        let candidate = classification.bestCandidate.string

        if let capturedString {
            guard candidate != capturedString else {
                return .keepCaptured(capturedString)
            }

            if isDecisiveAutoCandidate(classification) {
                return .decisiveRecapture(candidate)
            }

            guard isStrongAutoRecapture(classification, replacing: capturedString) else {
                return .keepCaptured(capturedString)
            }

            return .needsStableRecapture(candidate)
        }

        if isDecisiveAutoCandidate(classification) {
            return .decisiveInitial(candidate)
        }

        return .needsStableInitial(candidate)
    }

    private func isStrongAutoRecapture(
        _ classification: AutoStringClassification,
        replacing capturedString: PipaString
    ) -> Bool {
        guard let capturedCandidate = classification.rankedCandidates.first(where: { $0.string == capturedString }) else {
            return true
        }

        return classification.bestCandidate.classificationScore + TunerConfiguration.AutoClassification.recaptureScoreMargin
            < capturedCandidate.classificationScore
    }

    private func isDecisiveAutoCandidate(_ classification: AutoStringClassification) -> Bool {
        guard classification.bestCandidate.string == classification.primaryBandString else {
            return false
        }

        guard classification.bestCandidate.confidence >= TunerConfiguration.PitchDetection.minimumConfidence else {
            return false
        }

        if classification.bestCandidate.rawCentsDistance <= TunerConfiguration.AutoClassification.decisiveRawCentsWindow {
            return true
        }

        guard classification.rankedCandidates.count > 1 else {
            return true
        }

        let scoreGap = classification.rankedCandidates[1].classificationScore
            - classification.bestCandidate.classificationScore
        return scoreGap >= TunerConfiguration.AutoClassification.decisiveScoreGap
    }
}

enum AutoTargetResolution: Equatable {
    case keepCaptured(PipaString)
    case decisiveInitial(PipaString)
    case needsStableInitial(PipaString)
    case decisiveRecapture(PipaString)
    case needsStableRecapture(PipaString)
}
