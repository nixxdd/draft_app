//
//  CanvasView.swift
//  draft_app
//

import SwiftUI
import Foundation
import PhotosUI
import Photos
import AVFoundation
import UniformTypeIdentifiers

enum CanvasActiveSheet: Identifiable {
    case newEmoji
    case editEmoji(CanvasItem)
    case textEditor(CanvasItem?)
    case editOther(CanvasItem)
    case voiceNoteRecorder
    case musicPicker
    case locationPicker(CanvasItem?)
    
    var id: String {
        switch self {
        case .newEmoji:
            return "newEmoji"
        case .editEmoji(let item):
            return "editEmoji-\(item.id.uuidString)"
        case .textEditor(let item):
            return "textEditor-\(item?.id.uuidString ?? "new")"
        case .editOther(let item):
            return "editOther-\(item.id.uuidString)"
        case .voiceNoteRecorder:
            return "voiceNoteRecorder"
        case .musicPicker:
            return "musicPicker"
        case .locationPicker(let item):
            return "locationPicker-\(item?.id.uuidString ?? "new")"
        }
    }
}

struct CanvasView: View {
    @Bindable var store: MemoryStore
    @State private var activeSheet: CanvasActiveSheet? = nil
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isShowingFilePicker: Bool = false
    
    // Drag-to-delete state
    @State private var draggedItem: CanvasItem? = nil
    @State private var isHoveringTrash: Bool = false
    
    // Clipboard feedback toast
    @State private var toastMessage: String? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            SketchTheme.backgroundGradient
                .ignoresSafeArea()
            
            if let card = store.selectedCard {
                CanvasItemsLayer(
                    store: store,
                    card: card,
                    isEditable: true,
                    onItemClick: { clickedItem in
                        handleItemClick(clickedItem)
                    },
                    onDragChanged: { item, currentPos in
                        if draggedItem?.id != item.id {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                draggedItem = item
                            }
                        }
                        
                        let inTrash = currentPos.y < 130 && abs(currentPos.x - 195) < 95
                        if inTrash != isHoveringTrash {
                            if inTrash {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHoveringTrash = inTrash
                            }
                        }
                    },
                    onDragEnded: { item, finalPos in
                        guard let finalPos = finalPos else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                draggedItem = nil
                                isHoveringTrash = false
                            }
                            return
                        }
                        
