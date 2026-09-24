import SwiftUI

public enum SignalGrade: String, Sendable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case unknown = "--"

    public static func forRsrp(_ value: Int?) -> SignalGrade {
        guard let v = value else { return .unknown }
        if v >= -80 { return .excellent }
        if v >= -90 { return .good }
        if v >= -105 { return .fair }
        return .poor
    }

    public static func forSinr(_ value: Double?) -> SignalGrade {
        guard let v = value else { return .unknown }
        if v >= 15.0 { return .excellent }
        if v >= 10.0 { return .good }
        if v >= 5.0 { return .fair }
        return .poor
    }

    public var color: Color {
        switch self {
        case .excellent:
            return Color(red: 0.18, green: 0.84, blue: 0.45) // Vibrant Green
        case .good:
            return Color(red: 0.0, green: 0.78, blue: 0.99)  // Vibrant Cyan
        case .fair:
            return Color(red: 0.98, green: 0.75, blue: 0.18) // Amber
        case .poor:
            return Color(red: 0.96, green: 0.26, blue: 0.35) // Neon Red/Rose
        case .unknown:
            return Color.secondary
        }
    }
}
