import SwiftUI

struct CompactDashboard: View {
    @ObservedObject var viewModel: TunerViewModel
    @Binding var tuningMode: TuningMode
    @Binding var selectedString: PipaString
    let statusColor: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let usesPhoneCompactSizing = width >= 360 && width <= 460
            let leftWidth = min(usesPhoneCompactSizing ? 76 : 84, width * 0.21)
            let rightWidth = min(usesPhoneCompactSizing ? 112 : 120, width * 0.30)
            let panelSpacing: CGFloat = usesPhoneCompactSizing ? 7 : 10

            ZStack {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: panelSpacing) {
                        CompactDeviationPanel(centsOffset: viewModel.centsOffset, statusColor: statusColor)
                            .frame(height: usesPhoneCompactSizing ? 388 : 426)
                    }
                    .frame(width: leftWidth)

                    Spacer(minLength: 0)

                    VStack(spacing: panelSpacing) {
                        CompactReadoutPanel(viewModel: viewModel, statusColor: statusColor)
                        CompactConfidencePanel(
                            confidenceText: viewModel.confidenceText,
                            statusColor: statusColor,
                            isActive: viewModel.detectedFrequencyText != "--"
                        )
                    }
                    .frame(width: rightWidth)
                }
            }
        }
        .frame(height: 438)
    }
}
