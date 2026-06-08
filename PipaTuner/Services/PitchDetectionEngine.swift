import AVFoundation
import Foundation

struct PitchDetectionResult: Equatable {
    let frequency: Double
    let confidence: Double
    let rms: Double
}

enum PitchAnalysisReason: String, Equatable {
    case success
    case missingInput
    case emptyBuffer
    case silence
    case frameTooShort
    case noCandidate
    case lowConfidence
}

struct PitchAnalysisResult {
    let detection: PitchDetectionResult?
    let reason: PitchAnalysisReason
    let rms: Double?
}

final class PitchDetectionEngine {
    func detectPitch(from buffer: AVAudioPCMBuffer, targetFrequency: Double? = nil) -> PitchDetectionResult? {
        analyzePitch(from: buffer, targetFrequency: targetFrequency).detection
    }

    func analyzePitch(from buffer: AVAudioPCMBuffer, targetFrequency: Double? = nil) -> PitchAnalysisResult {
        guard let channelData = buffer.floatChannelData else {
            return PitchAnalysisResult(detection: nil, reason: .missingInput, rms: nil)
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return PitchAnalysisResult(detection: nil, reason: .emptyBuffer, rms: nil)
        }

        let channelCount = Int(buffer.format.channelCount)
        let samples = mixDownSamples(channelData: channelData, frameLength: frameLength, channelCount: channelCount)
        return analyzePitch(from: samples, sampleRate: buffer.format.sampleRate, targetFrequency: targetFrequency)
    }

    func detectPitch(from samples: [Float], sampleRate: Double, targetFrequency: Double? = nil) -> PitchDetectionResult? {
        analyzePitch(from: samples, sampleRate: sampleRate, targetFrequency: targetFrequency).detection
    }

    func analyzePitch(from samples: [Float], sampleRate: Double, targetFrequency: Double? = nil) -> PitchAnalysisResult {
        guard !samples.isEmpty else {
            return PitchAnalysisResult(detection: nil, reason: .emptyBuffer, rms: nil)
        }

        let rms = rootMeanSquare(samples)
        guard rms >= TunerConfiguration.PitchDetection.silenceRMS else {
            return PitchAnalysisResult(detection: nil, reason: .silence, rms: rms)
        }

        let centered = center(samples)

        let minLag = max(2, Int(sampleRate / TunerConfiguration.PitchDetection.maximumFrequency))
        let maxLag = max(minLag + 1, Int(sampleRate / TunerConfiguration.PitchDetection.minimumFrequency))

        let pitch = yinPitch(samples: centered, sampleRate: sampleRate, minLag: minLag, maxLag: maxLag, targetFrequency: targetFrequency)
        guard let pitch else {
            return PitchAnalysisResult(detection: nil, reason: .noCandidate, rms: rms)
        }

        switch pitch {
        case .success(let frequency, let confidence):
            return PitchAnalysisResult(
                detection: PitchDetectionResult(frequency: frequency, confidence: confidence, rms: rms),
                reason: .success,
                rms: rms
            )
        case .failure(let reason):
            return PitchAnalysisResult(detection: nil, reason: reason, rms: rms)
        }
    }

    func detectPitch(from samples: [Float], sampleRate: Double) -> PitchDetectionResult? {
        detectPitch(from: samples, sampleRate: sampleRate, targetFrequency: nil)
    }

    private func yinPitch(
        samples: [Double],
        sampleRate: Double,
        minLag: Int,
        maxLag: Int,
        targetFrequency: Double?
    ) -> YinPitchResult? {
        guard samples.count > maxLag else {
            return .failure(.frameTooShort)
        }

        var difference = Array(repeating: 0.0, count: maxLag + 1)

        for lag in 1...maxLag {
            let limit = samples.count - lag
            var sum = 0.0

            for index in 0..<limit {
                let delta = samples[index] - samples[index + lag]
                sum += delta * delta
            }

            difference[lag] = sum
        }

        var cumulativeMeanNormalized = Array(repeating: 1.0, count: maxLag + 1)
        var runningSum = 0.0

        for lag in 1...maxLag {
            runningSum += difference[lag]
            cumulativeMeanNormalized[lag] = runningSum > 0 ? difference[lag] * Double(lag) / runningSum : 1.0
        }

        if targetFrequency == nil {
            let threshold = TunerConfiguration.PitchDetection.yinThreshold
            var selectedLag: Int?

            for lag in minLag...maxLag {
                guard cumulativeMeanNormalized[lag] < threshold else {
                    continue
                }

                var localMinimumLag = lag
                while localMinimumLag + 1 <= maxLag && cumulativeMeanNormalized[localMinimumLag + 1] < cumulativeMeanNormalized[localMinimumLag] {
                    localMinimumLag += 1
                }

                selectedLag = localMinimumLag
                break
            }

            if selectedLag == nil {
                selectedLag = (minLag...maxLag).min(by: { cumulativeMeanNormalized[$0] < cumulativeMeanNormalized[$1] })
            }

            guard let selectedLag else {
                return nil
            }

            let refinedLag = parabolicRefinement(values: cumulativeMeanNormalized, bestLag: selectedLag)
            guard refinedLag > 0 else {
                return .failure(.noCandidate)
            }

            let confidence = max(0, min(1, 1.0 - cumulativeMeanNormalized[selectedLag]))
            guard confidence > TunerConfiguration.PitchDetection.minimumConfidence else {
                return .failure(.lowConfidence)
            }

            return .success(frequency: sampleRate / refinedLag, confidence: confidence)
        }

        let candidates = pitchCandidates(
            from: cumulativeMeanNormalized,
            sampleRate: sampleRate,
            minLag: minLag,
            maxLag: maxLag,
            targetFrequency: targetFrequency
        )

        guard let selectedPitch = candidates.first else {
            return .failure(.noCandidate)
        }

        guard selectedPitch.confidence > TunerConfiguration.PitchDetection.minimumConfidence else {
            return .failure(.lowConfidence)
        }

        return .success(frequency: selectedPitch.frequency, confidence: selectedPitch.confidence)
    }

