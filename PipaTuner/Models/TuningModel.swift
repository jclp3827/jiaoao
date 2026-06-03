import Foundation

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

    var scientificNoteName: String {
        switch self {
        case .fourth: return "A3"
        case .third: return "D4"
        case .second: return "E4"
        case .first: return "A4"
        }
    }

    var targetFrequency: Double {
        switch self {
        case .fourth: return 220.0
        case .third: return 293.6
        case .second: return 329.6
        case .first: return 440.0
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
        case .fourth: return "220 Hz"
        case .third: return "293.6 Hz"
        case .second: return "329.6 Hz"
        case .first: return "440 Hz"
        }
    }

    var targetDisplayText: String {
        "\(displayPitchName) · \(frequencyLabel) · \(jianpuLabel)"
    }

    var jianpuLabel: String {
        switch self {
        case .fourth: return "低音 5"
        case .third: return "中音 1"
        case .second: return "中音 2"
        case .first: return "中音 5"
        }
    }

    var tuningHint: String {
        switch self {
        case .fourth: return "把缠弦调到大 A，220 Hz。"
        case .third: return "把老弦调到 d，293.6 Hz。"
        case .second: return "把中弦调到 e，329.6 Hz。"
        case .first: return "把子弦调到 a，440 Hz。"
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
    static let inTuneThresholdCents = 12.0
    static let silenceThreshold = 0.01

    static func evaluate(detectedFrequency: Double, targetFrequency: Double, confidence: Double) -> TuningResult {
        let cents = 1200.0 * log2(detectedFrequency / targetFrequency)
        let absoluteCents = abs(cents)
        let direction: TuningDirection

        if confidence < 0.2 {
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
