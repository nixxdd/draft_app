//
//  CanvasModels.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI

enum CanvasItemKind: String, Codable, CaseIterable {
    case polaroidPhoto
    case friendAvatar
    case voiceNote
    case mapLocation
    case tapeLabel
    case musicTag
    case emojiSticker
}

enum WashiTapeStyle: String, Codable, CaseIterable {
    case topLeftYellow
    case topRightCream
    case topCenterPink
    case none
    
    var label: String {
        switch self {
        case .topLeftYellow: return "Yellow Corner Tape"
        case .topRightCream: return "Cream Corner Tape"
        case .topCenterPink: return "Pink Top Tape"
        case .none: return "No Tape"
        }
    }
}

struct CanvasItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: CanvasItemKind

    var position: CGPoint
    var size: CGSize
    var rotationDegrees: Double
    var scale: CGFloat
    var zIndex: Double
    
    var customImageFilename: String?
    var text: String?
    var subtitle: String?
    var friendID: UUID?
    var tapeStyle: WashiTapeStyle = .topLeftYellow
    var borderWidth: CGFloat = 9
    var hasShadow: Bool = true
    var stickerColorHex: String = "#F5EC87"
    var voiceDurationSeconds: Double = 8.0
    var audioFilename: String?
    var latitude: Double?
    var longitude: Double?
}

enum CanvasTemplate: String, CaseIterable, Identifiable {
    case sketchDefault = "Touristing Classic"
    case polaroidStack = "Polaroid Stack"
    case postcardSplit = "Postcard & Map"
    case friendSpotlight = "Friend Spotlight"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sketchDefault: return "rectangle.3.group.fill"
        case .polaroidStack: return "photo.stack.fill"
        case .postcardSplit: return "map.fill"
        case .friendSpotlight: return "person.2.crop.square.stack.fill"
        }
    }
}
