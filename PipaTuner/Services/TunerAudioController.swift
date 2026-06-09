import AVFoundation
import Foundation

final class TunerAudioController {
    var onAudioFrame: ((AudioAnalysisFrame) -> Void)?

    private let recorder = AudioRecorder()
    private let startQueue = DispatchQueue(label: "PipaTuner.audioStart")

    init() {
        recorder.onAudioFrame = { [weak self] frame in
            self?.onAudioFrame?(frame)
        }
    }

    var recordPermission: TunerMicrophonePermission {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .undetermined
        @unknown default:
            return .denied
        }
    }

    func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        recorder.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func start(
        targetFrequency: Double?,
        completion: @escaping (TunerAudioStartResult) -> Void
    ) {
        guard recordPermission == .granted else {
            completion(.permissionDenied)
            return
        }

        recorder.targetFrequency = targetFrequency
        startQueue.async { [recorder] in
            do {
                try recorder.start()
                DispatchQueue.main.async {
                    completion(.started)
                }
            } catch {
                recorder.stop()
                DispatchQueue.main.async {
                    completion(.failed)
                }
            }
        }
    }

    func stop() {
        startQueue.async { [recorder] in
            recorder.stop()
        }
    }

    func updateTargetFrequency(_ frequency: Double?) {
        recorder.targetFrequency = frequency
    }
}

enum TunerAudioStartResult: Equatable {
    case started
    case permissionDenied
    case failed
}

enum TunerMicrophonePermission: Equatable {
    case undetermined
    case granted
    case denied
}
