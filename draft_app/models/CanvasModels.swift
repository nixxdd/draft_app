//
//  CanvasModels.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI

// MARK: - Washi Tape Style

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

// MARK: - Polymorphic Content Payloads

struct MapPayload: Codable, Equatable {
    var title: String
    var latitude: Double
    var longitude: Double
    var zoom: Double = 0.05
    
    init(title: String = "Location", latitude: Double = 40.8518, longitude: Double = 14.2681, zoom: Double = 0.05) {
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.zoom = zoom
    }
}

struct LinkPayload: Codable, Equatable {
    var urlString: String
    var title: String
    var previewImageFilename: String?
    var host: String?
    
    init(urlString: String = "https://apple.com", title: String = "Apple", previewImageFilename: String? = nil, host: String? = "apple.com") {
        self.urlString = urlString
        self.title = title
        self.previewImageFilename = previewImageFilename
        self.host = host
    }
    
    var url: URL? {
        URL(string: urlString)
    }
}

struct ContactPayload: Codable, Equatable {
    var name: String
    var friendID: UUID?
    var avatarImageName: String?
    var subtitle: String?
    
    init(name: String = "Friend", friendID: UUID? = nil, avatarImageName: String? = nil, subtitle: String? = nil) {
        self.name = name
        self.friendID = friendID
        self.avatarImageName = avatarImageName
        self.subtitle = subtitle
    }
}

struct EmojiPayload: Codable, Equatable {
    var emoji: String
    var fontSize: CGFloat = 52
    
    init(emoji: String = "✨", fontSize: CGFloat = 52) {
        self.emoji = emoji
        self.fontSize = fontSize
    }
}

struct TextPayload: Codable, Equatable {
    var text: String
    var fontDesign: String = "rounded"
    var textColorHex: String = "#2C2C2E"
    var backgroundColorHex: String = "#F5EC87"
    
    init(text: String = "Note", fontDesign: String = "rounded", textColorHex: String = "#2C2C2E", backgroundColorHex: String = "#F5EC87") {
        self.text = text
        self.fontDesign = fontDesign
        self.textColorHex = textColorHex
        self.backgroundColorHex = backgroundColorHex
    }
}

struct PhotoPayload: Codable, Equatable {
    var imageFilename: String?
    var caption: String?
    var isPolaroid: Bool = true
    var imageData: Data? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var locationName: String? = nil
    
    init(
        imageFilename: String? = nil,
        caption: String? = nil,
        isPolaroid: Bool = true,
        imageData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) {
        self.imageFilename = imageFilename
        self.caption = caption
        self.isPolaroid = isPolaroid
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
    }
}

struct VideoPayload: Codable, Equatable {
    var videoFilename: String?
    var thumbnailFilename: String?
    var durationSeconds: Double = 0.0
    var isMuted: Bool = true
    var thumbnailData: Data? = nil
    var videoData: Data? = nil
    var videoURLString: String? = nil
    
    init(
        videoFilename: String? = nil,
        thumbnailFilename: String? = nil,
        durationSeconds: Double = 0.0,
        isMuted: Bool = true,
        thumbnailData: Data? = nil,
        videoData: Data? = nil,
        videoURLString: String? = nil
    ) {
        self.videoFilename = videoFilename
        self.thumbnailFilename = thumbnailFilename
        self.durationSeconds = durationSeconds
        self.isMuted = isMuted
        self.thumbnailData = thumbnailData
        self.videoData = videoData
        self.videoURLString = videoURLString
    }
}

struct FilePayload: Codable, Equatable {
    var filename: String
    var fileSizeDescription: String
    var fileExtension: String
    var fileData: Data? = nil
    var fileURLString: String? = nil
    
    init(
        filename: String = "Document.pdf",
        fileSizeDescription: String = "1.2 MB",
        fileExtension: String = "pdf",
        fileData: Data? = nil,
        fileURLString: String? = nil
    ) {
        self.filename = filename
        self.fileSizeDescription = fileSizeDescription
        self.fileExtension = fileExtension
        self.fileData = fileData
        self.fileURLString = fileURLString
    }
}

