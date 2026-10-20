import SwiftUI

enum SketchTheme {
    // MARK: - Gradients from DataBuddies.sketch
    
    /// Main screen pastel background gradient (stops at 0.0, 0.3, 0.65, 1.0)
    static let backgroundGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0.922, green: 0.957, blue: 1.000), location: 0.00),
            .init(color: Color(red: 0.988, green: 0.941, blue: 0.965), location: 0.30),
            .init(color: Color(red: 0.937, green: 0.973, blue: 0.953), location: 0.65),
            .init(color: Color(red: 0.980, green: 0.949, blue: 1.000), location: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Scrapbook canvas subtle atmospheric gradient matching Sketch preview
    static let canvasCardGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0.910, green: 0.865, blue: 0.918).opacity(0.85), location: 0.00),
            .init(color: Color(red: 0.865, green: 0.875, blue: 0.885).opacity(0.82), location: 0.48),
            .init(color: Color(red: 0.840, green: 0.890, blue: 0.868).opacity(0.88), location: 1.00)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Pastel aqua -> sky -> pink gradient used on primary CTA pills
    /// ("Who is in the card?", "Add from contacts", "Go to friend’s memories")
    static let pastelActionGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0.373, green: 0.886, blue: 0.820), location: 0.00),
            .init(color: Color(red: 0.635, green: 0.886, blue: 0.973), location: 0.50),
            .init(color: Color(red: 1.000, green: 0.659, blue: 0.773), location: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Magenta-purple glass pill gradient for the "Edit" button
    static let editPillGradient = LinearGradient(
        colors: [
            Color(red: 0.859, green: 0.204, blue: 0.949),
            Color(red: 0.796, green: 0.188, blue: 0.878)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Solid Colors from DataBuddies.sketch
    
    /// Lavender line color for Timeline track and Friends Cosmo constellation lines
    static let connectorLineColor = Color(red: 0.833, green: 0.816, blue: 0.915)
    
    /// Pink-purple color for calendar day badges (24, 25, 26)
    static let dateBadgeColor = Color(red: 0.816, green: 0.424, blue: 0.871)
    
    /// Yellow strip behind "Touristing" text
    static let yellowStickerColor = Color(red: 0.961, green: 0.925, blue: 0.529)
    
    /// Translucent yellow washi tape
    static let yellowWashiTape = Color(red: 0.961, green: 0.922, blue: 0.541).opacity(0.80)
    
    /// Translucent cream washi tape
    static let creamWashiTape = Color(red: 0.995, green: 0.989, blue: 0.936).opacity(0.95)
    
    /// Voice note waveform purple
    static let waveformPurple = Color(red: 0.580, green: 0.216, blue: 0.969)
}

// MARK: - Reusable Sketch UI Components

/// Calendar number badge (24, 25, 26...) matching SF Symbol `24.square` in Sketch
struct SketchDateBadge: View {
    let day: Int
    var isSelected: Bool = false
    
    var body: some View {
        Image(systemName: "\(max(1, min(31, day))).square")
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(
                SketchTheme.dateBadgeColor.opacity(isSelected ? 1.0 : 0.78)
            )
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 28, height: 28)
            )
    }
}

/// Top-left oval glass button (e.g. Friends `person.2` button in Memories Read View)
struct GlassOvalButton: View {
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black.opacity(0.85))
                .frame(width: 59, height: 44)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.9), .white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Pastel gradient CTA pill button used across Tagging Friends, Friends Cosmo, and Friend Profile
struct PastelGradientButton: View {
    let title: String
    var width: CGFloat? = nil
    var height: CGFloat = 44
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SketchTheme.pastelActionGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

