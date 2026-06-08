import AVFoundation
import Foundation

final class AudioRecorder: @unchecked Sendable {
    var onAudioFrame: ((AudioAnalysisFrame) -> Void)?

    private let engine = AVAudioEngine()
    private let detector = PitchDetectionEngine()
    private var isRunning = false
    private var hasInstalledTap = false

    var targetFrequency: Double?

    deinit {
        stop()
    }

    func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }

    func start() throws {
        guard !isRunning else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers])
            try session.setPreferredSampleRate(TunerConfiguration.AudioInput.preferredSampleRate)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            configurePreferredMicrophone(for: session)

            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
            inputNode.installTap(onBus: 0, bufferSize: TunerConfiguration.AudioInput.tapBufferSize, format: inputFormat) { [weak self] buffer, _ in
                guard let self else { return }

                let activityLevel = activityLevel(from: buffer)
                let rawAnalysis = self.detector.analyzePitch(from: buffer)
                let assistedAnalysis = targetFrequency.map {
                    self.detector.analyzePitch(from: buffer, targetFrequency: $0)
                }

                onAudioFrame?(AudioAnalysisFrame(
                    rawDetection: rawAnalysis.detection,
                    assistedDetection: assistedAnalysis?.detection,
                    activityLevel: activityLevel,
                    rawAnalysisReason: rawAnalysis.reason,
                    assistedAnalysisReason: assistedAnalysis?.reason
                ))
            }
            hasInstalledTap = true

            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            cleanupAudioEngine()
            throw error
        }
    }

    func stop() {
        cleanupAudioEngine()
    }

    private func cleanupAudioEngine() {
        if hasInstalledTap {
            engine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        if isRunning {
            engine.stop()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        isRunning = false
    }

    private func configurePreferredMicrophone(for session: AVAudioSession) {
        guard let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) else {
            return
        }

        try? session.setPreferredInput(builtInMic)

        let selectedDataSource = builtInMic.selectedDataSource
        let availableDataSources = builtInMic.dataSources ?? []
        let candidateDataSources = ([selectedDataSource].compactMap { $0 } + availableDataSources)
            .uniquedByDataSourceID()

        guard let omniDataSource = candidateDataSources.first(where: {
            $0.supportedPolarPatterns?.contains(.omnidirectional) == true
        }) else {
            return
        }

        if builtInMic.selectedDataSource?.dataSourceID != omniDataSource.dataSourceID {
            try? builtInMic.setPreferredDataSource(omniDataSource)
        }
        try? omniDataSource.setPreferredPolarPattern(.omnidirectional)
        try? session.setPreferredInput(builtInMic)
    }

    private func activityLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0
        }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameLength > 0, channelCount > 0 else {
            return 0
        }

        var sumSquares = 0.0
        var peak = 0.0
        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sample = Double(channelData[channel][frame])
                sumSquares += sample * sample
                peak = max(peak, abs(sample))
            }
        }

        let rms = sqrt(sumSquares / Double(frameLength * channelCount))
        let rmsNormalized = min(1.0, rms / TunerConfiguration.AudioInput.activityNormalizationLevel)
        let boostedRMS = pow(rmsNormalized, 0.72)
        let peakNormalized = min(1.0, peak / TunerConfiguration.AudioInput.peakNormalizationLevel)
        return min(1.0, max(boostedRMS, peakNormalized * 0.82))
    }
}

private extension Array where Element == AVAudioSessionDataSourceDescription {
    func uniquedByDataSourceID() -> [AVAudioSessionDataSourceDescription] {
        var seenIDs: Set<NSNumber> = []
        return filter { dataSource in
            seenIDs.insert(dataSource.dataSourceID).inserted
        }
    }
}
