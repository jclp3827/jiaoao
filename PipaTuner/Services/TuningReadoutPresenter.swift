import Foundation

struct TuningReadoutPresenter {
    private let formatter = TunerPresentationFormatter()

    func readout(for result: TuningResult, string: PipaString) -> TuningReadoutState {
        TuningReadoutState(
            detectedFrequencyText: result.frequencyText,
            centsText: result.centsText,
            centsOffset: result.centsOffset,
            confidenceText: TuningGuide.confidenceLabel(result.confidence),
            directionText: directionText(for: result, string: string),
            statusColorName: formatter.colorName(for: result.direction)
        )
    }

    private func directionText(for result: TuningResult, string: PipaString) -> String {
        switch result.direction {
        case .flat:
            let ratio = result.detectedFrequency / string.targetFrequency
            guard ratio >= 0.82 else {
                return "明显偏低，先拧紧"
            }
            return "偏低，继续拧紧"
        case .sharp:
            return "偏高，稍微放松"
        case .inTune:
            return "已准"
        case .silent:
            return "等待拨弦"
        }
    }
}

struct TuningReadoutState: Equatable {
    let detectedFrequencyText: String
    let centsText: String
    let centsOffset: Double?
    let confidenceText: String
    let directionText: String
    let statusColorName: String
}
