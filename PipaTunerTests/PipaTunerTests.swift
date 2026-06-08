import XCTest
@testable import PipaTuner

final class PipaTunerTests: XCTestCase {}

extension PipaTunerTests {
    var testSampleRate: Double { 44_100.0 }
    var testSampleCount: Int { 8192 }

    @MainActor
    func sendDetectedFrame(
        frequency: Double,
        confidence: Double,
        rms: Double,
        activity: Double,
        to viewModel: TunerViewModel
    ) {
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: frequency, confidence: confidence, rms: rms),
            activityLevel: activity
        ))
    }

    @MainActor
    func sendRawFrame(
        frequency: Double,
        confidence: Double,
        rms: Double,
        activity: Double,
        assistedFrequency: Double? = nil,
        assistedConfidence: Double? = nil,
        assistedRMS: Double? = nil,
        to viewModel: TunerViewModel
    ) {
        let assistedDetection = assistedFrequency.map {
            PitchDetectionResult(
                frequency: $0,
                confidence: assistedConfidence ?? confidence,
                rms: assistedRMS ?? rms
            )
        }

        viewModel.handleAudioFrame(AudioAnalysisFrame(
            rawDetection: PitchDetectionResult(frequency: frequency, confidence: confidence, rms: rms),
            assistedDetection: assistedDetection,
            activityLevel: activity
        ))
    }

    @MainActor
    func finishPluck(on viewModel: TunerViewModel, count: Int = 1) {
        for _ in 0..<count {
            viewModel.handleAudioFrame(AudioAnalysisFrame(detection: nil, activityLevel: 0))
        }
    }

    @MainActor
    func sendRejectedFrame(
        reason: PitchAnalysisReason,
        activity: Double,
        to viewModel: TunerViewModel
    ) {
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: nil,
            activityLevel: activity,
            analysisReason: reason
        ))
    }

    @MainActor
    func sendAutoPluck(
        _ frames: [(frequency: Double, confidence: Double, rms: Double, activity: Double)],
        to viewModel: TunerViewModel
    ) {
        for frame in frames {
            sendRawFrame(
                frequency: frame.frequency,
                confidence: frame.confidence,
                rms: frame.rms,
                activity: frame.activity,
                to: viewModel
            )
        }
        finishPluck(on: viewModel)
    }

    @MainActor
    func sendManualPluck(
        _ frames: [(frequency: Double, confidence: Double, rms: Double, activity: Double)],
        to viewModel: TunerViewModel
    ) {
        for frame in frames {
            sendDetectedFrame(
                frequency: frame.frequency,
                confidence: frame.confidence,
                rms: frame.rms,
                activity: frame.activity,
                to: viewModel
            )
        }
        finishPluck(on: viewModel)
    }

    @MainActor
    func assertManualLock(
        on viewModel: TunerViewModel,
        frequencyText: String,
        directionText: String,
        centsSign: FloatingPointSign,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(viewModel.detectedFrequencyText, frequencyText, file: file, line: line)
        XCTAssertEqual(viewModel.directionText, directionText, file: file, line: line)
        if centsSign == .plus {
            XCTAssertGreaterThan(viewModel.centsOffset ?? 0, 0, file: file, line: line)
        } else {
            XCTAssertLessThan(viewModel.centsOffset ?? 0, 0, file: file, line: line)
        }
    }

    @MainActor
    func assertAutoLock(
        on viewModel: TunerViewModel,
        string: PipaString,
        frequency: Double,
        accuracy: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(viewModel.activeString, string, file: file, line: line)
        XCTAssertEqual(viewModel.diagnostics.autoDetectedStringName, string.shortName, file: file, line: line)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, frequency, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, frequency, accuracy: accuracy, file: file, line: line)
    }

    func sineSamples(
        frequency: Double,
        amplitude: Double,
        sampleRate: Double? = nil,
        sampleCount: Int? = nil
    ) -> [Float] {
        let resolvedSampleRate = sampleRate ?? testSampleRate
        let resolvedSampleCount = sampleCount ?? testSampleCount

        return (0..<resolvedSampleCount).map { index -> Float in
            let t = Double(index) / resolvedSampleRate
            return Float(sin(2.0 * Double.pi * frequency * t) * amplitude)
        }
    }

    func harmonicSamples(
        frequency: Double,
        components: [(multiple: Double, amplitude: Double)],
        sampleRate: Double? = nil,
        sampleCount: Int? = nil
    ) -> [Float] {
        let resolvedSampleRate = sampleRate ?? testSampleRate
        let resolvedSampleCount = sampleCount ?? testSampleCount

        return (0..<resolvedSampleCount).map { index -> Float in
            let t = Double(index) / resolvedSampleRate
            let value = components.reduce(0.0) { partialResult, component in
                partialResult + sin(2.0 * Double.pi * frequency * component.multiple * t) * component.amplitude
            }
            return Float(value)
        }
    }
}
