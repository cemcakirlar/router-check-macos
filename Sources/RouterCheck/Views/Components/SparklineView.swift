import SwiftUI

public struct SparklineView: View {
    public let points: [Double]
    public let strokeColor: Color
    public let fillColor: Color?

    public init(
        points: [Double],
        strokeColor: Color = .cyan,
        fillColor: Color? = nil
    ) {
        self.points = points
        self.strokeColor = strokeColor
        self.fillColor = fillColor ?? strokeColor.opacity(0.15)
    }

    public var body: some View {
        GeometryReader { geo in
            if points.count >= 2 {
                let minVal = points.min() ?? 0
                let maxVal = points.max() ?? 1
                let range = max(maxVal - minVal, 0.001)

                let path = Path { p in
                    for (index, val) in points.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(points.count - 1)
                        let yRatio = CGFloat((val - minVal) / range)
                        let y = geo.size.height * (1.0 - yRatio)
                        if index == 0 {
                            p.move(to: CGPoint(x: x, y: y))
                        } else {
                            p.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                let areaPath = Path { p in
                    p.addPath(path)
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    p.closeSubpath()
                }

                ZStack {
                    if let fill = fillColor {
                        areaPath.fill(
                            LinearGradient(
                                colors: [fill, fill.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    path.stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                }
            } else {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                    Spacer()
                }
            }
        }
        .frame(height: 38)
    }
}