struct AudioNotePayload: Codable, Equatable {
    var audioFilename: String?
    var durationSeconds: Double = 8.0
    var waveformSamples: [Float] = [0.2, 0.5, 0.8, 0.4, 0.9, 0.6, 0.3, 0.7, 0.5]
    var audioData: Data? = nil
    
    init(audioFilename: String? = nil, durationSeconds: Double = 8.0, waveformSamples: [Float] = [0.2, 0.5, 0.8, 0.4, 0.9, 0.6, 0.3, 0.7, 0.5], audioData: Data? = nil) {
        self.audioFilename = audioFilename
        self.durationSeconds = durationSeconds
        self.waveformSamples = waveformSamples
        self.audioData = audioData
    }
}

struct MusicEmbedPayload: Codable, Equatable {
    var trackTitle: String
    var artist: String
    var albumArtworkFilename: String?
    var previewURLString: String?
    var appleMusicURLString: String?
    var artworkData: Data?
    var isAppleMusic: Bool = true
    
    init(
        trackTitle: String = "Favorite Song",
        artist: String = "Artist",
        albumArtworkFilename: String? = nil,
        previewURLString: String? = nil,
        appleMusicURLString: String? = nil,
        artworkData: Data? = nil,
        isAppleMusic: Bool = true
    ) {
        self.trackTitle = trackTitle
        self.artist = artist
        self.albumArtworkFilename = albumArtworkFilename
        self.previewURLString = previewURLString
        self.appleMusicURLString = appleMusicURLString
        self.artworkData = artworkData
        self.isAppleMusic = isAppleMusic
    }
}

// MARK: - Canvas Item Kind

enum CanvasItemKind: String, Codable, CaseIterable {
    case map
    case link
    case contact
    case emoji
    case text
    case photo
    case video
    case file
    case audioNote
    case musicEmbed
    
    // Legacy compatibility aliases
    case polaroidPhoto
    case friendAvatar
    case voiceNote
    case mapLocation
    case tapeLabel
    case musicTag
    case emojiSticker
}

// MARK: - Polymorphic Canvas Content

enum CanvasContent: Codable, Equatable {
    case map(MapPayload)
    case link(LinkPayload)
    case contact(ContactPayload)
    case emoji(EmojiPayload)
    case text(TextPayload)
    case photo(PhotoPayload)
    case video(VideoPayload)
    case file(FilePayload)
    case audioNote(AudioNotePayload)
    case musicEmbed(MusicEmbedPayload)
    
    var kind: CanvasItemKind {
        switch self {
        case .map: return .map
        case .link: return .link
        case .contact: return .contact
        case .emoji: return .emoji
        case .text: return .text
        case .photo: return .photo
        case .video: return .video
        case .file: return .file
        case .audioNote: return .audioNote
        case .musicEmbed: return .musicEmbed
        }
    }
}

// MARK: - Canvas Item

