import XCTest
@testable import PipaTuner

extension PipaTunerTests {
    func testAutoStringClassifierPrefersFourthStringForLowRawFrequency() {
        let classifier = AutoStringClassifier()
        let classification = classifier.classify(
            detection: PitchDetectionResult(frequency: 108.0, confidence: 0.43, rms: 0.11),
            fallbackString: .first
        )

        XCTAssertEqual(classification.bestCandidate.string, .fourth)
        XCTAssertTrue(classification.rankedCandidates.first?.string == .fourth)
    }

    func testAutoStringClassifierKeepsLooseFourthStringAtRawLowFrequency() {
        let classifier = AutoStringClassifier()
        let classification = classifier.classify(
            detection: PitchDetectionResult(frequency: 80.0, confidence: 0.42, rms: 0.04),
            fallbackString: .first
        )

        XCTAssertEqual(classification.bestCandidate.string, .fourth)
        XCTAssertEqual(classification.bestCandidate.normalizedFrequency, 80.0, accuracy: 0.5)
        XCTAssertFalse(classification.rankedCandidates.first?.string == .second)
    }

    func testPitchNormalizationDoesNotDoubleVeryLowFourthString() {
        let candidate = PitchNormalization.bestCandidate(
            from: 65.0,
            targetFrequency: PipaString.fourth.targetFrequency
        )

        XCTAssertEqual(candidate?.frequency ?? 0, 65.0, accuracy: 0.1)
        XCTAssertEqual(candidate?.multiplier ?? 0, 1.0, accuracy: 0.001)
        XCTAssertLessThan(candidate?.cents ?? 0, 0)
    }

    func testPitchNormalizationDoesNotDoubleVeryLowFirstString() {
        let candidate = PitchNormalization.bestCandidate(
            from: 135.0,
            targetFrequency: PipaString.first.targetFrequency
        )

        XCTAssertEqual(candidate?.frequency ?? 0, 135.0, accuracy: 0.1)
        XCTAssertEqual(candidate?.multiplier ?? 0, 1.0, accuracy: 0.001)
        XCTAssertLessThan(candidate?.cents ?? 0, 0)
    }

    func testAutoStringClassifierUsesSelectedStringAsWeakPriorForVeryLowThirdString() {
        let classifier = AutoStringClassifier()
        let classification = classifier.classify(
            detection: PitchDetectionResult(frequency: 80.0, confidence: 0.42, rms: 0.04),
            fallbackString: .third,
            preferredString: .third
        )

        XCTAssertEqual(classification.bestCandidate.string, .fourth)
        XCTAssertEqual(classification.bestCandidate.normalizedFrequency, 80.0, accuracy: 0.5)
    }

    func testAutoStringClassifierClassifiesStrongAAsFirstString() {
        let classifier = AutoStringClassifier()
        let classification = classifier.classify(
            detection: PitchDetectionResult(frequency: 440.0, confidence: 0.93, rms: 0.16),
            fallbackString: .fourth
        )

        XCTAssertEqual(classification.bestCandidate.string, .first)
        XCTAssertEqual(classification.bestCandidate.normalizedFrequency, 220.0, accuracy: 0.5)
    }

    func testTuningFrameProcessorKeepsManualRawFrequency() {
        let processor = TuningFrameProcessor()
        let detection = PitchDetectionResult(frequency: 400.0, confidence: 0.91, rms: 0.16)

        let result = processor.process(detection, for: .first, mode: .manual)

        XCTAssertEqual(
            result,
            .accepted(TuningFrameAcceptedDetection(detection: detection, source: .raw))
        )
    }

    func testTuningFrameProcessorRejectsManualHighHarmonic() {
        let processor = TuningFrameProcessor()
        let detection = PitchDetectionResult(frequency: 700.0, confidence: 0.91, rms: 0.16)

        let result = processor.process(detection, for: .fourth, mode: .manual)

        XCTAssertEqual(result, .rejected(.manualHighHarmonic(700.0)))
    }

    func testTuningFrameProcessorNormalizesAutoDetection() {
        let processor = TuningFrameProcessor()
        let detection = PitchDetectionResult(frequency: 440.0, confidence: 0.93, rms: 0.16)

        let result = processor.process(detection, for: .first, mode: .auto)

        XCTAssertEqual(
            result,
            .accepted(TuningFrameAcceptedDetection(
                detection: PitchDetectionResult(frequency: 220.0, confidence: 0.93, rms: 0.16),
                source: .normalized
            ))
        )
    }

    func testAutoTargetResolverAcceptsDecisiveInitialCandidate() {
        let resolver = AutoTargetResolver()
        let classification = makeAutoClassification(
            bestString: .fourth,
            primaryBandString: .fourth,
            bestScore: 10,
            secondScore: 220,
            rawCentsDistance: 40
        )

        let resolution = resolver.resolve(classification: classification, capturedString: nil)

        XCTAssertEqual(resolution, .decisiveInitial(.fourth))
    }

