import SwiftUI

struct HTMLStyleCompactDashboard: View {
    @ObservedObject var viewModel: TunerViewModel
    @Binding var tuningMode: TuningMode
    @Binding var selectedString: PipaString
    let statusColor: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let usesPhoneCompactSizing = width >= 360 && width <= 460
            let leftWidth = min(usesPhoneCompactSizing ? 104 : 112, width * 0.29)
            let rightWidth = min(usesPhoneCompactSizing ? 112 : 122, width * 0.31)
            let panelSpacing: CGFloat = usesPhoneCompactSizing ? 8 : 12

            ZStack {
                Image("pipaHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(width * 0.88, 348), height: height * 1.02)
                    .shadow(color: .black.opacity(0.62), radius: 22, x: 0, y: 16)
                    .shadow(color: TunerTheme.copper.opacity(0.20), radius: 20, x: 0, y: 0)
                    .position(x: width / 2, y: height * 0.53)
                    .accessibilityLabel("琵琶")

                RadialGradient(
                    colors: [TunerTheme.gold.opacity(0.16), .clear],
                    center: .center,
                    startRadius: 12,
                    endRadius: 200
                )
                .frame(width: width * 0.76, height: height * 0.70)
                .position(x: width / 2, y: height * 0.48)
                .allowsHitTesting(false)

                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: panelSpacing) {
                        HTMLStringPickerPanel(selectedString: $selectedString, isEnabled: tuningMode == .manual)
                            .fixedSize(horizontal: false, vertical: true)
                        HTMLDeviationPanel(centsOffset: viewModel.centsOffset, statusColor: statusColor)
                            .frame(height: usesPhoneCompactSizing ? 288 : 330)
                    }
                    .frame(width: leftWidth)

                    Spacer(minLength: 0)

                    VStack(spacing: panelSpacing) {
                        HTMLReadoutPanel(viewModel: viewModel, statusColor: statusColor)
                        HTMLConfidencePanel(
                            confidenceText: viewModel.confidenceText,
                            statusColor: statusColor,
                            isActive: viewModel.detectedFrequencyText != "--"
                        )
                    }
                    .frame(width: rightWidth)
                }
            }
        }
        .frame(height: 450)
    }
}
