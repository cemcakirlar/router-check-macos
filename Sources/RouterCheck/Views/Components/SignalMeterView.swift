import SwiftUI

public struct SignalMeterView: View {
    public let percentage: Double
    public let color: Color

    public init(percentage: Double, color: Color) {
        self.percentage = max(0, min(1, percentage))
        self.color = color
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(percentage))
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: 6)
    }
}
