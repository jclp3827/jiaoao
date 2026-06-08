import Foundation

enum TuningMode: String, CaseIterable, Identifiable, Codable {
    case manual
    case auto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "手动"
        case .auto: return "自动"
        }
    }

    var subtitle: String {
        switch self {
        case .manual: return "手选弦"
        case .auto: return "自动判弦"
        }
    }
}

enum PipaString: String, CaseIterable, Identifiable, Codable {
    case fourth = "四弦（缠弦）"
    case third = "三弦（老弦）"
    case second = "二弦（中弦）"
    case first = "一弦（子弦）"

    var id: String { rawValue }

    static let tuningOrder: [PipaString] = [.first, .second, .third, .fourth]

    var shortName: String {
        switch self {
        case .fourth: return "四弦"
        case .third: return "三弦"
        case .second: return "二弦"
        case .first: return "一弦"
        }
    }

    var roleName: String {
        switch self {
        case .fourth: return "缠弦"
        case .third: return "老弦"
        case .second: return "中弦"
        case .first: return "子弦"
        }
    }

    var scientificNoteName: String {
        switch self {
        case .fourth: return "A2"
        case .third: return "D3"
        case .second: return "E3"
        case .first: return "A3"
        }
    }

    var targetFrequency: Double {
        switch self {
        case .fourth: return 110.0
        case .third: return 146.8
        case .second: return 164.8
        case .first: return 220.0
        }
    }

    var displayPitchName: String {
        switch self {
        case .fourth: return "大 A"
        case .third: return "d"
        case .second: return "e"
        case .first: return "a"
        }
    }

    var frequencyLabel: String {
        switch self {
        case .fourth: return "110 Hz"
        case .third: return "146.8 Hz"
        case .second: return "164.8 Hz"
        case .first: return "220 Hz"
        }
    }

    var targetDisplayText: String {
        "\(displayPitchName) · \(frequencyLabel) · \(jianpuLabel)"
    }

    var jianpuLabel: String {
        switch self {
        case .fourth: return "倍低音 5"
        case .third: return "低音 1"
        case .second: return "低音 2"
        case .first: return "低音 5"
        }
    }

    var tuningHint: String {
        switch self {
        case .fourth: return "把缠弦调到大 A，110 Hz。"
        case .third: return "把老弦调到 d，146.8 Hz。"
        case .second: return "把中弦调到 e，164.8 Hz。"
        case .first: return "把子弦调到 a，220 Hz。"
        }
    }

    static func primaryAutoBandString(for rawFrequency: Double) -> PipaString? {
        let cappedUpper = first.targetFrequency * TunerConfiguration.AutoClassification.primaryBandUpperMultiplier
        let cappedLower = max(
            TunerConfiguration.PitchDetection.minimumFrequency,
            fourth.targetFrequency * TunerConfiguration.AutoClassification.primaryBandLowerMultiplier
        )
        guard rawFrequency >= cappedLower, rawFrequency <= cappedUpper else {
            return nil
        }

        let fourthThirdBoundary = sqrt(fourth.targetFrequency * third.targetFrequency)
        let thirdSecondBoundary = sqrt(third.targetFrequency * second.targetFrequency)
        let secondFirstBoundary = sqrt(second.targetFrequency * first.targetFrequency)

        switch rawFrequency {
        case ..<fourthThirdBoundary:
            return .fourth
        case ..<thirdSecondBoundary:
            return .third
        case ..<secondFirstBoundary:
            return .second
        default:
            return .first
        }
    }
}

enum TuningDirection: String {
    case flat
    case sharp
    case inTune
    case silent
}

struct TuningResult {
    let detectedFrequency: Double
    let targetFrequency: Double
    let centsOffset: Double
    let direction: TuningDirection
    let confidence: Double

    var frequencyText: String {
        String(format: "%.1f Hz", detectedFrequency)
    }

