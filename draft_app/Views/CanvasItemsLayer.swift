//
//  CanvasItemsLayer.swift
//  draft_app
//

import SwiftUI
import MapKit
import AVKit
import QuickLook

struct CanvasItemsLayer: View {
    @Bindable var store: MemoryStore
    let card: MemoryCard
    var isEditable: Bool
    var isThumbnail: Bool = false
    var onItemClick: ((CanvasItem) -> Void)? = nil
    var onDragChanged: ((CanvasItem, CGPoint) -> Void)? = nil
    var onDragEnded: ((CanvasItem, CGPoint?) -> Void)? = nil

    let fullCanvasSize = CGSize(width: 390, height: 720)
    
    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / fullCanvasSize.width
            let scaleY = geo.size.height / fullCanvasSize.height
            // Scale nicely to fit thumbnail or main canvas
            let scale = isEditable ? 1.0 : (isThumbnail ? scaleX : min(scaleX, scaleY))

            ZStack {
                ForEach(card.items) { item in
                    if isThumbnail {
                        thumbnailItemVisual(item)
                            .rotationEffect(.degrees(item.rotationDegrees))
                            .position(item.position)
                    } else {
                        DraggableCanvasItem(
                            store: store,
                            item: item,
                            isEditable: isEditable,
                            onItemClick: onItemClick,
                            onDragChanged: onDragChanged,
                            onDragEnded: onDragEnded
                        )
                    }
                }
            }
            .frame(width: fullCanvasSize.width, height: fullCanvasSize.height)
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    @ViewBuilder
    private func thumbnailItemVisual(_ item: CanvasItem) -> some View {
        switch item.content {
        case .map(let payload):
            // Lightweight map preview for thumbnail without heavy MapKit instance
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "#A8DADC") ?? .teal, Color(hex: "#457B9D") ?? .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.red)
                        .shadow(radius: 2)
                }
                .frame(width: max(item.size.width, 140), height: max(item.size.height - 30, 80))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(payload.title)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#1C1C1E") ?? .black)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: max(item.size.width, 140))
                .background(.white)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            
        case .video(let payload):
            // Video preview without AVPlayer overhead
            ZStack {
                if let data = payload.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: item.size.width, height: item.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#2C2C2E") ?? .gray, Color(hex: "#1C1C1E") ?? .black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: item.size.width, height: item.size.height)
                }
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 4)
            }
            .frame(width: item.size.width, height: item.size.height)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            
        default:
            DraggableCanvasItem(store: store, item: item, isEditable: false)
                .allowsHitTesting(false)
        }
    }
}

struct DraggableCanvasItem: View {
    @Bindable var store: MemoryStore
    let item: CanvasItem
    var isEditable: Bool
    var onItemClick: ((CanvasItem) -> Void)? = nil
    var onDragChanged: ((CanvasItem, CGPoint) -> Void)? = nil
    var onDragEnded: ((CanvasItem, CGPoint?) -> Void)? = nil
    
    @State private var dragOffset: CGSize = .zero
    @State private var quickLookURL: URL? = nil
    
    var body: some View {
        itemVisual
            .overlay(alignment: .bottomTrailing) {
                if !item.taggedFriendIDs.isEmpty {
                    friendTagsBadge
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditable {
                    onItemClick?(item)
                } else if case .audioNote = item.content {
                    store.toggleVoiceNotePlayback(for: item)
                } else if case .musicEmbed = item.content {
                    store.toggleMusicPlayback(for: item)
                } else if case .video = item.content {
                    store.toggleVideoPlayback(for: item)
                } else if case .file(let payload) = item.content {
                    previewFile(payload)
                } else if case .link(let payload) = item.content {
                    openLinkInBrowser(payload)
                }
            }
            .contextMenu {
                if isEditable {
                    Button {
                        onItemClick?(item)
                    } label: {
                        Label("Edit & Tag Friends", systemImage: "person.crop.circle.badge.plus")
                    }
                }
            }
            .quickLookPreview($quickLookURL)
            .rotationEffect(.degrees(item.rotationDegrees))
            .position(
                x: item.position.x + dragOffset.width,
                y: item.position.y + dragOffset.height
            )
            .gesture(
                isEditable ?
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        dragOffset = value.translation
                        let currentPos = CGPoint(
                            x: item.position.x + value.translation.width,
                            y: item.position.y + value.translation.height
                        )
                        onDragChanged?(item, currentPos)
                    }
                    .onEnded { value in
                        let distance = hypot(value.translation.width, value.translation.height)
                        if distance < 4 {
                            dragOffset = .zero
                            onDragEnded?(item, nil)
                            if isEditable {
                                onItemClick?(item)
                            } else if case .audioNote = item.content {
                                store.toggleVoiceNotePlayback(for: item)
                            } else if case .musicEmbed = item.content {
                                store.toggleMusicPlayback(for: item)
                            } else if case .video = item.content {
                                store.toggleVideoPlayback(for: item)
                            } else if case .file(let payload) = item.content {
                                previewFile(payload)
                            } else if case .link(let payload) = item.content {
                                openLinkInBrowser(payload)
                            }
                        } else {
                            let finalPos = CGPoint(
                                x: item.position.x + value.translation.width,
                                y: item.position.y + value.translation.height
                            )
                            dragOffset = .zero
                            if let onDragEnded = onDragEnded {
                                onDragEnded(item, finalPos)
                            } else {
                                var updated = item
                                updated.position = finalPos
                                store.updateItem(updated)
                            }
                        }
                    }
                : nil
            )
    }
    