struct CanvasItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var position: CGPoint
    var size: CGSize
    var rotationDegrees: Double = 0.0
    var scale: CGFloat = 1.0
    var zIndex: Double = 1.0
    var tapeStyle: WashiTapeStyle = .none
    var borderWidth: CGFloat = 0.0
    var hasShadow: Bool = true
    var taggedFriendIDs: [UUID] = []
    
    /// Polymorphic content representing map, link, contact, emoji, text, photo, video, file, audio note, or music embed
    var content: CanvasContent
    
    // Convenience kind accessor
    var kind: CanvasItemKind {
        content.kind
    }
    
    // MARK: Primary Initializer
    init(
        id: UUID = UUID(),
        position: CGPoint,
        size: CGSize,
        rotationDegrees: Double = 0.0,
        scale: CGFloat = 1.0,
        zIndex: Double = 1.0,
        tapeStyle: WashiTapeStyle = .none,
        borderWidth: CGFloat = 0.0,
        hasShadow: Bool = true,
        taggedFriendIDs: [UUID] = [],
        content: CanvasContent
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.rotationDegrees = rotationDegrees
        self.scale = scale
        self.zIndex = zIndex
        self.tapeStyle = tapeStyle
        self.borderWidth = borderWidth
        self.hasShadow = hasShadow
        self.taggedFriendIDs = taggedFriendIDs
        self.content = content
    }
    
    // MARK: Legacy / Convenience Initializer
    init(
        id: UUID = UUID(),
        kind: CanvasItemKind,
        position: CGPoint,
        size: CGSize,
        rotationDegrees: Double = 0.0,
        scale: CGFloat = 1.0,
        zIndex: Double = 1.0,
        customImageFilename: String? = nil,
        text: String? = nil,
        subtitle: String? = nil,
        friendID: UUID? = nil,
        tapeStyle: WashiTapeStyle = .none,
        borderWidth: CGFloat = 0.0,
        hasShadow: Bool = true,
        stickerColorHex: String = "#F5EC87",
        voiceDurationSeconds: Double = 8.0,
        audioFilename: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        taggedFriendIDs: [UUID] = []
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.rotationDegrees = rotationDegrees
        self.scale = scale
        self.zIndex = zIndex
        self.tapeStyle = tapeStyle
        self.borderWidth = borderWidth
        self.hasShadow = hasShadow
        var resolvedTagged = taggedFriendIDs
        if let friendID = friendID, !resolvedTagged.contains(friendID) {
            resolvedTagged.append(friendID)
        }
        self.taggedFriendIDs = resolvedTagged
        
        switch kind {
        case .map, .mapLocation:
            self.content = .map(MapPayload(title: text ?? "Location", latitude: latitude ?? 40.8518, longitude: longitude ?? 14.2681))
        case .link:
            self.content = .link(LinkPayload(urlString: text ?? "https://apple.com", title: subtitle ?? "Link"))
        case .contact, .friendAvatar:
            self.content = .contact(ContactPayload(name: text ?? "Friend", friendID: friendID, subtitle: subtitle))
        case .emoji, .emojiSticker:
            self.content = .emoji(EmojiPayload(emoji: text ?? "✨"))
        case .text, .tapeLabel:
            self.content = .text(TextPayload(text: text ?? "Note", backgroundColorHex: stickerColorHex))
        case .photo, .polaroidPhoto:
            self.content = .photo(PhotoPayload(imageFilename: customImageFilename, caption: text))
        case .video:
            self.content = .video(VideoPayload())
        case .file:
            self.content = .file(FilePayload(filename: text ?? "Document.pdf"))
        case .audioNote, .voiceNote:
            self.content = .audioNote(AudioNotePayload(audioFilename: audioFilename, durationSeconds: voiceDurationSeconds))
        case .musicEmbed, .musicTag:
            self.content = .musicEmbed(MusicEmbedPayload(trackTitle: text ?? "Favorite Song", artist: subtitle ?? "Artist"))
        }
    }
    
    // MARK: Backward Compatibility Accessors
    var text: String? {
        get {
            switch content {
            case .text(let p): return p.text
            case .emoji(let p): return p.emoji
            case .map(let p): return p.title
            case .link(let p): return p.title
            case .contact(let p): return p.name
            case .photo(let p): return p.caption
            case .file(let p): return p.filename
            case .musicEmbed(let p): return p.trackTitle
            default: return nil
            }
        }
        set {
            guard let val = newValue else { return }
            switch content {
            case .text(var p): p.text = val; content = .text(p)
            case .emoji(var p): p.emoji = val; content = .emoji(p)
            case .map(var p): p.title = val; content = .map(p)
            case .link(var p): p.title = val; content = .link(p)
            case .contact(var p): p.name = val; content = .contact(p)
            case .photo(var p): p.caption = val; content = .photo(p)
            case .file(var p): p.filename = val; content = .file(p)
            case .musicEmbed(var p): p.trackTitle = val; content = .musicEmbed(p)
            default: break
            }
        }
    }
    
    var friendID: UUID? {
        if case .contact(let p) = content { return p.friendID }
        return nil
    }
    
    var latitude: Double? {
        if case .map(let p) = content { return p.latitude }
        return nil
    }
    
    var longitude: Double? {
        if case .map(let p) = content { return p.longitude }
        return nil
    }
    
    var audioFilename: String? {
        if case .audioNote(let p) = content { return p.audioFilename }
        return nil
    }
    
    var voiceDurationSeconds: Double {
        if case .audioNote(let p) = content { return p.durationSeconds }
        return 0.0
    }
}

// MARK: - Canvas Template

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
// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r, g, b, a: Double
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if hexSanitized.count == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}


