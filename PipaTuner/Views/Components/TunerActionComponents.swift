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
    let isListening: Bool
    let isStarting: Bool
    let resultStatusText: String
    let microphoneStatusText: String
    let activityLevel: Double
    let tint: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            TunerActionStatusBanner(text: resultStatusText, tint: tint)

            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: isListening ? "stop.fill" : (isStarting ? "hourglass" : "waveform"))
                        .font(.system(size: 21, weight: .bold))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.22), in: Circle())

                    Rectangle()
                        .fill(Color.black.opacity(0.24))
                        .frame(width: 1, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(actionTitle)
                            .font(.system(size: 24, weight: .black, design: .serif))
                            .tunerSingleLine(0.78)

                        if isListening {
                            AudioActivityWaveform(
                                level: activityLevel,
                                tint: activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? TunerTheme.acidGreen : Color(red: 0.25, green: 0.21, blue: 0.16)
                            )
                            .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18)
                            .opacity(activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? 0.92 : 0.62)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(TunerTheme.actionInk)
                .padding(.horizontal, 20)
                .padding(.vertical, isListening ? 8 : 10)
                .frame(height: 66)
                .background(
                    Capsule()
                        .fill(TunerTheme.actionGradient)
                )
                .overlay(
                    Capsule()
                        .stroke(TunerTheme.gold.opacity(0.85), lineWidth: 1.3)
                )
                .shadow(color: TunerTheme.copper.opacity(0.45), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isStarting)
            .opacity(isStarting ? 0.78 : 1)

            Text(microphoneStatusText)
                .font(.caption)
                .foregroundStyle(TunerTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
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
        if isListening {
            return "停止调弦"
        }
        return isStarting ? "正在启动" : "开始调弦"
    }
}

private struct TunerActionStatusBanner: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .shadow(color: tint.opacity(0.68), radius: 5, x: 0, y: 0)

            Text(text)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(TunerTheme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.30), in: Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.34), lineWidth: 1)
        )
    }
}
