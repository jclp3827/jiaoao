import AVFoundation
import Foundation

struct PitchDetectionResult {
    let frequency: Double
    let confidence: Double
    let rms: Double
}

final class PitchDetectionEngine {
    private let minimumFrequency: Double = 60.0
    private let maximumFrequency: Double = 600.0
    private let silenceThreshold: Double = 0.01

    func detectPitch(from buffer: AVAudioPCMBuffer) -> PitchDetectionResult? {
        guard let channelData = buffer.floatChannelData else {
            return nil
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return nil
        }

        let channelCount = Int(buffer.format.channelCount)
        let samples = mixDownSamples(channelData: channelData, frameLength: frameLength, channelCount: channelCount)
        return detectPitch(from: samples, sampleRate: buffer.format.sampleRate)
    }

    func detectPitch(from samples: [Float], sampleRate: Double) -> PitchDetectionResult? {
        guard !samples.isEmpty else {
            return nil
        }

        let rms = rootMeanSquare(samples)
        guard rms >= silenceThreshold else {
            return nil
        }

        let centered = center(samples)

        let minLag = max(2, Int(sampleRate / maximumFrequency))
        let maxLag = max(minLag + 1, Int(sampleRate / minimumFrequency))

        guard let pitch = yinPitch(samples: centered, sampleRate: sampleRate, minLag: minLag, maxLag: maxLag) else {
            return nil
        }

        return PitchDetectionResult(frequency: pitch.frequency, confidence: pitch.confidence, rms: rms)
    }

    private func yinPitch(samples: [Double], sampleRate: Double, minLag: Int, maxLag: Int) -> (frequency: Double, confidence: Double)? {
        guard samples.count > maxLag else {
            return nil
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

        let threshold = 0.16
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
            return nil
        }

        let confidence = max(0, min(1, 1.0 - cumulativeMeanNormalized[selectedLag]))
        guard confidence > 0.2 else {
            return nil
        }

        return (sampleRate / refinedLag, confidence)
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

    private func applyHannWindow(_ samples: [Double]) -> [Double] {
        guard samples.count > 1 else {
            return samples
        }

        let count = Double(samples.count - 1)
        return samples.enumerated().map { index, sample in
            let multiplier = 0.5 - 0.5 * cos((2.0 * Double.pi * Double(index)) / count)
            return sample * multiplier
        }
    }

    private func normalizedAutoCorrelation(_ samples: [Double], lag: Int) -> Double {
        guard samples.count > lag else {
            return 0
        }

        var correlation = 0.0
        var normalization = 0.0

        let limit = samples.count - lag
        for index in 0..<limit {
            let a = samples[index]
            let b = samples[index + lag]
            correlation += a * b
            normalization += a * a + b * b
        }

        guard normalization > 0 else {
            return 0
        }

        return (2.0 * correlation) / normalization
    }

    private func parabolicRefinement(correlations: [Double], bestLag: Int, minLag: Int) -> Double {
        let bestIndex = bestLag - minLag
        guard correlations.indices.contains(bestIndex) else {
            return Double(bestLag)
        }

        let leftIndex = bestIndex - 1
        let rightIndex = bestIndex + 1

        guard correlations.indices.contains(leftIndex), correlations.indices.contains(rightIndex) else {
            return Double(bestLag)
        }

        let left = correlations[leftIndex]
        let center = correlations[bestIndex]
        let right = correlations[rightIndex]
        let denominator = left - 2.0 * center + right

        guard abs(denominator) > 0.000001 else {
            return Double(bestLag)
        }

        let shift = 0.5 * (left - right) / denominator
        return Double(bestLag) + shift
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
