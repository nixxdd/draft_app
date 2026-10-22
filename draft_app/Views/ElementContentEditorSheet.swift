//
//  ElementContentEditorSheet.swift
//  draft_app
//

import SwiftUI
import AVFoundation

struct ElementContentEditorSheet: View {
    let item: CanvasItem
    let store: MemoryStore
    let onSave: (CanvasItem) -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var text1: String = ""
    @State private var text2: String = ""
    @State private var bool1: Bool = true
    @State private var number1: Double = 0.0
    @State private var mapLatitude: Double = 40.8518
    @State private var mapLongitude: Double = 14.2681
    @State private var showLocationPicker: Bool = false
    @State private var previewPlayer: AVAudioPlayer? = nil
    @State private var isPlayingPreview: Bool = false
    @State private var taggedFriendIDs: [UUID] = []
    
    init(item: CanvasItem, store: MemoryStore, onSave: @escaping (CanvasItem) -> Void, onCancel: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.store = store
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        _taggedFriendIDs = State(initialValue: item.taggedFriendIDs)
        
        switch item.content {
        case .photo(let payload):
            _text1 = State(initialValue: payload.caption ?? "")
            _bool1 = State(initialValue: payload.isPolaroid)
        case .link(let payload):
            _text1 = State(initialValue: payload.title)
            _text2 = State(initialValue: payload.urlString)
        case .map(let payload):
            _text1 = State(initialValue: payload.title)
            _mapLatitude = State(initialValue: payload.latitude)
            _mapLongitude = State(initialValue: payload.longitude)
        case .contact(let payload):
            _text1 = State(initialValue: payload.name)
            _text2 = State(initialValue: payload.subtitle ?? "")
        case .musicEmbed(let payload):
            _text1 = State(initialValue: payload.trackTitle)
            _text2 = State(initialValue: payload.artist)
        case .file(let payload):
            _text1 = State(initialValue: payload.filename)
            _text2 = State(initialValue: payload.fileSizeDescription)
        case .video(let payload):
            _bool1 = State(initialValue: payload.isMuted)
        case .text(let payload):
            _text1 = State(initialValue: payload.text)
        case .audioNote(let payload):
            _number1 = State(initialValue: payload.durationSeconds)
        case .emoji(let payload):
            _text1 = State(initialValue: payload.emoji)
        }
    }
    
    private var navigationTitle: String {
        switch item.content {
        case .photo: return "Edit Photo"
        case .link: return "Edit Link"
        case .map: return "Edit Location & Tag"
        case .contact: return "Edit Contact & Tag"
        case .musicEmbed: return "Edit Music & Tag"
        case .file: return "Edit Document & Tag"
        case .video: return "Edit Video & Tag"
        case .text: return "Edit Note & Tag"
        case .audioNote: return "Edit Voice Note & Tag"
        case .emoji: return "Edit Sticker & Tag"
        }
    }
    
    private func formattedBrowserURL(_ input: String) -> URL? {
        var str = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !str.isEmpty else { return nil }
        if !str.lowercased().hasPrefix("http://") && !str.lowercased().hasPrefix("https://") {
            str = "https://" + str
        }
        return URL(string: str)
    }
    
    private func toggleAudioPreview(data: Data?) {
        guard let data = data else { return }
        if isPlayingPreview {
            previewPlayer?.stop()
            isPlayingPreview = false
        } else {
            do {
                previewPlayer = try AVAudioPlayer(data: data)
                previewPlayer?.play()
                isPlayingPreview = true
            } catch {
                isPlayingPreview = false
            }
        }
    }
    