                        let inTrash = finalPos.y < 130 && abs(finalPos.x - 195) < 95
                        if inTrash {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                store.deleteItem(id: item.id)
                                draggedItem = nil
                                isHoveringTrash = false
                            }
                        } else {
                            var updated = item
                            updated.position = finalPos
                            store.updateItem(updated)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                draggedItem = nil
                                isHoveringTrash = false
                            }
                        }
                    }
                )
            }
            
            VStack {
                ZStack {
                    // Center Top Trash Zone - ONLY shows when dragging
                    if draggedItem != nil {
                        TrashDropZoneView(isHovered: isHoveringTrash)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.75).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .scale(scale: 0.75).combined(with: .opacity).combined(with: .move(edge: .top))
                                )
                            )
                    }
                    
                    HStack {
                        Spacer()
                        Button("Done") {
                            withAnimation(.spring(response: 0.9, dampingFraction: 0.9)) {
                                store.isEditingCard = false
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(SketchTheme.editPillGradient, in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                if let msg = toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.pink)
                        Text(msg)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }
                
                Spacer()
                
                HStack {
                    bottomToolbar
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .newEmoji:
                EmojiPickerView { selectedEmoji in
                    store.addItem(kind: .emoji, text: selectedEmoji)
                    activeSheet = nil
                }
                .presentationDetents([.height(380), .medium, .large])
                .presentationDragIndicator(.visible)
                
            case .editEmoji(let itemToEdit):
                EmojiPickerView { newEmoji in
                    var updated = itemToEdit
                    let fontSize: CGFloat
                    if case .emoji(let payload) = itemToEdit.content {
                        fontSize = payload.fontSize
                    } else {
                        fontSize = 52
                    }
                    updated.content = .emoji(EmojiPayload(emoji: newEmoji, fontSize: fontSize))
                    store.updateItem(updated)
                    activeSheet = nil
                }
                .presentationDetents([.height(380), .medium, .large])
                .presentationDragIndicator(.visible)
                
            case .textEditor(let itemToEdit):
                TextItemEditorSheet(
                    store: store,
                    initialItem: itemToEdit,
                    onSave: { newText, bgHex, textHex, newTaggedIDs in
                        if let existingItem = itemToEdit {
                            var updated = existingItem
                            let existingDesign: String
                            if case .text(let p) = existingItem.content {
                                existingDesign = p.fontDesign
                            } else {
                                existingDesign = "rounded"
                            }
                            updated.taggedFriendIDs = newTaggedIDs
                            updated.content = .text(TextPayload(
                                text: newText,
                                fontDesign: existingDesign,
                                textColorHex: textHex,
                                backgroundColorHex: bgHex
                            ))
                            store.updateItem(updated)
                        } else {
                            store.addItem(
                                content: .text(TextPayload(
                                    text: newText,
                                    fontDesign: "rounded",
                                    textColorHex: textHex,
                                    backgroundColorHex: bgHex
                                )),
                                taggedFriendIDs: newTaggedIDs
                            )
                        }
                        activeSheet = nil
                    },
                    onCancel: {
                        activeSheet = nil
                    },
                    onDelete: itemToEdit != nil ? {
                        if let item = itemToEdit {
                            store.deleteItem(id: item.id)
                        }
                        activeSheet = nil
                    } : nil
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                
            case .editOther(let itemToEdit):
                NavigationStack {
                    ElementContentEditorSheet(
                        item: itemToEdit,
                        store: store,
                        onSave: { updated in
                            store.updateItem(updated)
                            activeSheet = nil
                        },
                        onCancel: {
                            activeSheet = nil
                        },
                        onDelete: {
                            store.deleteItem(id: itemToEdit.id)
                            activeSheet = nil
                        }
                    )
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                
            case .voiceNoteRecorder:
                VoiceNoteRecorderSheet(
                    onSave: { audioData, duration, samples in
                        store.addItem(
                            content: .audioNote(AudioNotePayload(
                                durationSeconds: duration,
                                waveformSamples: samples,
                                audioData: audioData
                            )),
                            size: CGSize(width: 170, height: 56)
                        )
                        activeSheet = nil
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
                .presentationDetents([.height(490), .medium, .large])
                .presentationDragIndicator(.visible)
                
            case .musicPicker:
                MusicPickerSheet(
                    onSelect: { payload in
                        store.addItem(
                            content: .musicEmbed(payload),
                            size: CGSize(width: 220, height: 74)
                        )
                        activeSheet = nil
                        showToast("Added \(payload.trackTitle)")
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                
            case .locationPicker(let itemToEdit):
                let initialPayload: MapPayload? = {
                    if let item = itemToEdit, case .map(let p) = item.content {
                        return p
                    }
                    return nil
                }()
                LocationPickerSheet(
                    initialPayload: initialPayload,
                    card: store.selectedCard,
                    onSelect: { payload in
                        if let existing = itemToEdit {
                            var updated = existing
                            updated.content = .map(payload)
                            store.updateItem(updated)
                        } else {
                            store.addItem(
                                content: .map(payload),
                                size: CGSize(width: 150, height: 110)
                            )
                        }
                        activeSheet = nil
                        showToast("Added \(payload.title)")
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            let itemsToProcess = newItems
            selectedPhotoItems = []
            Task {
                await handlePickedMedia(itemsToProcess)
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handlePickedFiles(result)
        }
    }
    
    private func handleItemClick(_ item: CanvasItem) {
        switch item.content {
        case .text:
            activeSheet = .textEditor(item)
        default:
            activeSheet = .editOther(item)
        }
    }
    
    private func pasteFromClipboard() {
        Task {
            if let result = await ClipboardHelper.processClipboard() {
                await MainActor.run {
                    store.addItem(content: result.content, size: result.size)
                    showToast(result.message)
                }
            } else {
                await MainActor.run {
                    showToast("Clipboard is empty or unsupported")
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
  
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Paste Button
            Button {
                pasteFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            
            // Emoji Picker
            Button {
                activeSheet = .newEmoji
            } label: {
                Image(systemName: "face.smiling.inverse")
            }
            
            // Text Note Editor
            Button {
                activeSheet = .textEditor(nil)
            } label: {
                Image(systemName: "character.textbox")
            }
            
            // Photos Picker
            PhotosPicker(
                selection: $selectedPhotoItems,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo.badge.plus")
            }
            
            // More / Elements Menu
            Menu {
                Button {
                    pasteFromClipboard()
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }
                
                Divider()
                
                Button {
                    activeSheet = .musicPicker
                } label: {
                    Label("Apple Music", systemImage: "music.note")
                }
                
                Button {
                    activeSheet = .voiceNoteRecorder
                } label: {
                    Label("Voice Note", systemImage: "waveform")
                }
                
                Button {
                    activeSheet = .locationPicker(nil)
                } label: {
                    Label("Location", systemImage: "map")
                }
                
                Button {
                    store.addItem(content: .link(LinkPayload(urlString: "https://apple.com", title: "Apple", host: "apple.com")))
                } label: {
                    Label("Link", systemImage: "link")
                }
                
                Button {
                    store.addItem(content: .video(VideoPayload(durationSeconds: 15)))
                } label: {
                    Label("Video", systemImage: "video")
                }
                
                Button {
                    isShowingFilePicker = true
                } label: {
                    Label("File", systemImage: "doc")
                }
                
                Button {
                    store.addItem(content: .contact(ContactPayload(name: "Friend")))
                } label: {
                    Label("Contact", systemImage: "person.crop.circle")
                }
            } label: {
                Image(systemName: "plus.circle")
            }
        }
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
    
    private func handlePickedMedia(_ items: [PhotosPickerItem]) async {
        for (index, item) in items.enumerated() {
            let offsetPoint = CGPoint(x: 180 + CGFloat(index * 20), y: 260 + CGFloat(index * 20))
            
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) || $0.conforms(to: .video) }
            
            if isVideo {
                if let movieData = try? await item.loadTransferable(type: Data.self) {
                    let thumbData = await generateVideoThumbnail(from: movieData)
                    let duration = await getVideoDuration(from: movieData)
                    await MainActor.run {
                        store.addItem(
                            content: .video(VideoPayload(
                                durationSeconds: duration,
                                isMuted: true,
                                thumbnailData: thumbData
                            )),
                            size: CGSize(width: 170, height: 130),
                            position: offsetPoint
                        )
                    }
                } else {
                    await MainActor.run {
                        store.addItem(
                            content: .video(VideoPayload(durationSeconds: 15.0, isMuted: true)),
                            size: CGSize(width: 170, height: 130),
                            position: offsetPoint
                        )
                    }
                }
            } else {
                if let imageData = try? await item.loadTransferable(type: Data.self) {
                    var lat: Double? = nil
                    var lon: Double? = nil
                    var locName: String? = nil
                    if let coord = PhotoLocationHelper.extractCoordinates(from: imageData) {
                        lat = coord.latitude
                        lon = coord.longitude
                        let info = await PhotoLocationHelper.reverseGeocode(coordinate: coord)
                        locName = info.title
                    }
                    
                    await MainActor.run {
                        store.addItem(
                            content: .photo(PhotoPayload(
                                caption: locName,
                                isPolaroid: true,
                                imageData: imageData,
                                latitude: lat,
                                longitude: lon,
                                locationName: locName
                            )),
                            size: CGSize(width: 160, height: 180),
                            position: offsetPoint
                        )
                    }
                } else {
                    await MainActor.run {
                        store.addItem(
                            content: .photo(PhotoPayload(
                                caption: "New Memory",
                                isPolaroid: true
                            )),
                            size: CGSize(width: 160, height: 180),
                            position: offsetPoint
                        )
                    }
                }
            }
        }
    }
    
    private func generateVideoThumbnail(from videoData: Data) async -> Data? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        do {
            try videoData.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            let (imageRef, _) = try await generator.image(at: time)
            let image = UIImage(cgImage: imageRef)
            try? FileManager.default.removeItem(at: tempURL)
            return image.jpegData(compressionQuality: 0.8)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }
    
    private func getVideoDuration(from videoData: Data) async -> Double {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        do {
            try videoData.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            try? FileManager.default.removeItem(at: tempURL)
            return seconds.isFinite && seconds > 0 ? seconds : 15.0
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return 15.0
        }
    }
    
    private func handlePickedFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            for (index, url) in urls.enumerated() {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let filename = url.lastPathComponent
                let fileExtension = url.pathExtension.lowercased()
                
                let fileSizeDesc: String
                if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                    fileSizeDesc = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
                } else {
                    fileSizeDesc = "Document"
                }
                
                let fileData = try? Data(contentsOf: url)
                
                // Copy to local app sandbox directory to persist across sessions
                let localURL: URL? = {
                    guard let data = fileData else { return nil }
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
                    let dest = docs.appendingPathComponent("\(UUID().uuidString)_\(filename)")
                    try? data.write(to: dest)
                    return dest
                }()
                
                let offset = CGFloat(index * 24)
                let pos = CGPoint(x: 195 + (index % 2 == 0 ? -offset : offset), y: 320 + offset)
                
                store.addItem(
                    content: .file(FilePayload(
                        filename: filename,
                        fileSizeDescription: fileSizeDesc,
                        fileExtension: fileExtension,
                        fileData: fileData,
                        fileURLString: localURL?.absoluteString
                    )),
                    size: CGSize(width: 175, height: 60),
                    position: pos
                )
                
                showToast("Added \(filename)")
            }
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Trash Drop Zone (Center top, shows only when dragging)

struct TrashDropZoneView: View {
    var isHovered: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isHovered ? "trash.fill" : "trash")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isHovered ? .white : Color(red: 0.85, green: 0.2, blue: 0.2))
                .symbolEffect(.bounce, value: isHovered)
            
            Text(isHovered ? "Release to Delete" : "Drag here to delete")
                .font(.subheadline.bold())
                .foregroundStyle(isHovered ? .white : Color.primary)
        }
        .padding(.horizontal, isHovered ? 20 : 16)
        .padding(.vertical, isHovered ? 12 : 9)
        .background(
            isHovered ? Color.red : Color(.secondarySystemGroupedBackground),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .strokeBorder(isHovered ? Color.white.opacity(0.3) : Color.primary.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: isHovered ? Color.red.opacity(0.5) : Color.black.opacity(0.15), radius: isHovered ? 12 : 6, y: 3)
        .scaleEffect(isHovered ? 1.12 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered)
    }
}
