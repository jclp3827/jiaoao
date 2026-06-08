import XCTest
@testable import PipaTuner

extension PipaTunerTests {
    @MainActor
    func testAutoModeClassifiesStringFromRawDetection() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto
        viewModel.selectedString = .fourth

        sendAutoPluck([
            (frequency: 440.0, confidence: 0.93, rms: 0.16, activity: 0.7),
            (frequency: 439.5, confidence: 0.92, rms: 0.15, activity: 0.65)
        ], to: viewModel)

        XCTAssertEqual(viewModel.selectedString, .fourth)
        assertAutoLock(on: viewModel, string: .first, frequency: 220.0, accuracy: 0.5)
        XCTAssertTrue(viewModel.diagnostics.autoCandidateSummary.first?.contains("一弦") == true)
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.first.targetDisplayText)
    }

    @MainActor
    func testAutoModeKeepsDetectedStringVisibleAfterLock() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 146.8, confidence: 0.92, rms: 0.16, activity: 0.7),
            (frequency: 147.0, confidence: 0.90, rms: 0.15, activity: 0.65)
        ], to: viewModel)

        XCTAssertEqual(viewModel.diagnostics.autoDetectedStringName, "三弦")

        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.diagnostics.autoDetectedStringName, "三弦")
    }

    @MainActor
    func testAutoModeKeepsFourthStringNearFundamentalInsteadOfJumpingToFirst() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 108.0, confidence: 0.43, rms: 0.11, activity: 0.7),
            (frequency: 108.5, confidence: 0.41, rms: 0.10, activity: 0.65)
        ], to: viewModel)

        XCTAssertEqual(viewModel.selectedString, .first)
        assertAutoLock(on: viewModel, string: .fourth, frequency: 108.3, accuracy: 1.0)
        XCTAssertTrue(viewModel.diagnostics.autoCandidateSummary.first?.contains("四弦") == true)
        XCTAssertEqual(viewModel.autoStatusText, "四弦")
        XCTAssertEqual(viewModel.diagnostics.lastLockedSnapshot?.autoDetectedStringName, "四弦")
    }

    @MainActor
    func testAutoModeKeepsManualSelectionButSwitchesActiveTargetString() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .second
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 220.0, confidence: 0.94, rms: 0.18, activity: 0.72),
            (frequency: 219.6, confidence: 0.92, rms: 0.16, activity: 0.66)
        ], to: viewModel)

        XCTAssertEqual(viewModel.selectedString, .second)
        XCTAssertEqual(viewModel.activeString, .first)
        XCTAssertEqual(viewModel.targetFrequencyText, PipaString.first.targetDisplayText)
        XCTAssertEqual(viewModel.diagnostics.selectedStringName, PipaString.first.shortName)
    }

    @MainActor
    func testAutoModeKeepsLooseFourthStringFromJumpingToSecondString() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 80.0, confidence: 0.42, rms: 0.04, activity: 0.42),
            (frequency: 81.0, confidence: 0.40, rms: 0.04, activity: 0.38)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .fourth, frequency: 80.5, accuracy: 1.0)
        XCTAssertLessThan(viewModel.centsOffset ?? 0, 0)
    }

    @MainActor
    func testAutoModeUsesSelectedThirdStringAsWeakPriorForVeryLowPitch() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .third
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 80.0, confidence: 0.42, rms: 0.04, activity: 0.42),
            (frequency: 81.0, confidence: 0.40, rms: 0.04, activity: 0.38)
        ], to: viewModel)

        XCTAssertEqual(viewModel.selectedString, .third)
        assertAutoLock(on: viewModel, string: .fourth, frequency: 80.5, accuracy: 1.0)
    }

    @MainActor
    func testAutoModeRecapturesFourthStringAfterPreviouslyCapturedThirdString() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7),
            (frequency: 143.2, confidence: 0.91, rms: 0.12, activity: 0.7),
            (frequency: 116.0, confidence: 0.90, rms: 0.13, activity: 0.7),
            (frequency: 116.2, confidence: 0.91, rms: 0.13, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .fourth, frequency: 116.1, accuracy: 1.0)
    }

    @MainActor
    func testAutoModeCapturesNewFourthStringAfterPreviousThirdStringPluckLocked() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7)
        ], to: viewModel)
        XCTAssertEqual(viewModel.activeString, .third)

        sendAutoPluck([
            (frequency: 116.0, confidence: 0.90, rms: 0.13, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .fourth, frequency: 116.0, accuracy: 0.1)
    }

    @MainActor
    func testAutoModeRecapturesFirstStringInsteadOfFoldingToPreviousThirdString() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7),
            (frequency: 143.2, confidence: 0.91, rms: 0.12, activity: 0.7),
            (frequency: 220.0, confidence: 0.92, rms: 0.15, activity: 0.7),
            (frequency: 220.2, confidence: 0.93, rms: 0.15, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .first, frequency: 220.1, accuracy: 1.0)
    }

    @MainActor
    func testAutoModeCapturesNewFirstStringAfterPreviousThirdStringPluckLocked() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7)
        ], to: viewModel)
        XCTAssertEqual(viewModel.activeString, .third)

        sendAutoPluck([
            (frequency: 220.0, confidence: 0.92, rms: 0.15, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .first, frequency: 220.0, accuracy: 0.1)
    }

    @MainActor
    func testAutoModeRecapturesThirdStringInsteadOfFoldingToPreviousFirstString() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 220.0, confidence: 0.92, rms: 0.15, activity: 0.7),
            (frequency: 220.2, confidence: 0.93, rms: 0.15, activity: 0.7),
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7),
            (frequency: 143.2, confidence: 0.91, rms: 0.12, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .third, frequency: 143.1, accuracy: 1.0)
    }

    @MainActor
    func testAutoModeCapturesNewThirdStringAfterPreviousFirstStringPluckLocked() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 220.0, confidence: 0.92, rms: 0.15, activity: 0.7)
        ], to: viewModel)
        XCTAssertEqual(viewModel.activeString, .first)

        sendAutoPluck([
            (frequency: 143.0, confidence: 0.90, rms: 0.12, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .third, frequency: 143.0, accuracy: 0.1)
    }

    @MainActor
    func testAutoModeKeepsVeryLowFourthStringRawInsteadOfDoubling() {
        let viewModel = TunerViewModel()
        viewModel.tuningMode = .auto

        sendAutoPluck([
            (frequency: 65.0, confidence: 0.58, rms: 0.08, activity: 0.7),
            (frequency: 65.5, confidence: 0.60, rms: 0.08, activity: 0.7)
        ], to: viewModel)

        assertAutoLock(on: viewModel, string: .fourth, frequency: 65.25, accuracy: 0.5)
        XCTAssertLessThan(viewModel.centsOffset ?? 0, 0)
    }
}