    private enum YinPitchResult {
        case success(frequency: Double, confidence: Double)
        case failure(PitchAnalysisReason)
    }

    private func pitchCandidates(
        from cumulativeMeanNormalized: [Double],
        sampleRate: Double,
        minLag: Int,
        maxLag: Int,
        targetFrequency: Double?
    ) -> [(frequency: Double, confidence: Double)] {
        var localMinima: [(lag: Int, value: Double)] = []
        let threshold = TunerConfiguration.PitchDetection.candidateThreshold

        for lag in minLag...maxLag {
            let value = cumulativeMeanNormalized[lag]
            guard value <= threshold else {
                continue
            }

            let previous = lag > minLag ? cumulativeMeanNormalized[lag - 1] : 1.0
            let next = lag < maxLag ? cumulativeMeanNormalized[lag + 1] : 1.0
            guard value <= previous && value <= next else {
                continue
            }

            localMinima.append((lag, value))
        }

        if localMinima.isEmpty, let bestLag = (minLag...maxLag).min(by: { cumulativeMeanNormalized[$0] < cumulativeMeanNormalized[$1] }) {
            localMinima.append((bestLag, cumulativeMeanNormalized[bestLag]))
        }

        let candidates = localMinima.compactMap { minimum -> (frequency: Double, confidence: Double, lag: Int, value: Double)? in
            let refinedLag = parabolicRefinement(values: cumulativeMeanNormalized, bestLag: minimum.lag)
            guard refinedLag > 0 else {
                return nil
            }

            let frequency = sampleRate / refinedLag
            guard frequency >= TunerConfiguration.PitchDetection.minimumFrequency && frequency <= TunerConfiguration.PitchDetection.maximumFrequency else {
                return nil
            }

            let confidence = max(0, min(1, 1.0 - minimum.value))
            return (frequency, confidence, minimum.lag, minimum.value)
        }

        guard let targetFrequency else {
            return candidates
                .sorted { lhs, rhs in
                    if abs(lhs.value - rhs.value) > 0.04 {
                        return lhs.value < rhs.value
                    }
                    return lhs.frequency < rhs.frequency
                }
                .map { ($0.frequency, $0.confidence) }
        }

        let scoredCandidates = candidates.compactMap { candidate -> (frequency: Double, confidence: Double, score: Double)? in
            let rawFrequency = candidate.frequency
            guard let normalized = PitchNormalization.bestCandidate(
                from: rawFrequency,
                targetFrequency: targetFrequency
            ) else {
                return nil
            }

            let yinPenalty = candidate.value * TunerConfiguration.Harmonics.yinPenaltyScale
            let score = normalized.score + yinPenalty
            return (normalized.frequency, candidate.confidence, score)
        }

        if !scoredCandidates.isEmpty {
            return scoredCandidates
                .sorted { $0.score < $1.score }
                .map { ($0.frequency, $0.confidence) }
        }

        return candidates
            .sorted { $0.value < $1.value }
            .map { ($0.frequency, $0.confidence) }
    }
    private func mixDownSamples(channelData: UnsafePointer<UnsafeMutablePointer<Float>>, frameLength: Int, channelCount: Int) -> [Float] {
        guard channelCount > 0 else {
            return []
        }

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        }

        var output: [Float] = []
        output.reserveCapacity(frameLength)

        for index in 0..<frameLength {
            var sum: Float = 0
            for channel in 0..<channelCount {
                sum += channelData[channel][index]
            }
            output.append(sum / Float(channelCount))
        }

        return output
    }

    private func rootMeanSquare(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else {
            return 0
        }

        let sumSquares = samples.reduce(0.0) { partialResult, sample in
            partialResult + Double(sample * sample)
        }
        return sqrt(sumSquares / Double(samples.count))
    }

    private func center(_ samples: [Float]) -> [Double] {
        guard !samples.isEmpty else {
            return []
        }

        let mean = samples.reduce(0.0) { $0 + Double($1) } / Double(samples.count)
        return samples.map { Double($0) - mean }
    }

    private func parabolicRefinement(values: [Double], bestLag: Int) -> Double {
        let leftIndex = bestLag - 1
        let rightIndex = bestLag + 1

        guard values.indices.contains(leftIndex), values.indices.contains(bestLag), values.indices.contains(rightIndex) else {
            return Double(bestLag)
        }

        let left = values[leftIndex]
        let center = values[bestLag]
        let right = values[rightIndex]
        let denominator = left - 2.0 * center + right

        guard abs(denominator) > 0.000001 else {
            return Double(bestLag)
        }

        let shift = 0.5 * (left - right) / denominator
        return Double(bestLag) + shift
    }
}
