import SwiftUI

struct TunerHeader: View {
    let tuningMode: TuningMode
    let toggleTuningMode: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            header(fontSize: 42, gearSize: 28)
            header(fontSize: 36, gearSize: 25)
        }
    }

    private func header(fontSize: CGFloat, gearSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("琵琶调音")
                            .font(.system(size: fontSize, weight: .black, design: .serif))
                            .foregroundStyle(TunerTheme.text)
                            .shadow(color: TunerTheme.copper.opacity(0.38), radius: 8, x: 0, y: 3)

                        Text("听准")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(TunerTheme.copper)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(TunerTheme.copper, lineWidth: 1)
                            )
                    }
                }

                Spacer(minLength: 0)

                Button(action: toggleTuningMode) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tuningMode == .manual ? "手动" : "自动")
                            .font(.system(size: gearSize - 8, weight: .bold, design: .rounded))
                        Text("切换")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(TunerTheme.gold)
                    .padding(.top, 4)
                    .accessibilityLabel("切换调音模式")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PipaHeroStage: View {
    let string: PipaString
    let statusColor: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            RadialGradient(
                colors: [
                    TunerTheme.gold.opacity(0.18),
                    TunerTheme.copper.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 360
            )

            Image("pipaHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 360, maxHeight: 620)
                .shadow(color: .black.opacity(0.52), radius: 28, x: 0, y: 22)
                .shadow(color: statusColor.opacity(0.16), radius: 18, x: 0, y: 0)
                .accessibilityLabel("琵琶")

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.22)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Spacer()
                CurrentSelectionPill(string: string)
                    .frame(maxWidth: 360)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactHeroStage: View {
    @ObservedObject var viewModel: TunerViewModel
    let string: PipaString
    let statusColor: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let sideCardWidth = min(126, width * 0.35)
            let imageWidth = min(width * 0.70, 260)

            ZStack {
                RadialGradient(
                    colors: [
                        TunerTheme.gold.opacity(0.18),
                        TunerTheme.copper.opacity(0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 16,
                    endRadius: 250
                )
                .frame(width: width * 1.08, height: height * 0.82)
                .position(x: width / 2, y: height * 0.45)

                Image("pipaHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth, height: height * 0.92)
                    .shadow(color: .black.opacity(0.58), radius: 24, x: 0, y: 18)
                    .shadow(color: statusColor.opacity(0.16), radius: 18, x: 0, y: 0)
                    .position(x: width / 2, y: height * 0.44)
                    .accessibilityLabel("琵琶")

                CompactMetricBadge(
                    title: "实时结果",
                    primary: viewModel.activeString.displayPitchName,
                    secondary: viewModel.detectedFrequencyText,
                    alignment: .leading
                )
                .frame(width: sideCardWidth)
                .position(x: sideCardWidth / 2 + 2, y: height * 0.23)

                CompactMetricBadge(
                    title: "目标音高",
                    primary: string.displayPitchName,
                    secondary: string.frequencyLabel,
                    alignment: .trailing
                )
                .frame(width: sideCardWidth)
                .position(x: width - sideCardWidth / 2 - 2, y: height * 0.31)

                CompactMetricBadge(
                    title: "偏差",
                    primary: viewModel.centsOffset == nil ? "--" : viewModel.centsText,
                    secondary: viewModel.directionText,
                    alignment: .leading
                )
                .frame(width: sideCardWidth)
                .position(x: sideCardWidth / 2 + 6, y: height * 0.56)

                CompactMetricBadge(
                    title: "置信度",
                    primary: viewModel.confidenceText,
                    secondary: viewModel.recognitionStatusText,
                    alignment: .trailing
                )
                .frame(width: sideCardWidth)
                .position(x: width - sideCardWidth / 2 - 6, y: height * 0.64)

                CurrentSelectionPill(string: string)
                    .frame(maxWidth: min(300, width - 36))
                    .position(x: width / 2, y: height - 28)

                if viewModel.tuningMode == .auto {
                    AutoDetectionPill(title: "自动判弦", value: viewModel.autoStatusText)
                        .position(x: width / 2, y: height - 70)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactMetricBadge: View {
    let title: String
    let primary: String
    let secondary: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TunerTheme.muted)
                .lineLimit(1)
            Text(primary)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundStyle(TunerTheme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(secondary)
                .font(.caption2.weight(.medium))
                .foregroundStyle(TunerTheme.text.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .tunerSurface(.card, cornerRadius: 18)
    }

    private var frameAlignment: Alignment {
        alignment == .trailing ? .trailing : .leading
    }
}
