import Foundation

struct TuningFrameProcessor {
    private let normalizer = TargetPitchNormalizer()

    func process(
        _ detection: PitchDetectionResult,
        for string: PipaString,
        mode: TuningMode
    ) -> TuningFrameProcessingResult {
        guard detection.confidence >= TunerConfiguration.PitchDetection.minimumConfidence else {
            return .rejected(.lowConfidence(detection.confidence))
        }

        switch mode {
        case .manual:
            guard isManualRawFrequencyUsable(detection.frequency, for: string) else {
                return .rejected(.manualHighHarmonic(detection.frequency))
            }
            return .accepted(TuningFrameAcceptedDetection(detection: detection, source: .raw))

        case .auto:
            guard let normalizedDetection = normalizer.normalizedDetection(detection, for: string) else {
                return .rejected(.outsideTargetRange(detection.frequency))
            }
            return .accepted(TuningFrameAcceptedDetection(detection: normalizedDetection, source: .normalized))
        }
    }

    private func isManualRawFrequencyUsable(_ frequency: Double, for string: PipaString) -> Bool {
        frequency <= string.targetFrequency * TunerConfiguration.Tuning.manualMaximumRawFrequencyMultiplier
    }
}

enum TuningFrameProcessingResult: Equatable {
    case accepted(TuningFrameAcceptedDetection)
    case rejected(TuningFrameRejectionReason)
}

struct TuningFrameAcceptedDetection: Equatable {
    let detection: PitchDetectionResult
    let source: TuningFrameDetectionSource
}

enum TuningFrameDetectionSource: Equatable {
    case raw
    case normalized
}

enum TuningFrameRejectionReason: Equatable {
    case lowConfidence(Double)
    case manualHighHarmonic(Double)
    case outsideTargetRange(Double)
}
