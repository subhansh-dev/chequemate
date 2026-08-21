import SwiftUI

struct AnimatedDashedBorder: View {
    let color: Color
    let cornerRadius: CGFloat
    var lineWidth: CGFloat = 2
    var dashPattern: [CGFloat] = [8, 6]
    var animationDuration: CGFloat = 1.5

    private var patternLength: CGFloat {
        dashPattern.reduce(0, +)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let phase = -patternLength
                * CGFloat(elapsed.truncatingRemainder(dividingBy: animationDuration) / animationDuration)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        dash: dashPattern,
                        dashPhase: phase
                    )
                )
        }
    }
}
