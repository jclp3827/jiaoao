import SwiftUI

struct HTMLStyleCompactDashboard: View {
    @ObservedObject var viewModel: TunerViewModel
    @Binding var tuningMode: TuningMode
    @Binding var selectedString: PipaString
    let statusColor: Color

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let leftWidth = min(112, width * 0.30)
                let rightWidth = min(122, width * 0.32)
                let panelSpacing: CGFloat = 12

                ZStack {
                    Image("pipaHero")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(width * 0.94, 370), height: height * 1.08)
                        .shadow(color: .black.opacity(0.62), radius: 24, x: 0, y: 18)
                        .shadow(color: TunerTheme.copper.opacity(0.20), radius: 22, x: 0, y: 0)
                        .position(x: width / 2, y: height * 0.54)
                        .accessibilityLabel("琵琶")

                    RadialGradient(
                        colors: [TunerTheme.gold.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 12,
                        endRadius: 210
                    )
                    .frame(width: width * 0.78, height: height * 0.72)
                    .position(x: width / 2, y: height * 0.48)
                    .allowsHitTesting(false)

                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: panelSpacing) {
                            HTMLStringPickerPanel(selectedString: $selectedString, isEnabled: tuningMode == .manual)
                                .fixedSize(horizontal: false, vertical: true)
                            HTMLDeviationPanel(centsOffset: viewModel.centsOffset, statusColor: statusColor)
                                .frame(height: 330)
                        }
                        .frame(width: leftWidth)

                        Spacer(minLength: 0)

                        VStack(spacing: panelSpacing) {
                            HTMLTargetPanel(string: viewModel.activeString)
                            HTMLReadoutPanel(viewModel: viewModel)
                            HTMLConfidencePanel(confidenceText: viewModel.confidenceText)
                        }
                        .frame(width: rightWidth)
                    }
                }
            }
            .frame(height: 486)
        }
    }
}
