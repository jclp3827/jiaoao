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
        let windowed = applyHannWindow(centered)

        let minLag = max(2, Int(sampleRate / maximumFrequency))
        let maxLag = max(minLag + 1, Int(sampleRate / minimumFrequency))

        var correlations: [Double] = []
        correlations.reserveCapacity(maxLag - minLag + 1)

        var bestLag = minLag
        var bestCorrelation = -Double.greatestFiniteMagnitude

        for lag in minLag...maxLag {
            let correlation = normalizedAutoCorrelation(windowed, lag: lag)
            correlations.append(correlation)

            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestCorrelation > 0.2 else {
            return nil
        }

        let refinedLag = parabolicRefinement(correlations: correlations, bestLag: bestLag, minLag: minLag)
        guard refinedLag > 0 else {
            return nil
        }

        let frequency = sampleRate / refinedLag
        return PitchDetectionResult(frequency: frequency, confidence: bestCorrelation, rms: rms)
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
}
