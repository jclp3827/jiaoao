import XCTest
@testable import PipaTuner

final class PipaTunerTests: XCTestCase {
    func testStringTargetsMatchReferenceTuning() {
        XCTAssertEqual(PipaString.fourth.targetFrequency, 220.0, accuracy: 0.001)
        XCTAssertEqual(PipaString.third.targetFrequency, 293.6, accuracy: 0.001)
        XCTAssertEqual(PipaString.second.targetFrequency, 329.6, accuracy: 0.001)
        XCTAssertEqual(PipaString.first.targetFrequency, 440.0, accuracy: 0.001)
    }

    func testStringLabelsMatchReferenceTuning() {
        XCTAssertEqual(PipaString.fourth.displayPitchName, "大 A")
        XCTAssertEqual(PipaString.fourth.roleName, "缠弦")
        XCTAssertEqual(PipaString.fourth.scientificNoteName, "A3")
        XCTAssertEqual(PipaString.third.displayPitchName, "d")
        XCTAssertEqual(PipaString.third.roleName, "老弦")
        XCTAssertEqual(PipaString.third.scientificNoteName, "D4")
        XCTAssertEqual(PipaString.second.displayPitchName, "e")
        XCTAssertEqual(PipaString.second.roleName, "中弦")
        XCTAssertEqual(PipaString.second.scientificNoteName, "E4")
        XCTAssertEqual(PipaString.first.displayPitchName, "a")
        XCTAssertEqual(PipaString.first.roleName, "子弦")
        XCTAssertEqual(PipaString.first.scientificNoteName, "A4")
    }

    func testTuningOrderMatchesNaturalStringOrder() {
        XCTAssertEqual(PipaString.tuningOrder, [.first, .second, .third, .fourth])
    }

    @MainActor
    func testSelectedStringUpdatesReadoutTargetImmediately() {
        let viewModel = TunerViewModel()

        viewModel.selectedString = .first
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.first.targetDisplayText)

