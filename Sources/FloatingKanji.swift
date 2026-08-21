import SwiftUI

struct FloatingKanji: View {
    let text: String

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                let horizontalProgress = (time / 20.0).truncatingRemainder(dividingBy: 1.0)
                let xPosition = horizontalProgress * (geometry.size.width + 200) - 100

                let yOffset = sin(time / 2.5) * (geometry.size.height * 0.25)
                let yPosition = geometry.size.height / 2 + yOffset

                Text(text)
                    .font(.system(size: 120, weight: .light, design: .serif))
                    .opacity(0.06)
                    .position(x: xPosition, y: yPosition)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
