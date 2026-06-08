import Foundation

struct TunerStatusPresenter {
    var initialDirectionText: String { "点击开始，准备拾音" }
    var microphoneNotStartedText: String { "麦克风尚未启动" }
    var recognitionNotStartedText: String { "未开始" }
    var autoWaitingText: String { "等待判弦" }
    var requestingPermissionText: String { "正在请求麦克风权限..." }
    var startingMicrophoneText: String { "正在启动麦克风..." }
    var microphoneListeningText: String { "正在监听所选弦" }
    var permissionDeniedText: String { "麦克风权限未开启" }
    var permissionDirectionText: String { "请在系统设置中允许麦克风" }
    var startFailedText: String { "启动失败" }
    var startFailedDirectionText: String { "请检查麦克风权限和音频会话" }
    var microphoneStoppedText: String { "麦克风已停止" }
    var recognitionStoppedText: String { "已停止" }
    var waitingPluckText: String { "等待拨弦" }
    var waitingNextPluckText: String { "等待下一次拨弦" }
    var activeRecognizingText: String { "识别中..." }
    var findingStablePitchText: String { "已拾取声音，正在寻找稳定音高" }
    var analyzingPluckText: String { "正在分析本次拨弦" }
    var recognizingUntilReleaseText: String { "正在识别，松手后锁定" }
    var highHarmonicText: String { "拾取到高次谐波，请靠近重拨" }
    var lockedMicrophoneText: String { "已锁定本次结果" }
    var lockedRecognitionText: String { "已锁定结果，等待下一次拨弦" }
    var unstableDirectionText: String { "已拾取声音，未能稳定识别音高" }
    var unstableMicrophoneText: String { "请靠近麦克风重拨所选弦" }
    var unstableRecognitionText: String { "未锁定稳定音高" }
    var unstableEventText: String { "锁定失败，结果不稳定" }
    var lightPluckText: String { "请轻拨所选弦" }
    var lockedEventLabel: String { "本次锁定" }

    func listeningPrompt(for string: PipaString, mode: TuningMode) -> String {
        mode == .auto ? "请拨动任意一根弦，系统将自动识别" : string.tuningHint
    }

    func waitingMicrophoneText(for string: PipaString, mode: TuningMode) -> String {
        mode == .auto ? "自动模式已开启，请拨弦" : "已切换到\(string.shortName)，请拨弦"
    }

    func autoStatusText(mode: TuningMode, autoDetectedString: PipaString?, selectedString: PipaString) -> String {
        mode == .auto ? (autoDetectedString?.shortName ?? autoWaitingText) : selectedString.shortName
    }
}