    var centsText: String {
        let prefix = centsOffset >= 0 ? "+" : ""
        return String(format: "%@%.1f cents", prefix, centsOffset)
    }

    var directionText: String {
        switch direction {
        case .flat:
            return "偏低，往上拧一点"
        case .sharp:
            return "偏高，往下松一点"
        case .inTune:
            return "音高接近目标"
        case .silent:
            return "请靠近麦克风并拨动所选弦"
        }
    }
}

enum TuningGuide {
    static let inTuneThresholdCents = TunerConfiguration.Tuning.inTuneThresholdCents
    static let silenceThreshold = TunerConfiguration.PitchDetection.silenceRMS

    static func evaluate(detectedFrequency: Double, targetFrequency: Double, confidence: Double) -> TuningResult {
        let cents = TunerConfiguration.Tuning.centsOctaveUnit * log2(detectedFrequency / targetFrequency)
        let absoluteCents = abs(cents)
        let direction: TuningDirection

        if confidence < TunerConfiguration.PitchDetection.minimumConfidence {
            direction = .silent
        } else if absoluteCents <= inTuneThresholdCents {
            direction = .inTune
        } else if cents < 0 {
            direction = .flat
        } else {
            direction = .sharp
        }

        return TuningResult(
            detectedFrequency: detectedFrequency,
            targetFrequency: targetFrequency,
            centsOffset: cents,
            direction: direction,
            confidence: confidence
        )
    }

    static func confidenceLabel(_ confidence: Double) -> String {
        let percentage = max(0, min(100, Int((confidence * 100).rounded())))
        return "\(percentage)%"
    }
}

struct NormalizedPitchCandidate: Equatable {
    let frequency: Double
    let cents: Double
    let divisor: Double
    let multiplier: Double
    let score: Double

    var isWithinDisplayRange: Bool {
        abs(cents) <= TunerConfiguration.Tuning.centsDisplayRange
    }
}

enum PitchNormalization {
    static func bestCandidate(
        from detectedFrequency: Double,
        targetFrequency: Double
    ) -> NormalizedPitchCandidate? {
        let divisors = TunerConfiguration.Harmonics.divisors
        let multipliers = TunerConfiguration.Harmonics.multipliers
        var best: NormalizedPitchCandidate?

        for divisor in divisors {
            guard shouldUseDivisor(
                divisor,
                detectedFrequency: detectedFrequency,
                targetFrequency: targetFrequency
            ) else {
                continue
            }

            for multiplier in multipliers {
                let frequency = detectedFrequency / divisor * multiplier
                let cents = TunerConfiguration.Tuning.centsOctaveUnit * log2(frequency / targetFrequency)
                let harmonicPenalty = divisor == 1.0 ? 0.0 : TunerConfiguration.Harmonics.harmonicPenalty * log2(divisor)
                let subharmonicPenalty = multiplier == 1.0 ? 0.0 : TunerConfiguration.Harmonics.subharmonicPenalty * log2(multiplier)
                let candidate = NormalizedPitchCandidate(
                    frequency: frequency,
                    cents: cents,
                    divisor: divisor,
                    multiplier: multiplier,
                    score: abs(cents) + harmonicPenalty + subharmonicPenalty
                )

                if best == nil || candidate.score < best!.score {
                    best = candidate
                }
            }
        }

        guard let best, best.isWithinDisplayRange else {
            return nil
        }

        return best
    }

    private static func shouldUseDivisor(
        _ divisor: Double,
        detectedFrequency: Double,
        targetFrequency: Double
    ) -> Bool {
        guard divisor > 1.0 else {
            return true
        }

        let harmonicFrequency = targetFrequency * divisor
        let centsFromExpectedHarmonic = TunerConfiguration.Tuning.centsOctaveUnit
            * log2(detectedFrequency / harmonicFrequency)
        return abs(centsFromExpectedHarmonic) <= TunerConfiguration.Harmonics.harmonicMatchWindowCents
    }
}
