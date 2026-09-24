import Foundation

public enum Formatters {
    public static func formatSpeed(bps: Double?) -> String {
        guard let bps = bps, bps >= 0 else { return "--" }
        if bps >= 1_000_000_000 {
            return String(format: "%.2f Gbps", bps / 1_000_000_000)
        } else if bps >= 1_000_000 {
            return String(format: "%.2f Mbps", bps / 1_000_000)
        } else if bps >= 1_000 {
            return String(format: "%.1f Kbps", bps / 1_000)
        } else {
            return String(format: "%.0f bps", bps)
        }
    }

    public static func formatSpeedParts(bps: Double?) -> (value: String, unit: String) {
        guard let bps = bps, bps >= 0 else { return ("--", "") }
        if bps >= 1_000_000_000 {
            return (String(format: "%.2f", bps / 1_000_000_000), "Gbps")
        } else if bps >= 1_000_000 {
            return (String(format: "%.2f", bps / 1_000_000), "Mbps")
        } else if bps >= 1_000 {
            return (String(format: "%.1f", bps / 1_000), "Kbps")
        } else {
            return (String(format: "%.0f", bps), "bps")
        }
    }

    public static func formatBytes(_ bytes: Int64?) -> String {
        guard let bytes = bytes, bytes >= 0 else { return "--" }
        let d = Double(bytes)
        if d >= 1_073_741_824 * 1024 {
            return String(format: "%.2f TB", d / (1_073_741_824 * 1024))
        } else if d >= 1_073_741_824 {
            return String(format: "%.2f GB", d / 1_073_741_824)
        } else if d >= 1_048_576 {
            return String(format: "%.2f MB", d / 1_048_576)
        } else if d >= 1024 {
            return String(format: "%.1f KB", d / 1024)
        } else {
            return "\(bytes) B"
        }
    }

    public static func formatDuration(seconds: Int64?) -> String {
        guard let seconds = seconds, seconds > 0 else { return "--" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, secs)
        } else if minutes > 0 {
            return String(format: "%02dm %02ds", minutes, secs)
        } else {
            return String(format: "%02ds", secs)
        }
    }
}
