import Foundation

struct AutoStringClassifier {
    func classify(
        detection: PitchDetectionResult,
        fallbackString: PipaString,
        preferredString: PipaString? = nil
    ) -> AutoStringClassification {
        let primaryBandString = PipaString.primaryAutoBandString(for: detection.frequency)
        let candidates = PipaString.tuningOrder.compactMap { string -> AutoStringCandidate? in
            guard let normalizedCandidate = PitchNormalization.bestCandidate(
                from: detection.frequency,
                targetFrequency: string.targetFrequency
            ) else {
                return nil
            }

            let cents = abs(normalizedCandidate.cents)
            let rawDeltaCents = abs(
                TunerConfiguration.Tuning.centsOctaveUnit * log2(detection.frequency / string.targetFrequency)
            )
            let normalizationPenalty = normalizationPenalty(
                divisor: normalizedCandidate.divisor,
                multiplier: normalizedCandidate.multiplier
            )
            let primaryBandPenalty = autoPrimaryBandPenalty(
                rawFrequency: detection.frequency,
                primaryBandString: primaryBandString,
                candidate: string,
                normalizedCandidate: normalizedCandidate,
                preferredString: preferredString
            )
            let selectedStringBonus = selectedStringPriorBonus(
                rawFrequency: detection.frequency,
                candidate: string,
                preferredString: preferredString
            )
            return AutoStringCandidate(
                string: string,
                normalizedFrequency: normalizedCandidate.frequency,
                confidence: detection.confidence,
                centsDistance: cents,
                rawCentsDistance: rawDeltaCents,
                normalizationPenalty: normalizationPenalty + primaryBandPenalty - selectedStringBonus,
                classificationScore: cents + normalizationPenalty + primaryBandPenalty - selectedStringBonus
            )
        }
        .sorted { lhs, rhs in
            if abs(lhs.classificationScore - rhs.classificationScore) > 0.1 {
                return lhs.classificationScore < rhs.classificationScore
            }
            if abs(lhs.rawCentsDistance - rhs.rawCentsDistance) > 0.1 {
                return lhs.rawCentsDistance < rhs.rawCentsDistance
            }
            if abs(lhs.centsDistance - rhs.centsDistance) > 0.1 {
                return lhs.centsDistance < rhs.centsDistance
            }
            return lhs.confidence > rhs.confidence
        }

        return AutoStringClassification(
            bestCandidate: candidates.first ?? AutoStringCandidate(
                string: fallbackString,
                normalizedFrequency: detection.frequency,
                confidence: detection.confidence,
                centsDistance: .greatestFiniteMagnitude,
                rawCentsDistance: .greatestFiniteMagnitude,
                normalizationPenalty: .greatestFiniteMagnitude,
                classificationScore: .greatestFiniteMagnitude
            ),
            rankedCandidates: candidates,
            primaryBandString: primaryBandString
        )
    }

    private func normalizationPenalty(divisor: Double, multiplier: Double) -> Double {
        let divisorPenalty = divisor == 1.0 ? 0.0 : TunerConfiguration.AutoClassification.divisorPenalty * log2(divisor)
        let multiplierPenalty = multiplier == 1.0 ? 0.0 : TunerConfiguration.AutoClassification.multiplierPenalty * log2(multiplier)
        return divisorPenalty + multiplierPenalty
    }

    private func autoPrimaryBandPenalty(
        rawFrequency: Double,
        primaryBandString: PipaString?,
        candidate: PipaString,
        normalizedCandidate: NormalizedPitchCandidate,
        preferredString: PipaString?
    ) -> Double {
        guard let primaryBandString else {
            return 0.0
        }

        guard primaryBandString != candidate else {
            return 0.0
        }

        if normalizedCandidate.multiplier > 1.0 {
            if selectedStringPriorBonus(
                rawFrequency: rawFrequency,
                candidate: candidate,
                preferredString: preferredString
            ) > 0 {
                return 0.0
            }
            return TunerConfiguration.AutoClassification.lowRawPrimaryBandPenalty
        }

        let boundaryDistance = abs(
            TunerConfiguration.Tuning.centsOctaveUnit * log2(rawFrequency / primaryBandString.targetFrequency)
        )
        let scaledPenalty = max(
            TunerConfiguration.AutoClassification.primaryBandPenalty - boundaryDistance * 0.35,
            TunerConfiguration.AutoClassification.primaryBandPenalty * 0.4
        )
        return scaledPenalty
    }

    private func selectedStringPriorBonus(
        rawFrequency: Double,
        candidate: PipaString,
        preferredString: PipaString?
    ) -> Double {
        guard candidate == preferredString else {
            return 0.0
        }

        guard rawFrequency < candidate.targetFrequency * 0.75 else {
            return 0.0
        }

        return TunerConfiguration.AutoClassification.selectedStringPriorBonus
    }
}
