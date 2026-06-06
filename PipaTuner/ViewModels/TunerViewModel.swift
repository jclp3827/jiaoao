import AVFoundation
import Combine
import Foundation

@MainActor
final class TunerViewModel: ObservableObject {
    @Published var selectedString: PipaString = .first
    @Published var detectedFrequencyText: String = "--"
    @Published var targetFrequencyText: String = "440 Hz"
    @Published var centsText: String = "--"
    @Published var directionText: String = "点击开始，准备拾音"
    @Published var confidenceText: String = "0%"
    @Published var statusColorName: String = "secondary"
    @Published var isListening: Bool = false
    @Published var microphoneStatusText: String = "麦克风尚未启动"
    @Published var centsOffset: Double?
    @Published var inputActivityLevel: Double = 0
    @Published var recognitionStatusText: String = "未开始"

    private let recorder = AudioRecorder()
    private var cancellables: Set<AnyCancellable> = []
    private var lastDetectedFrequency: Double?
    private var lastConfidence: Double = 0
    private var bestCurrentPluckDetection: PitchDetectionResult?
    private var isCollectingPluck = false

    init() {
        recorder.onAudioFrame = { [weak self] frame in
            DispatchQueue.main.async {
                self?.handleAudioFrame(frame)
            }
        }

        $selectedString
            .dropFirst()
            .sink { [weak self] string in
                self?.recalculateLastResult(for: string)
            }
            .store(in: &cancellables)

        updateTargetLabels()
    }

    func startListening() {
        guard !isListening else {
            return
        }

        microphoneStatusText = "正在请求麦克风权限..."

        recorder.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }

                guard granted else {
                    self.isListening = false
                    self.microphoneStatusText = "麦克风权限未开启"
                    self.directionText = "请在系统设置中允许麦克风"
                    self.statusColorName = "red"
                    return
                }

                do {
                    try self.recorder.start()
                    self.isListening = true
                    self.microphoneStatusText = "正在监听所选弦"
                    self.recognitionStatusText = "等待拨弦"
                    self.directionText = self.selectedString.tuningHint
                    self.statusColorName = "secondary"
                } catch {
                    self.isListening = false
                    self.microphoneStatusText = "启动失败"
                    self.directionText = "请检查麦克风权限和音频会话"
                    self.statusColorName = "red"
                }
            }
        }
    }

    func stopListening() {
        guard isListening else {
            return
        }

        publishBestCurrentPluckIfNeeded()
        recorder.stop()
        isListening = false
        microphoneStatusText = "麦克风已停止"
        recognitionStatusText = "已停止"
        inputActivityLevel = 0
        directionText = selectedString.tuningHint
        statusColorName = "secondary"
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func recalculateLastResult() {
        recalculateLastResult(for: selectedString)
    }

    private func recalculateLastResult(for string: PipaString) {
        updateTargetLabels(for: string)

        guard let lastDetectedFrequency else {
            directionText = string.tuningHint
            centsText = "--"
            centsOffset = nil
            confidenceText = "0%"
            detectedFrequencyText = "--"
            statusColorName = "secondary"
            return
        }

        let result = TuningGuide.evaluate(
            detectedFrequency: lastDetectedFrequency,
            targetFrequency: string.targetFrequency,
            confidence: lastConfidence
        )
        apply(result)
    }

    func handleAudioFrame(_ frame: AudioAnalysisFrame) {
        inputActivityLevel = frame.activityLevel
        let isActiveFrame = frame.activityLevel > 0.08
        recognitionStatusText = isActiveFrame ? "识别中..." : "等待下一次拨弦"

        guard isActiveFrame else {
            let didPublishResult = publishBestCurrentPluckIfNeeded()
            guard !didPublishResult else {
                return
            }

            if lastDetectedFrequency != nil {
                microphoneStatusText = "等待下一次拨弦"
            } else {
                directionText = "请轻拨所选弦"
                statusColorName = "secondary"
            }
            return
        }

        isCollectingPluck = true

        if let detection = frame.detection {
            collectBestDetection(detection)
            recognitionStatusText = "已捕捉，等待声音结束"
        }
    }

    func handleDetection(_ detection: PitchDetectionResult?) {
        guard let detection else {
            guard lastDetectedFrequency != nil else {
                directionText = "请轻拨所选弦"
                statusColorName = "secondary"
                return
            }

            microphoneStatusText = "等待下一次拨弦"
            statusColorName = "secondary"
            return
        }

        lastDetectedFrequency = detection.frequency
        lastConfidence = detection.confidence

        let result = TuningGuide.evaluate(
            detectedFrequency: detection.frequency,
            targetFrequency: selectedString.targetFrequency,
            confidence: detection.confidence
        )
        apply(result)
    }

    private func collectBestDetection(_ detection: PitchDetectionResult) {
        guard let currentBest = bestCurrentPluckDetection else {
            bestCurrentPluckDetection = detection
            return
        }

        if detection.confidence > currentBest.confidence {
            bestCurrentPluckDetection = detection
        }
    }

    @discardableResult
    private func publishBestCurrentPluckIfNeeded() -> Bool {
        guard isCollectingPluck else {
            return false
        }

        defer {
            isCollectingPluck = false
            bestCurrentPluckDetection = nil
        }

        guard let detection = bestCurrentPluckDetection else {
            return false
        }

        lastDetectedFrequency = detection.frequency
        lastConfidence = detection.confidence

        let result = TuningGuide.evaluate(
            detectedFrequency: detection.frequency,
            targetFrequency: selectedString.targetFrequency,
            confidence: detection.confidence
        )
        apply(result)
        microphoneStatusText = "已显示本次最佳结果"
        return true
    }

    private func apply(_ result: TuningResult) {
        detectedFrequencyText = result.frequencyText
        centsText = result.centsText
        centsOffset = result.centsOffset
        confidenceText = TuningGuide.confidenceLabel(result.confidence)
        directionText = result.directionText
        statusColorName = colorName(for: result.direction)
    }

    private func updateTargetLabels() {
        updateTargetLabels(for: selectedString)
    }

    private func updateTargetLabels(for string: PipaString) {
        targetFrequencyText = string.targetDisplayText
    }

    private func colorName(for direction: TuningDirection) -> String {
        switch direction {
        case .flat:
            return "orange"
        case .sharp:
            return "blue"
        case .inTune:
            return "green"
        case .silent:
            return "secondary"
        }
    }
}

struct AudioAnalysisFrame {
    let detection: PitchDetectionResult?
    let activityLevel: Double
}

private final class AudioRecorder {
    var onAudioFrame: ((AudioAnalysisFrame) -> Void)?

    private let engine = AVAudioEngine()
    private let detector = PitchDetectionEngine()
    private var isRunning = false

    func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }

    func start() throws {
        guard !isRunning else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP])
        try session.setPreferredSampleRate(44_100)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let activityLevel = self.activityLevel(from: buffer)
            let detection = self.detector.detectPitch(from: buffer)
            self.onAudioFrame?(AudioAnalysisFrame(detection: detection, activityLevel: activityLevel))
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else {
            return
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
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
        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sample = Double(channelData[channel][frame])
                sumSquares += sample * sample
            }
        }

        let rms = sqrt(sumSquares / Double(frameLength * channelCount))
        return min(1.0, rms / 0.08)
    }
}
