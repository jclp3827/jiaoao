import Foundation

struct TargetPitchNormalizer {
    func candidate(
        for detection: PitchDetectionResult,
        string: PipaString
    ) -> NormalizedPitchCandidate? {
        PitchNormalization.bestCandidate(
            from: detection.frequency,
            targetFrequency: string.targetFrequency
        )
    }

    func normalizedDetection(
        _ detection: PitchDetectionResult,
        for string: PipaString
    ) -> PitchDetectionResult? {
        guard let best = candidate(for: detection, string: string) else {
            return nil
        }

        return PitchDetectionResult(
            frequency: best.frequency,
            confidence: detection.confidence,
            rms: detection.rms
        )
    }
}
