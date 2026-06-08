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
        guard result.direction == .flat else {
            return result.directionText
        }

        let ratio = result.detectedFrequency / string.targetFrequency
        guard ratio < 0.82 else {
            return result.directionText
        }

        return "明显偏低，继续上紧"
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
