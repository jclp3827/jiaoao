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

    func start(
        targetFrequency: Double?,
        onPermissionGranted: @escaping () -> Void,
        completion: @escaping (TunerAudioStartResult) -> Void
    ) {
        recorder.requestRecordPermission { [weak self] granted in
            guard let self else { return }

            guard granted else {
                DispatchQueue.main.async {
                    completion(.permissionDenied)
                }
                return
            }

            DispatchQueue.main.async {
                onPermissionGranted()
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