    func testAutoTargetResolverRequiresStableInitialCandidateWhenNotDecisive() {
        let resolver = AutoTargetResolver()
        let classification = makeAutoClassification(
            bestString: .fourth,
            primaryBandString: .third,
            bestScore: 10,
            secondScore: 60,
            rawCentsDistance: 500
        )

        let resolution = resolver.resolve(classification: classification, capturedString: nil)

        XCTAssertEqual(resolution, .needsStableInitial(.fourth))
    }

    func testAutoTargetResolverKeepsCapturedStringWhenRecaptureIsWeak() {
        let resolver = AutoTargetResolver()
        let classification = makeAutoClassification(
            bestString: .fourth,
            primaryBandString: .third,
            bestScore: 100,
            secondString: .third,
            secondScore: 180,
            rawCentsDistance: 500
        )

        let resolution = resolver.resolve(classification: classification, capturedString: .third)

        XCTAssertEqual(resolution, .keepCaptured(.third))
    }

    func testAutoTargetResolverRequiresStableRecaptureWhenCandidateIsStrongButNotDecisive() {
        let resolver = AutoTargetResolver()
        let classification = makeAutoClassification(
            bestString: .fourth,
            primaryBandString: .third,
            bestScore: 10,
            secondString: .third,
            secondScore: 220,
            rawCentsDistance: 500
        )

        let resolution = resolver.resolve(classification: classification, capturedString: .third)

        XCTAssertEqual(resolution, .needsStableRecapture(.fourth))
    }

    private func makeAutoClassification(
        bestString: PipaString,
        primaryBandString: PipaString?,
        bestScore: Double,
        secondString: PipaString = .first,
        secondScore: Double,
        rawCentsDistance: Double
    ) -> AutoStringClassification {
        let bestCandidate = AutoStringCandidate(
            string: bestString,
            normalizedFrequency: bestString.targetFrequency,
            confidence: 0.90,
            centsDistance: 5,
            rawCentsDistance: rawCentsDistance,
            normalizationPenalty: bestScore,
            classificationScore: bestScore
        )
        let secondCandidate = AutoStringCandidate(
            string: secondString,
            normalizedFrequency: secondString.targetFrequency,
            confidence: 0.80,
            centsDistance: 50,
            rawCentsDistance: 50,
            normalizationPenalty: secondScore,
            classificationScore: secondScore
        )

        return AutoStringClassification(
            bestCandidate: bestCandidate,
            rankedCandidates: [bestCandidate, secondCandidate],
            primaryBandString: primaryBandString
        )
    }

    func testPitchAnalysisMarksSilenceReason() {
        let engine = PitchDetectionEngine()
        let samples = Array(repeating: Float(0), count: testSampleCount)

        let result = engine.analyzePitch(from: samples, sampleRate: testSampleRate, targetFrequency: 440.0)

        XCTAssertNil(result.detection)
        XCTAssertEqual(result.reason, .silence)
    }

    func testPitchAnalysisDoesNotTreatQuietLowStringAsSilence() {
        let samples = sineSamples(frequency: 75.0, amplitude: 0.0034)

        let engine = PitchDetectionEngine()
        let result = engine.analyzePitch(from: samples, sampleRate: testSampleRate)

        XCTAssertNotEqual(result.reason, .silence)
        XCTAssertGreaterThan(result.rms ?? 0, TunerConfiguration.PitchDetection.silenceRMS)
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
        let frequency = 220.0
        let samples = harmonicSamples(
            frequency: frequency,
            components: [
                (multiple: 1.0, amplitude: 0.28),
                (multiple: 2.0, amplitude: 0.20)
            ]
        )

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: testSampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 2.0)
    }

    func testTargetAwarePitchDetectionFoldsStrongOctaveHarmonic() {
        let frequency = 440.0
        let samples = harmonicSamples(
            frequency: frequency,
            components: [
                (multiple: 1.0, amplitude: 0.05),
                (multiple: 2.0, amplitude: 0.34)
            ]
        )

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: testSampleRate, targetFrequency: frequency)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 3.0)
    }

    private func assertDetectedPitch(frequency: Double, file: StaticString = #filePath, line: UInt = #line) {
        let samples = sineSamples(frequency: frequency, amplitude: 0.35)

        let engine = PitchDetectionEngine()
        let result = engine.detectPitch(from: samples, sampleRate: testSampleRate)

        XCTAssertNotNil(result, file: file, line: line)
        XCTAssertEqual(result?.frequency ?? 0, frequency, accuracy: 2.0, file: file, line: line)
    }
}