        viewModel.selectedString = .second
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.second.targetDisplayText)

        viewModel.selectedString = .third
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.third.targetDisplayText)

        viewModel.selectedString = .fourth
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.fourth.targetDisplayText)
    }

    func testTargetDisplayTextMatchesTable() {
        XCTAssertEqual(PipaString.fourth.targetDisplayText, "大 A · 220 Hz · 低音 5")
        XCTAssertEqual(PipaString.third.targetDisplayText, "d · 293.6 Hz · 中音 1")
        XCTAssertEqual(PipaString.second.targetDisplayText, "e · 329.6 Hz · 中音 2")
        XCTAssertEqual(PipaString.first.targetDisplayText, "a · 440 Hz · 中音 5")
    }

    @MainActor
    func testSilentDetectionKeepsLastVisibleReadout() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first
        viewModel.handleDetection(PitchDetectionResult(frequency: 438.0, confidence: 0.92, rms: 0.2))

        let detectedFrequencyText = viewModel.detectedFrequencyText
        let centsText = viewModel.centsText
        let confidenceText = viewModel.confidenceText
        let directionText = viewModel.directionText

        viewModel.handleDetection(nil)

        XCTAssertEqual(viewModel.detectedFrequencyText, detectedFrequencyText)
        XCTAssertEqual(viewModel.centsText, centsText)
        XCTAssertEqual(viewModel.confidenceText, confidenceText)
        XCTAssertEqual(viewModel.directionText, directionText)
        XCTAssertEqual(viewModel.microphoneStatusText, "等待下一次拨弦")
    }

    @MainActor
    func testAudioFrameUpdatesActivityWithoutChangingTuningBasis() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .second
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: 331.0, confidence: 0.88, rms: 0.15),
            activityLevel: 0.6
        ))

        XCTAssertEqual(viewModel.inputActivityLevel, 0.6, accuracy: 0.001)
        XCTAssertEqual(viewModel.recognitionStatusText, "已捕捉，等待声音结束")
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.second.targetDisplayText)
    }

    @MainActor
    func testAudioFramesPublishHighestConfidenceResultAfterPluckEnds() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: 430.0, confidence: 0.4, rms: 0.12),
            activityLevel: 0.6
        ))
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: 441.0, confidence: 0.95, rms: 0.16),
            activityLevel: 0.7
        ))
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: 448.0, confidence: 0.72, rms: 0.14),
            activityLevel: 0.5
        ))

        XCTAssertEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertEqual(viewModel.recognitionStatusText, "已捕捉，等待声音结束")

        viewModel.handleAudioFrame(AudioAnalysisFrame(detection: nil, activityLevel: 0))

        XCTAssertEqual(viewModel.detectedFrequencyText, "441.0 Hz")
        XCTAssertEqual(viewModel.confidenceText, "95%")
        XCTAssertEqual(viewModel.microphoneStatusText, "已显示本次最佳结果")
    }

    @MainActor
    func testSilentAudioFrameKeepsLastReadoutAndDropsActivity() {
        let viewModel = TunerViewModel()
        viewModel.handleAudioFrame(AudioAnalysisFrame(
            detection: PitchDetectionResult(frequency: 438.0, confidence: 0.92, rms: 0.2),
            activityLevel: 0.7
        ))

        viewModel.handleAudioFrame(AudioAnalysisFrame(detection: nil, activityLevel: 0))
        let detectedFrequencyText = viewModel.detectedFrequencyText
        viewModel.handleAudioFrame(AudioAnalysisFrame(detection: nil, activityLevel: 0))

        XCTAssertEqual(viewModel.inputActivityLevel, 0, accuracy: 0.001)
        XCTAssertEqual(viewModel.recognitionStatusText, "等待下一次拨弦")
        XCTAssertEqual(viewModel.detectedFrequencyText, detectedFrequencyText)
    }

    func testTuningGuideMarksLowPitchAsFlat() {
        let result = TuningGuide.evaluate(detectedFrequency: 210.0, targetFrequency: 220.0, confidence: 0.9)
        XCTAssertEqual(result.direction, .flat)
        XCTAssertLessThan(result.centsOffset, 0)
    }

    func testTuningGuideMarksHighPitchAsSharp() {
        let result = TuningGuide.evaluate(detectedFrequency: 230.0, targetFrequency: 220.0, confidence: 0.9)
        XCTAssertEqual(result.direction, .sharp)
        XCTAssertGreaterThan(result.centsOffset, 0)
    }

    func testTuningGuideMarksInTuneWithinThreshold() {
        let result = TuningGuide.evaluate(detectedFrequency: 221.5, targetFrequency: 220.0, confidence: 0.9)
        XCTAssertEqual(result.direction, .inTune)
    }

    func testPitchDetectionRecognizesPureTone() {
        assertDetectedPitch(frequency: 220.0)
    }

    func testPitchDetectionRecognizesAllPipaStringTargets() {
        for string in PipaString.tuningOrder {
            assertDetectedPitch(frequency: string.targetFrequency)
        }
    }

    func testPitchDetectionPrefersFundamentalWhenSecondHarmonicIsPresent() {
        let sampleRate = 44_100.0
        let frequency = 220.0
        let sampleCount = 8192
        let samples = (0..<sampleCount).map { index -> Float in
            let t = Double(index) / sampleRate
            let fundamental = sin(2.0 * Double.pi * frequency * t) * 0.28
            let secondHarmonic = sin(2.0 * Double.pi * frequency * 2.0 * t) * 0.20
            return Float(fundamental + secondHarmonic)
        }

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 2.0)
    }

    private func assertDetectedPitch(frequency: Double, file: StaticString = #filePath, line: UInt = #line) {
        let sampleRate = 44_100.0
        let sampleCount = 8192
        let samples = (0..<sampleCount).map { index -> Float in
            let t = Double(index) / sampleRate
            return Float(sin(2.0 * Double.pi * frequency * t) * 0.35)
        }

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: sampleRate)

        XCTAssertNotNil(result, file: file, line: line)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 2.0, file: file, line: line)
    }
}