    private func saveChanges() {
        previewPlayer?.stop()
        var updated = item
        updated.taggedFriendIDs = taggedFriendIDs
        
        switch item.content {
        case .photo(var payload):
            let trimmed = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.caption = trimmed.isEmpty ? nil : trimmed
            payload.isPolaroid = bool1
            updated.content = .photo(payload)
        case .link(var payload):
            let trimmedTitle = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.title = trimmedTitle.isEmpty ? "Link" : trimmedTitle
            payload.urlString = text2.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: payload.urlString), let host = url.host {
                payload.host = host
            }
            updated.content = .link(payload)
        case .map(var payload):
            let trimmed = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.title = trimmed.isEmpty ? "Location" : trimmed
            payload.latitude = mapLatitude
            payload.longitude = mapLongitude
            updated.content = .map(payload)
        case .contact(var payload):
            let trimmedName = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSub = text2.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.name = trimmedName.isEmpty ? "Friend" : trimmedName
            payload.subtitle = trimmedSub.isEmpty ? nil : trimmedSub
            updated.content = .contact(payload)
        case .musicEmbed(var payload):
            let trimmedTrack = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedArtist = text2.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.trackTitle = trimmedTrack.isEmpty ? "Favorite Song" : trimmedTrack
            payload.artist = trimmedArtist.isEmpty ? "Artist" : trimmedArtist
            updated.content = .musicEmbed(payload)
        case .file(var payload):
            let trimmedName = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSize = text2.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.filename = trimmedName.isEmpty ? "Document" : trimmedName
            payload.fileSizeDescription = trimmedSize.isEmpty ? "1.0 MB" : trimmedSize
            updated.content = .file(payload)
        case .video(var payload):
            payload.isMuted = bool1
            updated.content = .video(payload)
        case .text(var payload):
            let trimmed = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            payload.text = trimmed.isEmpty ? "Note" : trimmed
            updated.content = .text(payload)
        case .audioNote:
            // Audio payload remains intact, tags updated
            break
        case .emoji:
            // Emoji remains intact, tags updated
            break
        }
        onSave(updated)
        dismiss()
    }
    
    var body: some View {
        Form {
            switch item.content {
            case .photo:
                Section("Photo Details") {
                    TextField("Caption", text: $text1)
                    Toggle("Polaroid Style", isOn: $bool1)
                }
            case .link:
                Section("Link Details") {
                    TextField("Title", text: $text1)
                    TextField("URL", text: $text2)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                if let url = formattedBrowserURL(text2) {
                    Section {
                        Link(destination: url) {
                            HStack {
                                Label("Open in Browser", systemImage: "safari")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            case .map:
                Section("Location") {
                    TextField("Location Title", text: $text1)
                    
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack {
                            Label("Adjust Map Pin", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(String(format: "%.3f, %.3f", mapLatitude, mapLongitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            case .contact:
                Section("Contact Info") {
                    TextField("Name", text: $text1)
                    TextField("Subtitle", text: $text2)
                }
                if !store.friends.isEmpty {
                    Section("Select Friend") {
                        ForEach(store.friends) { friend in
                            Button {
                                text1 = friend.name
                                text2 = "Friend"
                            } label: {
                                HStack {
                                    Text(friend.name)
                                    Spacer()
                                    if text1 == friend.name {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            case .musicEmbed:
                Section("Track Details") {
                    TextField("Song Title", text: $text1)
                    TextField("Artist", text: $text2)
                }
            case .file:
                Section("File Details") {
                    TextField("Filename", text: $text1)
                    TextField("File Size", text: $text2)
                }
            case .video:
                Section("Video Sound") {
                    Toggle(isOn: $bool1) {
                        Label(
                            bool1 ? "Mute Video" : "Audio Enabled",
                            systemImage: bool1 ? "speaker.slash.fill" : "speaker.wave.2.fill"
                        )
                    }
                }
            case .text:
                Section("Note Text") {
                    TextField("Text", text: $text1, axis: .vertical)
                        .lineLimit(3...6)
                }
            case .audioNote(let payload):
                Section("Voice Note") {
                    HStack {
                        Label(String(format: "%.1fs Voice Note", payload.durationSeconds), systemImage: "waveform")
                            .font(.headline)
                        Spacer()
                        if let data = payload.audioData {
                            Button {
                                toggleAudioPreview(data: data)
                            } label: {
                                Image(systemName: isPlayingPreview ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            case .emoji(let payload):
                Section("Sticker") {
                    HStack {
                        Text(payload.emoji)
                            .font(.system(size: 40))
                        Spacer()
                        Text("Sticker Stamp")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Tagged Friends Section (Available for EVERY element!)
            Section {
                if store.friends.isEmpty {
                    Text("No friends added yet. Open Friends Cosmos from the top bar to add from your Contacts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.friends) { friend in
                        let isTagged = taggedFriendIDs.contains(friend.id)
                        Button {
                            if isTagged {
                                taggedFriendIDs.removeAll { $0 == friend.id }
                            } else {
                                taggedFriendIDs.append(friend.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                FriendAvatarView(friend: friend, size: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    if !friend.birthday.isEmpty {
                                        Text("🎂 \(friend.birthday)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: isTagged ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isTagged ? Color.purple : Color.secondary.opacity(0.3))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                HStack {
                    Text("Tag Friends With This Element")
                    Spacer()
                    if !taggedFriendIDs.isEmpty {
                        Text("\(taggedFriendIDs.count) tagged")
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                    }
                }
            } footer: {
                Text("Friends tagged on this element will grow their bubble in the Friends screen!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button(role: .destructive) {
                    previewPlayer?.stop()
                    onDelete()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("Delete Element")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    previewPlayer?.stop()
                    onCancel()
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                initialPayload: MapPayload(
                    title: text1.isEmpty ? "Location" : text1,
                    latitude: mapLatitude,
                    longitude: mapLongitude
                ),
                card: store.selectedCard,
                onSelect: { payload in
                    mapLatitude = payload.latitude
                    mapLongitude = payload.longitude
                    if text1.isEmpty || text1 == "Location" {
                        text1 = payload.title
                    }
                    showLocationPicker = false
                },
                onCancel: {
                    showLocationPicker = false
                }
            )
        }
        .onDisappear {
            previewPlayer?.stop()
        }
    }
}
