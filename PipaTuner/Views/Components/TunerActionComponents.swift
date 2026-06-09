import SwiftUI

struct FloatingDiagnosticsButton: View {
    let showsDiagnostics: Bool
    let action: () -> Void

    var body: some View {
        FloatingIconButton(
            systemName: showsDiagnostics ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle",
            tint: showsDiagnostics ? TunerTheme.acidGreen : TunerTheme.gold,
            action: action
        )
        .accessibilityLabel("诊断")
    }
}

struct TunerActionBar: View {
    let tuningMode: TuningMode
    @Binding var selectedString: PipaString
    let displayString: PipaString
    let isListening: Bool
    let isStarting: Bool
    let resultStatusText: String
    let microphoneStatusText: String
    let activityLevel: Double
    let tint: Color
    let toggleTuningMode: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 9) {
                BottomStringTabs(
                    selectedString: $selectedString,
                    displayString: displayString,
                    isEnabled: tuningMode == .manual
                )

                TuningModeControl(
                    tuningMode: tuningMode,
                    action: toggleTuningMode
                )
            }

            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: isListening ? "stop.fill" : (isStarting ? "hourglass" : "waveform"))
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.22), in: Circle())

                    Rectangle()
                        .fill(Color.black.opacity(0.24))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 6) {
                        if isListening {
                            Text(actionHintText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(TunerTheme.actionInk.opacity(0.84))
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                                .frame(maxWidth: .infinity)

                            AudioActivityWaveform(
                                level: activityLevel,
                                tint: activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? TunerTheme.acidGreen : Color(red: 0.25, green: 0.21, blue: 0.16)
                            )
                            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                            .opacity(activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? 0.92 : 0.62)
                        } else {
                            Text(actionTitle)
                                .font(.system(size: 24, weight: .black, design: .serif))
                                .foregroundStyle(TunerTheme.actionInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(TunerTheme.actionInk)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .frame(height: 72)
                .background(
                    Capsule()
                        .fill(TunerTheme.actionGradient)
                )
                .overlay(
                    Capsule()
                        .stroke(TunerTheme.gold.opacity(0.85), lineWidth: 1.3)
                )
                .shadow(color: TunerTheme.copper.opacity(0.38), radius: 13, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            .disabled(isStarting)
            .opacity(isStarting ? 0.78 : 1)
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    TunerTheme.ink.opacity(0.92),
                    TunerTheme.ink
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var actionTitle: String {
        return isStarting ? "正在启动" : "开始调弦"
    }

    private var actionHintText: String {
        let trimmedResult = resultStatusText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMicrophone = microphoneStatusText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedMicrophone == "麦克风权限受限" {
            return "请允许麦克风权限"
        }
        if trimmedMicrophone == "启动失败" || trimmedMicrophone == "启动超时" {
            return "麦克风未响应，请重试"
        }
        if isStarting {
            return "正在准备麦克风"
        }
        if isListening, ["拨弦后显示结果", "准备调弦", "已停止"].contains(trimmedResult) {
            return tuningMode == .auto ? "拨任意弦，自动判弦" : "\(displayString.shortName) 拨弦后显示结果"
        }
        if isListening, ["正在识别音高", "保持片刻，等待稳定"].contains(trimmedResult) {
            return "保持片刻，等待稳定"
        }
        if !isListening {
            return "准备调弦"
        }
        if trimmedResult.isEmpty || trimmedResult == trimmedMicrophone {
            return tuningMode == .auto ? "拨任意弦，自动判弦" : "\(displayString.shortName) 拨弦后显示结果"
        }
        return trimmedResult
    }
}

private struct BottomStringTabs: View {
    @Binding var selectedString: PipaString
    let displayString: PipaString
    let isEnabled: Bool

    var body: some View {
        NativeStringSegmentedControl(
            selection: selectionBinding,
            strings: PipaString.tuningOrder,
            isEnabled: isEnabled
        )
        .frame(height: 51)
        .frame(maxWidth: .infinity)
        .opacity(isEnabled ? 1 : 0.82)
        .tunerSurface(.inset, cornerRadius: 25.5)
    }

    private var selectionBinding: Binding<PipaString> {
        Binding(
            get: {
                isEnabled ? selectedString : displayString
            },
            set: { newValue in
                guard isEnabled else { return }
                selectedString = newValue
            }
        )
    }

}

private struct TuningModeControl: View {
    let tuningMode: TuningMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .bold))

                Text(tuningMode == .manual ? "手动" : "自动")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(TunerTheme.gold)
            .frame(width: 88, height: 51)
            .tunerSurface(.inset, cornerRadius: 25.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("切换调音模式")
    }
}
