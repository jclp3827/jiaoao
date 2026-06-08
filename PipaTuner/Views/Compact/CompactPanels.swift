import SwiftUI

struct HTMLGlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity)
            .tunerSurface(.glass, cornerRadius: 18)
    }
}

struct HTMLStringPickerPanel: View {
    @Binding var selectedString: PipaString
    let isEnabled: Bool

    var body: some View {
        HTMLGlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HTMLPanelTitle(isEnabled ? "选择弦" : "自动判弦")
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    ForEach(PipaString.tuningOrder) { string in
                        HTMLStringOption(string: string, isSelected: selectedString == string, isEnabled: isEnabled) {
                            selectedString = string
                        }
                    }
                }
            }
        }
    }
}

struct HTMLStringOption: View {
    let string: PipaString
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(string.shortName) / \(string.roleName)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(isSelected ? TunerTheme.text : TunerTheme.muted.opacity(0.70))
                    .tunerSingleLine()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .tunerOptionChrome(isSelected: isSelected, chromeStyle: .compact, cornerRadius: 12)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.72)
    }
}

struct HTMLReadoutPanel: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 6) {
                HTMLPanelTitle("实时结果")
                if viewModel.tuningMode == .auto {
                    AutoDetectionPill(title: "自动", value: viewModel.autoStatusText)
                }
                ZStack {
                    Circle()
                        .stroke(TunerTheme.gold.opacity(0.16), lineWidth: 1)
                        .frame(width: 58, height: 58)
                    Text(viewModel.activeString.displayPitchName)
                        .tunerMetricText(size: 34, weight: .black, design: .serif)
                }
                Text(viewModel.detectedFrequencyText)
                    .tunerMetricText(size: 17, weight: .bold)
                    .tunerSingleLine()
                Text(viewModel.activeString.jianpuLabel)
                    .font(.caption2)
                    .tunerTextTone(.muted)
            }
        }
    }
}

struct HTMLTargetPanel: View {
    let string: PipaString

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 5) {
                HTMLPanelTitle("目标音高")
                Text(string.displayPitchName)
                    .tunerMetricText(size: 31, weight: .black, design: .serif)
                Text(string.frequencyLabel)
                    .tunerMetricText(size: 15, weight: .bold)
                    .tunerSingleLine()
                Text(string.jianpuLabel)
                    .font(.caption2)
                    .tunerTextTone(.muted)
            }
        }
    }
}

struct HTMLConfidencePanel: View {
    let confidenceText: String

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 6) {
                HTMLPanelTitle("偏差")
                Text(confidenceText)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.35, green: 0.88, blue: 0.47))
                    .tunerSingleLine()
                Text("置信度")
                    .font(.caption2)
                    .tunerTextTone(.muted)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index < activeSegments ? Color(red: 0.35, green: 0.88, blue: 0.47) : TunerTheme.muted.opacity(0.22))
                            .frame(height: 5)
                    }
                }
            }
        }
    }

    private var activeSegments: Int {
        let digits = confidenceText.filter(\.isNumber)
        let value = Int(digits) ?? 0
        return max(0, min(5, Int((Double(value) / 100.0 * 5.0).rounded(.up))))
    }
}

struct HTMLPanelTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .tunerMetricText(size: 15, weight: .bold, design: .serif)
            .tunerSingleLine(0.8)
    }
}
