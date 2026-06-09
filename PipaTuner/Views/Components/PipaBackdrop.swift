import SwiftUI

struct PipaBackdrop: View {
    var body: some View {
        VStack {
            Spacer(minLength: 0)

            Image("pipaHero")
                .resizable()
                .scaledToFit()
                .frame(width: 372)
                .scaleEffect(1.24)
                .shadow(color: .black.opacity(0.58), radius: 20, x: 0, y: 14)
                .accessibilityLabel("琵琶")
                .allowsHitTesting(false)

            Spacer()
                .frame(height: 246)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
