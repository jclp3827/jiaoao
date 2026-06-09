import XCTest
@testable import PipaTuner

extension PipaTunerTests {
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

    @MainActor
    func testChangingStringClearsLockedReadoutAndMeter() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first
        sendDetectedFrame(frequency: 438.0, confidence: 0.92, rms: 0.2, activity: 0.7, to: viewModel)

        XCTAssertNotEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertNotNil(viewModel.centsOffset)

        viewModel.selectedString = .second

        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.second.targetDisplayText)
        XCTAssertEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertEqual(viewModel.centsText, "--")
        XCTAssertNil(viewModel.centsOffset)
        XCTAssertEqual(viewModel.confidenceText, "0%")
        XCTAssertEqual(viewModel.directionText, PipaString.second.tuningHint)
    }

    @MainActor
    func testInactiveAudioFrameKeepsLastVisibleReadout() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first
        sendDetectedFrame(frequency: 438.0, confidence: 0.92, rms: 0.2, activity: 0.7, to: viewModel)

        let detectedFrequencyText = viewModel.detectedFrequencyText
        let centsText = viewModel.centsText
        let confidenceText = viewModel.confidenceText
        let directionText = viewModel.directionText

        finishPluck(on: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.detectedFrequencyText, detectedFrequencyText)
        XCTAssertEqual(viewModel.centsText, centsText)
        XCTAssertEqual(viewModel.confidenceText, confidenceText)
        XCTAssertEqual(viewModel.directionText, directionText)
        XCTAssertEqual(viewModel.microphoneStatusText, "正在监听")
    }

    @MainActor
    func testAudioFrameUpdatesActivityWithoutChangingTuningBasis() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .second
        sendDetectedFrame(frequency: 331.0, confidence: 0.88, rms: 0.15, activity: 0.6, to: viewModel)

        XCTAssertEqual(viewModel.inputActivityLevel, 0.6, accuracy: 0.001)
        XCTAssertEqual(viewModel.recognitionStatusText, "保持片刻，等待稳定")
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.second.targetDisplayText)
    }

    @MainActor
    func testAudioFramesLockStableResultAfterPluckEnds() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendDetectedFrame(frequency: 439.0, confidence: 0.82, rms: 0.12, activity: 0.6, to: viewModel)
        sendDetectedFrame(frequency: 441.0, confidence: 0.90, rms: 0.16, activity: 0.7, to: viewModel)
        sendDetectedFrame(frequency: 440.0, confidence: 0.99, rms: 0.14, activity: 0.5, to: viewModel)

        XCTAssertEqual(viewModel.detectedFrequencyText, "440.0 Hz")
        XCTAssertEqual(viewModel.recognitionStatusText, "保持片刻，等待稳定")

        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.detectedFrequencyText, "440.0 Hz")
        XCTAssertEqual(viewModel.confidenceText, "90%")
        XCTAssertEqual(viewModel.microphoneStatusText, "正在监听")
        XCTAssertEqual(viewModel.recognitionStatusText, "已锁定")
    }

    @MainActor
    func testManualModeRejectsVeryHighFirstStringHarmonic() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendManualPluck([
            (frequency: 880.0, confidence: 0.91, rms: 0.16, activity: 0.7),
            (frequency: 878.0, confidence: 0.88, rms: 0.14, activity: 0.6)
        ], to: viewModel)

        XCTAssertEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertNil(viewModel.diagnostics.acceptedFrequency)
        XCTAssertNil(viewModel.diagnostics.lockedFrequency)
        XCTAssertEqual(viewModel.microphoneStatusText, "拨弦稍轻")
    }

    @MainActor
    func testFirstStringLocksLowButPlausiblePitch() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendManualPluck([
            (frequency: 400.0, confidence: 0.86, rms: 0.14, activity: 0.7),
            (frequency: 402.0, confidence: 0.88, rms: 0.16, activity: 0.6)
        ], to: viewModel)

        assertManualLock(
            on: viewModel,
            frequencyText: "401.0 Hz",
            directionText: "偏高，稍微放松",
            centsSign: .plus
        )
    }

    @MainActor
    func testSelectedThirdStringKeepsNonHarmonicHighRawPitchFeedback() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .third

        sendManualPluck([
            (frequency: 230.0, confidence: 0.88, rms: 0.14, activity: 0.7),
            (frequency: 232.0, confidence: 0.90, rms: 0.16, activity: 0.6)
        ], to: viewModel)

        assertManualLock(
            on: viewModel,
            frequencyText: "231.0 Hz",
            directionText: "偏高，稍微放松",
            centsSign: .plus
        )
        XCTAssertEqual(viewModel.microphoneStatusText, "正在监听")
    }

    @MainActor
    func testFourthStringKeepsNonHarmonicHighRawPitchFeedback() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendManualPluck([
            (frequency: 180.0, confidence: 0.90, rms: 0.16, activity: 0.7),
            (frequency: 181.0, confidence: 0.88, rms: 0.14, activity: 0.6)
        ], to: viewModel)

        assertManualLock(
            on: viewModel,
            frequencyText: "180.5 Hz",
            directionText: "偏高，稍微放松",
            centsSign: .plus
        )
    }

    @MainActor
    func testManualModePrefersValidRawFourthStringOverWrongAssistedCandidate() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendRawFrame(frequency: 114.0, confidence: 0.88, rms: 0.14, activity: 0.7, assistedFrequency: 190.0, assistedConfidence: 0.91, assistedRMS: 0.14, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.activeString, .fourth)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 114.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 114.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.detectedFrequencyText, "114.0 Hz")
    }

    @MainActor
    func testManualModePrefersValidRawFirstStringOverWrongAssistedCandidate() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendRawFrame(frequency: 220.0, confidence: 0.92, rms: 0.16, activity: 0.7, assistedFrequency: 293.0, assistedConfidence: 0.93, assistedRMS: 0.16, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.activeString, .first)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 220.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 220.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.detectedFrequencyText, "220.0 Hz")
    }

    @MainActor
    func testManualModeKeepsVeryLowFourthStringRawInsteadOfDoubling() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendRawFrame(frequency: 65.0, confidence: 0.58, rms: 0.08, activity: 0.7, assistedFrequency: 130.0, assistedConfidence: 0.72, assistedRMS: 0.08, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.activeString, .fourth)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 65.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 65.0, accuracy: 0.1)
        XCTAssertLessThan(viewModel.centsOffset ?? 0, 0)
        XCTAssertEqual(viewModel.directionText, "明显偏低，先拧紧")
    }

    @MainActor
    func testManualModeKeepsVeryLowFirstStringRawInsteadOfDoubling() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendRawFrame(frequency: 135.0, confidence: 0.62, rms: 0.09, activity: 0.7, assistedFrequency: 270.0, assistedConfidence: 0.74, assistedRMS: 0.09, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.activeString, .first)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 135.0, accuracy: 0.1)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 135.0, accuracy: 0.1)
        XCTAssertLessThan(viewModel.centsOffset ?? 0, 0)
        XCTAssertEqual(viewModel.directionText, "明显偏低，先拧紧")
    }

    @MainActor
    func testManualModeRejectsVeryHighThirdStringHarmonic() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .third

        sendManualPluck([
            (frequency: 700.0, confidence: 0.90, rms: 0.16, activity: 0.7),
            (frequency: 705.0, confidence: 0.88, rms: 0.14, activity: 0.6)
        ], to: viewModel)

        XCTAssertEqual(viewModel.activeString, .third)
        XCTAssertEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertNil(viewModel.diagnostics.acceptedFrequency)
        XCTAssertNil(viewModel.diagnostics.lockedFrequency)
    }

    @MainActor
    func testManualModeRejectsVeryHighFourthStringHarmonic() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendManualPluck([
            (frequency: 700.0, confidence: 0.90, rms: 0.16, activity: 0.7),
            (frequency: 705.0, confidence: 0.88, rms: 0.14, activity: 0.6)
        ], to: viewModel)

        XCTAssertEqual(viewModel.activeString, .fourth)
        XCTAssertEqual(viewModel.detectedFrequencyText, "--")
        XCTAssertNil(viewModel.diagnostics.acceptedFrequency)
        XCTAssertNil(viewModel.diagnostics.lockedFrequency)
    }

    @MainActor
    func testVeryLowFourthStringShowsTightenGuidance() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendManualPluck([
            (frequency: 80.0, confidence: 0.42, rms: 0.04, activity: 0.42),
            (frequency: 81.0, confidence: 0.40, rms: 0.04, activity: 0.38)
        ], to: viewModel)

        assertManualLock(
            on: viewModel,
            frequencyText: "80.5 Hz",
            directionText: "明显偏低，先拧紧",
            centsSign: .minus
        )
    }

    @MainActor
    func testSilentAudioFrameKeepsLastReadoutAndDropsActivity() {
        let viewModel = TunerViewModel()
        sendDetectedFrame(frequency: 438.0, confidence: 0.92, rms: 0.2, activity: 0.7, to: viewModel)

        finishPluck(on: viewModel)
        let detectedFrequencyText = viewModel.detectedFrequencyText
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.inputActivityLevel, 0, accuracy: 0.001)
        XCTAssertEqual(viewModel.recognitionStatusText, "拨弦后显示结果")
        XCTAssertEqual(viewModel.detectedFrequencyText, detectedFrequencyText)
    }
}
