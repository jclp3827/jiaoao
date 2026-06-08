import Foundation

struct TunerPresentationFormatter {
    var rawDetectionLabel: String { "原始" }
    var assistedDetectionLabel: String { "辅助" }
    var decisiveRecaptureLabel: String { "明确换弦" }
    var recaptureCandidateLabel: String { "换弦候选" }
    var stableRecaptureLabel: String { "重新判弦" }
    var autoDetectionLabel: String { "自动判弦" }
    var autoCandidateLabel: String { "自动候选" }

    func detectionEventText(label: String, detection: PitchDetectionResult) -> String {
        "\(label) \(frequencyText(detection.frequency)) · \(percentText(detection.confidence))"
    }

    func acceptedDetectionEventText(_ accepted: TuningFrameAcceptedDetection) -> String {
        "\(acceptedDetectionSourceText(accepted.source)) \(frequencyText(accepted.detection.frequency))"
    }

    func rejectedDetectionEventText(for reason: TuningFrameRejectionReason) -> String {
        switch reason {
        case .lowConfidence(let confidence):
            return "置信度过低，未采纳 \(percentText(confidence))"
        case .manualHighHarmonic(let frequency):
            return "高次谐波未采纳 \(frequencyText(frequency))"
        case .outsideTargetRange(let frequency):
            return "超出目标范围，未采纳 \(frequencyText(frequency))"
        }
    }

    func lockedDetectionEventText(label: String, detection: PitchDetectionResult) -> String {
        "\(label) \(frequencyText(detection.frequency))"
    }

    func autoStringEventText(label: String, string: PipaString) -> String {
        "\(label) \(string.shortName)"
    }

    func eventText(for reason: PitchAnalysisReason) -> String {
        switch reason {
        case .success:
            return "检测成功"
        case .missingInput:
            return "音频输入缺失"
        case .emptyBuffer:
            return "空音频帧"
        case .silence:
            return "等待拨弦或余音衰减"
        case .frameTooShort:
            return "采样帧过短"
        case .noCandidate:
            return "未找到稳定候选音高"
        case .lowConfidence:
            return "检测置信度过低"
        }
    }

    func frequencyText(_ value: Double) -> String {
        String(format: "%.1f Hz", value)
    }

    func percentText(_ value: Double) -> String {
        "\(Int((value * 100.0).rounded()))%"
    }

    func colorName(for direction: TuningDirection) -> String {
        switch direction {
        case .flat:
            return "orange"
        case .sharp:
            return "blue"
        case .inTune:
            return "green"
        case .silent:
            return "secondary"
        }
    }

    func autoCandidateSummary(for candidate: AutoStringCandidate) -> String {
        "\(candidate.string.shortName) \(frequencyText(candidate.normalizedFrequency)) · 分数 \(String(format: "%.0f", candidate.classificationScore))"
    }

    private func acceptedDetectionSourceText(_ source: TuningFrameDetectionSource) -> String {
        switch source {
        case .raw:
            return "原始采纳"
        case .normalized:
            return "折算采纳"
        }
    }
}
