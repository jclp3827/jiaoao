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
    let microphoneStatusText: String
    let activityLevel: Double
    let tint: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: isListening ? "stop.fill" : (isStarting ? "hourglass" : "waveform"))
                        .font(.system(size: 23, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.22), in: Circle())

                    Rectangle()
                        .fill(Color.black.opacity(0.24))
                        .frame(width: 1, height: 30)

                    if isListening {
                        AudioActivityWaveform(
                            level: activityLevel,
                            tint: activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? TunerTheme.acidGreen : Color(red: 0.25, green: 0.21, blue: 0.16)
                        )
                        .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                        .opacity(activityLevel > TunerConfiguration.AudioInput.activeFrameLevel ? 0.92 : 0.62)
                    } else {
                        Text(isStarting ? "启动中" : "开始调弦")
                            .font(.system(size: 26, weight: .black, design: .serif))
                        Spacer(minLength: 0)
                    }
                }
                .foregroundStyle(TunerTheme.actionInk)
                .padding(.horizontal, 22)
                .padding(.vertical, isListening ? 9 : 12)
                .frame(height: 72)
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
            .opacity(isStarting ? 0.74 : 1)

            Text(microphoneStatusText)
                .font(.caption)
                .foregroundStyle(TunerTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
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
}
