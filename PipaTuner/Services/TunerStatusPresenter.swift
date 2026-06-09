import Foundation

struct TunerStatusPresenter {
    var initialDirectionText: String { "点击开始，准备调弦" }
    var microphoneNotStartedText: String { "麦克风尚未启动" }
    var recognitionNotStartedText: String { "准备调弦" }
    var autoWaitingText: String { "等待判弦" }
    var requestingPermissionText: String { "请求麦克风权限" }
    var startingRecognitionText: String { "准备拾音" }
    var startingMicrophoneText: String { "正在启动麦克风" }
    var microphoneListeningText: String { "正在监听" }
    var permissionDeniedText: String { "麦克风权限受限" }
    var permissionDirectionText: String { "请在系统设置中允许麦克风" }
    var startFailedText: String { "启动失败" }
    var startFailedDirectionText: String { "请检查麦克风权限和音频会话" }
    var startTimeoutText: String { "启动超时" }
    var startTimeoutDirectionText: String { "麦克风没有响应，请重试" }
    var unableToStartTuningText: String { "无法开始调弦" }
    var retryStartTuningText: String { "请重试开始调弦" }
    var microphoneStoppedText: String { "麦克风已停止" }
    var recognitionStoppedText: String { "已停止" }
    var waitingPluckText: String { "拨弦后显示结果" }
    var waitingNextPluckText: String { "拨弦后显示结果" }
    var activeRecognizingText: String { "正在识别音高" }
    var findingStablePitchText: String { "正在识别音高" }
    var analyzingPluckText: String { "正在识别音高" }
    var recognizingUntilReleaseText: String { "保持片刻，等待稳定" }
    var highHarmonicText: String { "疑似泛音，重新拨弦" }
    var lockedMicrophoneText: String { "正在监听" }
    var lockedRecognitionText: String { "已锁定" }
    var unstableDirectionText: String { "本次声音不稳定" }
    var unstableMicrophoneText: String { "拨弦稍轻" }
    var unstableRecognitionText: String { "未锁定" }
    var unstableEventText: String { "锁定失败，结果不稳定" }
    var lightPluckText: String { "拨弦稍轻" }
    var lockedEventLabel: String { "本次锁定" }

    func listeningPrompt(for string: PipaString, mode: TuningMode) -> String {
        mode == .auto ? "拨任意弦，自动判弦" : string.tuningHint
    }

    func waitingMicrophoneText(for string: PipaString, mode: TuningMode) -> String {
        mode == .auto ? "正在监听" : "正在监听 \(string.shortName)"
    }

    func autoStatusText(mode: TuningMode, autoDetectedString: PipaString?, selectedString: PipaString) -> String {
        mode == .auto ? (autoDetectedString?.shortName ?? autoWaitingText) : selectedString.shortName
    }
}
