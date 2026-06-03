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
        XCTAssertEqual(PipaString.fourth.scientificNoteName, "A3")
        XCTAssertEqual(PipaString.third.displayPitchName, "d")
        XCTAssertEqual(PipaString.third.scientificNoteName, "D4")
        XCTAssertEqual(PipaString.second.displayPitchName, "e")
        XCTAssertEqual(PipaString.second.scientificNoteName, "E4")
        XCTAssertEqual(PipaString.first.displayPitchName, "a")
        XCTAssertEqual(PipaString.first.scientificNoteName, "A4")
    }

    func testTargetDisplayTextMatchesTable() {
        XCTAssertEqual(PipaString.fourth.targetDisplayText, "大 A · 220 Hz · 低音 5")
        XCTAssertEqual(PipaString.third.targetDisplayText, "d · 293.6 Hz · 中音 1")
        XCTAssertEqual(PipaString.second.targetDisplayText, "e · 329.6 Hz · 中音 2")
        XCTAssertEqual(PipaString.first.targetDisplayText, "a · 440 Hz · 中音 5")
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
        let sampleRate = 44_100.0
        let frequency = 220.0
        let sampleCount = 8192
        let samples = (0..<sampleCount).map { index -> Float in
            let t = Double(index) / sampleRate
            return Float(sin(2.0 * Double.pi * frequency * t) * 0.35)
        }

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 2.0)
    }
}
