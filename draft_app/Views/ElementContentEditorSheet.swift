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
    @State private var previewPlayer: AVAudioPlayer? = nil
    @State private var isPlayingPreview = false
    
    init(item: CanvasItem, store: MemoryStore, onSave: @escaping (CanvasItem) -> Void, onCancel: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.store = store
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        
        switch item.content {
        case .photo(let payload):
            _text1 = State(initialValue: payload.caption ?? "")
            _bool1 = State(initialValue: payload.isPolaroid)
        case .link(let payload):
            _text1 = State(initialValue: payload.title)
            _text2 = State(initialValue: payload.urlString)
        case .map(let payload):
            _text1 = State(initialValue: payload.title)
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
        default:
            break
        }
    }
    
    private var navigationTitle: String {
        switch item.content {
        case .photo: return "Edit Photo"
        case .link: return "Edit Link"
        case .map: return "Edit Location"
        case .contact: return "Edit Contact"
        case .musicEmbed: return "Edit Music"
        case .file: return "Edit Document"
        case .video: return "Edit Video"
        default: return "Edit Element"
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
    
    private func saveChanges() {
        var updated = item
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
        default:
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
            default:
                EmptyView()
            }
            
            Section {
                Button(role: .destructive) {
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
    }
}