    private var friendTagsBadge: some View {
        HStack(spacing: -6) {
            ForEach(item.taggedFriendIDs.prefix(3), id: \.self) { friendID in
                if let friend = store.friends.first(where: { $0.id == friendID }) {
                    FriendAvatarView(friend: friend, size: 20)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                }
            }
            if item.taggedFriendIDs.count > 3 {
                Text("+\(item.taggedFriendIDs.count - 3)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.black.opacity(0.7), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
            }
        }
        .padding(3)
        .offset(x: 4, y: 4)
    }
    
    @ViewBuilder
    private var itemVisual: some View {
        switch item.content {
        case .photo(let payload):
            VStack(spacing: 6) {
                if let data = payload.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(item.size.width - (payload.isPolaroid ? 16 : 8), 60),
                               height: max(item.size.height - (payload.caption != nil ? 44 : (payload.isPolaroid ? 16 : 8)), 60))
                        .clipped()
                        .cornerRadius(payload.isPolaroid ? 4 : 8)
                } else if let filename = payload.imageFilename, let uiImage = UIImage(named: filename) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(item.size.width - (payload.isPolaroid ? 16 : 8), 60),
                               height: max(item.size.height - (payload.caption != nil ? 44 : (payload.isPolaroid ? 16 : 8)), 60))
                        .clipped()
                        .cornerRadius(payload.isPolaroid ? 4 : 8)
                } else {
                    RoundedRectangle(cornerRadius: payload.isPolaroid ? 4 : 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: max(item.size.width - (payload.isPolaroid ? 16 : 8), 60),
                               height: max(item.size.height - (payload.caption != nil ? 44 : (payload.isPolaroid ? 16 : 8)), 60))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                }
                if let caption = payload.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(payload.isPolaroid ? 8 : 4)
            .background(payload.isPolaroid ? Color.white : Color.clear)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 4, y: 6)
            
        case .video(let payload):
            let isPlaying = store.playingVideoItemID == item.id
            ZStack {
                if isPlaying, let player = store.videoPlayer {
                    VideoPlayer(player: player)
                        .frame(width: item.size.width, height: item.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    if let data = payload.thumbnailData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: item.size.width, height: item.size.height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#2C2C2E") ?? .gray, Color(hex: "#1C1C1E") ?? .black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: item.size.width, height: item.size.height)
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(radius: 4)
                }
                
                // Mute / sound status indicator badge in top corner
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: payload.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.65), in: Circle())
                    }
                    .padding(8)
                    Spacer()
                }
            }
            .frame(width: item.size.width, height: item.size.height)
            .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
            
        case .text(let payload):
            Text(payload.text)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: payload.textColorHex) ?? .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: payload.backgroundColorHex) ?? SketchTheme.yellowStickerColor)
                .shadow(radius: 2)
                
        case .emoji(let payload):
            Text(payload.emoji)
                .font(.system(size: payload.fontSize))
                .padding(10)
                .background(.white.opacity(0.9), in: Circle())
                .shadow(radius: 3)
                
        case .map(let payload):
            VStack(spacing: 0) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: payload.latitude, longitude: payload.longitude),
                    span: MKCoordinateSpan(latitudeDelta: payload.zoom, longitudeDelta: payload.zoom)
                ))) {
                    Marker(payload.title, coordinate: CLLocationCoordinate2D(latitude: payload.latitude, longitude: payload.longitude))
                        .tint(.red)
                }
                .disabled(true)
                .frame(width: max(item.size.width, 140), height: max(item.size.height - 30, 80))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(payload.title)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#1C1C1E") ?? .black)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: max(item.size.width, 140))
                .background(.white)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                
        case .link(let payload):
            HStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    if let host = payload.host {
                        Text(host)
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.35))
                    }
                }
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "#007AFF") ?? .blue)
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 3)
            
        case .contact(let payload):
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                    if let subtitle = payload.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white, in: Capsule())
            .shadow(radius: 3)
            
        case .file(let payload):
            let ext = payload.fileExtension.lowercased()
            let iconName = fileIconName(for: ext)
            let iconColor = fileIconColor(for: ext)
            
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.filename)
                        .font(.caption.bold())
                        .foregroundStyle(Color.black)
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Text(payload.fileSizeDescription)
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.35))
                        
                        if !ext.isEmpty {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(Color(white: 0.5))
                            Text(ext.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(iconColor)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(iconColor.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            
        case .audioNote(let payload):
            let isPlaying = store.playingVoiceItemID == item.id
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(isPlaying ? Color.red : SketchTheme.waveformPurple)
                
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isPlaying ? Color.red : SketchTheme.waveformPurple)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                
                Text("\(Int(payload.durationSeconds))s")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.15))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isPlaying ? Color.red.opacity(0.4) : Color.purple.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: isPlaying ? Color.red.opacity(0.35) : Color.black.opacity(0.12), radius: isPlaying ? 8 : 4, y: 2)
            .scaleEffect(isPlaying ? 1.06 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPlaying)
            
        case .musicEmbed(let payload):
            let isPlaying = store.playingMusicItemID == item.id
            HStack(spacing: 10) {
                // Album artwork or Apple Music gradient
                Group {
                    if let data = payload.artworkData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "#FC3C44") ?? .pink, Color(hex: "#D62828") ?? .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Track Info & Apple Music badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(payload.trackTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        if payload.isAppleMusic {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color(hex: "#FC3C44") ?? .pink)
                        }
                        Text(payload.artist)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(white: 0.75))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Play / Pause / Equalizer Button
                HStack(spacing: 6) {
                    if isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<3) { idx in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color(hex: "#FC3C44") ?? .pink)
                                    .frame(width: 2.5, height: CGFloat([12, 18, 14][idx]))
                            }
                        }
                    }
                    
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "#FC3C44") ?? .pink)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 220, height: 60)
            .background(Color(hex: "#1C1C1E") ?? Color.black, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isPlaying ? (Color(hex: "#FC3C44") ?? .pink).opacity(0.6) : Color.white.opacity(0.14), lineWidth: 1.5)
            )
            .shadow(color: isPlaying ? (Color(hex: "#FC3C44") ?? .pink).opacity(0.35) : Color.black.opacity(0.25), radius: isPlaying ? 8 : 4, y: 2)
            .scaleEffect(isPlaying ? 1.04 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPlaying)
        }
    }
    
    private func fileIconName(for ext: String) -> String {
        switch ext {
        case "pdf": return "doc.text.fill"
        case "zip", "rar", "7z", "tar", "gz": return "doc.zipper"
        case "png", "jpg", "jpeg", "heic", "gif", "svg": return "photo.fill"
        case "mp3", "m4a", "wav", "aac", "flac": return "waveform"
        case "mp4", "mov", "m4v", "avi", "mkv": return "film.fill"
        case "doc", "docx", "pages", "txt", "rtf", "md": return "doc.text.fill"
        case "xls", "xlsx", "numbers", "csv": return "tablecells.fill"
        case "ppt", "pptx", "key": return "doc.richtext.fill"
        default: return "doc.fill"
        }
    }
    
    private func fileIconColor(for ext: String) -> Color {
        switch ext {
        case "pdf": return Color(hex: "#E63946") ?? .red
        case "zip", "rar", "7z", "tar", "gz": return Color(hex: "#7209B7") ?? .purple
        case "png", "jpg", "jpeg", "heic", "gif", "svg": return Color(hex: "#2A9D8F") ?? .teal
        case "mp3", "m4a", "wav", "aac", "flac": return Color(hex: "#E76F51") ?? .orange
        case "mp4", "mov", "m4v", "avi", "mkv": return Color(hex: "#4361EE") ?? .blue
        case "doc", "docx", "pages", "txt", "rtf", "md": return Color(hex: "#1D3557") ?? .blue
        case "xls", "xlsx", "numbers", "csv": return Color(hex: "#2B9348") ?? .green
        case "ppt", "pptx", "key": return Color(hex: "#F77F00") ?? .orange
        default: return Color(hex: "#E76F51") ?? .orange
        }
    }
    
    private func previewFile(_ payload: FilePayload) {
        if let urlStr = payload.fileURLString, let u = URL(string: urlStr), FileManager.default.fileExists(atPath: u.path) {
            quickLookURL = u
            return
        }
        if let data = payload.fileData {
            let tempDir = FileManager.default.temporaryDirectory
            let safeName = payload.filename.isEmpty ? "document.\(payload.fileExtension)" : payload.filename
            let tempURL = tempDir.appendingPathComponent(safeName)
            try? data.write(to: tempURL)
            quickLookURL = tempURL
            return
        }
    }
    
    private func openLinkInBrowser(_ payload: LinkPayload) {
        var str = payload.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !str.isEmpty else { return }
        if !str.lowercased().hasPrefix("http://") && !str.lowercased().hasPrefix("https://") {
            str = "https://" + str
        }
        if let url = URL(string: str) {
            UIApplication.shared.open(url)
        }
    }
}
