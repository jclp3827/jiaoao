import XCTest
@testable import PipaTuner

extension PipaTunerTests {
    func testStringTargetsMatchReferenceTuning() {
        XCTAssertEqual(PipaString.fourth.targetFrequency, 110.0, accuracy: 0.001)
        XCTAssertEqual(PipaString.third.targetFrequency, 146.8, accuracy: 0.001)
        XCTAssertEqual(PipaString.second.targetFrequency, 164.8, accuracy: 0.001)
        XCTAssertEqual(PipaString.first.targetFrequency, 220.0, accuracy: 0.001)
    }

    func testStringLabelsMatchReferenceTuning() {
        XCTAssertEqual(PipaString.fourth.displayPitchName, "大 A")
        XCTAssertEqual(PipaString.fourth.roleName, "缠弦")
        XCTAssertEqual(PipaString.fourth.scientificNoteName, "A2")
        XCTAssertEqual(PipaString.third.displayPitchName, "d")
        XCTAssertEqual(PipaString.third.roleName, "老弦")
        XCTAssertEqual(PipaString.third.scientificNoteName, "D3")
        XCTAssertEqual(PipaString.second.displayPitchName, "e")
        XCTAssertEqual(PipaString.second.roleName, "中弦")
        XCTAssertEqual(PipaString.second.scientificNoteName, "E3")
        XCTAssertEqual(PipaString.first.displayPitchName, "a")
        XCTAssertEqual(PipaString.first.roleName, "子弦")
        XCTAssertEqual(PipaString.first.scientificNoteName, "A3")
    }

    func testTuningOrderMatchesNaturalStringOrder() {
        XCTAssertEqual(PipaString.tuningOrder, [.first, .second, .third, .fourth])
    }

    func testTargetDisplayTextMatchesTable() {
        XCTAssertEqual(PipaString.fourth.targetDisplayText, "大 A · 110 Hz · 倍低音 5")
        XCTAssertEqual(PipaString.third.targetDisplayText, "d · 146.8 Hz · 低音 1")
        XCTAssertEqual(PipaString.second.targetDisplayText, "e · 164.8 Hz · 低音 2")
        XCTAssertEqual(PipaString.first.targetDisplayText, "a · 220 Hz · 低音 5")
    }

    func testPrimaryAutoBandPrefersFourthStringForLowRawFrequency() {
        XCTAssertEqual(PipaString.primaryAutoBandString(for: 80.0), .fourth)
        XCTAssertEqual(PipaString.primaryAutoBandString(for: 108.0), .fourth)
        XCTAssertEqual(PipaString.primaryAutoBandString(for: 146.8), .third)
        XCTAssertEqual(PipaString.primaryAutoBandString(for: 164.8), .second)
        XCTAssertEqual(PipaString.primaryAutoBandString(for: 220.0), .first)
        XCTAssertNil(PipaString.primaryAutoBandString(for: 440.0))
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

    func testTuningReadoutPresenterShowsLowFrequencyGuidance() {
        let presenter = TuningReadoutPresenter()
        let result = TuningGuide.evaluate(
            detectedFrequency: 80.0,
            targetFrequency: PipaString.fourth.targetFrequency,
            confidence: 0.42
        )

        let readout = presenter.readout(for: result, string: .fourth)

        XCTAssertEqual(readout.detectedFrequencyText, "80.0 Hz")
        XCTAssertEqual(readout.directionText, "明显偏低，继续上紧")
        XCTAssertEqual(readout.statusColorName, "orange")
    }

    func testTuningReadoutPresenterKeepsNormalFlatGuidanceNearTarget() {
        let presenter = TuningReadoutPresenter()
        let result = TuningGuide.evaluate(
            detectedFrequency: 100.0,
            targetFrequency: PipaString.fourth.targetFrequency,
            confidence: 0.72
        )

        let readout = presenter.readout(for: result, string: .fourth)

        XCTAssertEqual(readout.directionText, "偏低，往上拧一点")
    }
}
