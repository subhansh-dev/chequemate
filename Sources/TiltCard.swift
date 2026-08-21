import SwiftUI

struct TiltCard<Content: View>: View {
    @ViewBuilder var content: Content

    private let maxTilt: Double = 4

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        content
            .rotation3DEffect(
                .degrees(tiltAngles.y),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(tiltAngles.x),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isDragging)
            .animation(.spring(response: 0.2, dampingFraction: 1.0), value: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragOffset = .zero
                    }
            )
    }

    private var tiltAngles: CGPoint {
        let clampedX = max(-150, min(150, dragOffset.width))
        let clampedY = max(-150, min(150, dragOffset.height))
        return CGPoint(
            x: (clampedX / 150) * maxTilt,
            y: -(clampedY / 150) * maxTilt
        )
    }
}
