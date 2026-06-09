import SwiftUI
import UIKit

struct NativeStringSegmentedControl: UIViewRepresentable {
    @Binding var selection: PipaString
    let strings: [PipaString]
    let isEnabled: Bool

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = TunerSegmentedControl(items: strings.map(\.shortName))
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        control.apportionsSegmentWidthsByContent = false
        applyTheme(to: control)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        if control.numberOfSegments != strings.count {
            control.removeAllSegments()
            for (index, string) in strings.enumerated() {
                control.insertSegment(withTitle: string.shortName, at: index, animated: false)
            }
        }

        control.selectedSegmentIndex = strings.firstIndex(of: selection) ?? 0
        control.isEnabled = isEnabled
        applyTheme(to: control)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, strings: strings)
    }

    private func applyTheme(to control: UISegmentedControl) {
        control.backgroundColor = .clear
        control.selectedSegmentTintColor = UIColor(TunerTheme.copper)
        control.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        control.setDividerImage(UIImage(), forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        control.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .selected, barMetrics: .default)
        control.layer.borderColor = UIColor.clear.cgColor
        control.layer.borderWidth = 0
        control.layer.cornerRadius = 18
        control.layer.cornerCurve = .continuous
        control.clipsToBounds = true
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor(TunerTheme.text.opacity(0.84)),
                .font: UIFont.systemFont(ofSize: 19, weight: .semibold)
            ],
            for: .normal
        )
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor(TunerTheme.actionInk),
                .font: UIFont.systemFont(ofSize: 19, weight: .bold)
            ],
            for: .selected
        )
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor(TunerTheme.muted.opacity(0.70)),
                .font: UIFont.systemFont(ofSize: 19, weight: .semibold)
            ],
            for: .disabled
        )
    }

    final class Coordinator: NSObject {
        @Binding private var selection: PipaString
        private let strings: [PipaString]

        init(selection: Binding<PipaString>, strings: [PipaString]) {
            _selection = selection
            self.strings = strings
        }

        @objc func valueChanged(_ sender: UISegmentedControl) {
            guard strings.indices.contains(sender.selectedSegmentIndex) else {
                return
            }
            selection = strings[sender.selectedSegmentIndex]
        }
    }
}

private final class TunerSegmentedControl: UISegmentedControl {
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 45
        return size
    }
}
