//
//  MusicPickerSheet.swift
//  draft_app
//

import SwiftUI
import AVFoundation

struct FeaturedTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let appleMusicURL: String
    let previewURL: String?
    let gradientColors: [Color]
}

struct MusicPickerSheet: View {
    var onSelect: (MusicEmbedPayload) -> Void
    var onCancel: () -> Void
    
    @State private var pastedLink: String = ""
    @State private var isResolving: Bool = false
    @State private var resolvedPayload: MusicEmbedPayload? = nil
    @State private var statusMessage: String? = nil
    
    // Custom entry
    @State private var customTitle: String = ""
    @State private var customArtist: String = ""
    
    // Featured songs
    private let featuredTracks: [FeaturedTrack] = [
        FeaturedTrack(
            title: "Espresso",
            artist: "Sabrina Carpenter",
            appleMusicURL: "https://music.apple.com/us/album/espresso/1739566914?i=1739566922",
            previewURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/91/97/bb/9197bb75-9e6b-a2ea-9e0a-0c7f2127ef3e/mzaf_17208107936166795493.plus.aac.p.m4a",
            gradientColors: [Color(hex: "#C68B59") ?? .brown, Color(hex: "#8B5A2B") ?? .black]
        ),
        FeaturedTrack(
            title: "Birds of a Feather",
            artist: "Billie Eilish",
            appleMusicURL: "https://music.apple.com/us/album/birds-of-a-feather/1739692790",
            previewURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/65/59/2e/65592ec4-5f40-d9c9-6f96-29177114b74a/mzaf_4721447937402375836.plus.aac.p.m4a",
            gradientColors: [Color(hex: "#4A7C59") ?? .green, Color(hex: "#203A2B") ?? .black]
        ),
        FeaturedTrack(
            title: "Cruel Summer",
            artist: "Taylor Swift",
            appleMusicURL: "https://music.apple.com/us/album/cruel-summer/1476140504?i=1476140506",
            previewURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/44/78/3f/44783f9c-722a-f97e-d0a8-bcf6b1c67d71/mzaf_8147648356976690412.plus.aac.p.m4a",
            gradientColors: [Color(hex: "#E07A5F") ?? .orange, Color(hex: "#3D405B") ?? .purple]
        ),
        FeaturedTrack(
            title: "Blinding Lights",
            artist: "The Weeknd",
            appleMusicURL: "https://music.apple.com/us/album/blinding-lights/1499378108?i=1499378607",
            previewURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/b8/b5/02/b8b50290-7cb5-eb65-c9c0-bb82ee33144a/mzaf_10497525381048684497.plus.aac.p.m4a",
            gradientColors: [Color(hex: "#D62828") ?? .red, Color(hex: "#003049") ?? .black]
        ),
        FeaturedTrack(
            title: "Good Luck, Babe!",
            artist: "Chappell Roan",
            appleMusicURL: "https://music.apple.com/us/album/good-luck-babe/1739229767?i=1739229774",
            previewURL: nil,
            gradientColors: [Color(hex: "#FA8072") ?? .pink, Color(hex: "#FF69B4") ?? .purple]
        ),
        FeaturedTrack(
            title: "Get Lucky",
            artist: "Daft Punk feat. Pharrell Williams",
            appleMusicURL: "https://music.apple.com/us/album/get-lucky-feat-pharrell-williams-nile-rodgers/636986427?i=636986438",
            previewURL: nil,
            gradientColors: [Color(hex: "#F4A261") ?? .orange, Color(hex: "#264653") ?? .blue]
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Apple Music Link Paste
                Section("Apple Music Link") {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(.pink)
                        TextField("Paste https://music.apple.com link", text: $pastedLink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if !pastedLink.isEmpty {
                            Button {
                                pastedLink = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                                .font(.subheadline.bold())
                        }
                        
                        Spacer()
                        
                        if isResolving {
                            ProgressView()
                                .padding(.horizontal, 8)
                        } else {
                            Button("Add Track") {
                                resolveAndInsert(pastedLink)
                            }
                            .font(.subheadline.bold())
                            .disabled(pastedLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    if let msg = statusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }
                
                // Section 2: Popular Hits
                Section("Featured Apple Music") {
                    ForEach(featuredTracks) { track in
                        Button {
                            insertTrack(track)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: track.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "apple.logo")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white.opacity(0.85))
                                    }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(track.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(track.artist)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                }
                
                // Section 3: Custom Track
                Section("Custom Song") {
                    TextField("Song Title", text: $customTitle)
                    TextField("Artist", text: $customArtist)
                    
                    Button {
                        let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let artist = customArtist.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        onSelect(MusicEmbedPayload(
                            trackTitle: title,
                            artist: artist.isEmpty ? "Artist" : artist,
                            isAppleMusic: true
                        ))
                    } label: {
                        Text("Add Custom Song")
                            .font(.subheadline.bold())
                    }
                    .disabled(customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Insert Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                // Pre-check clipboard for Apple Music link
                if let str = UIPasteboard.general.string, str.contains("music.apple.com") {
                    pastedLink = str.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let str = UIPasteboard.general.string {
            pastedLink = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if pastedLink.contains("music.apple.com") {
                resolveAndInsert(pastedLink)
            }
        } else {
            statusMessage = "No text found on clipboard."
        }
    }
    
    private func resolveAndInsert(_ link: String) {
        let clean = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        isResolving = true
        statusMessage = "Fetching track details..."
        
        Task {
            let payload = await ClipboardHelper.resolveAppleMusicLink(clean)
            await MainActor.run {
                isResolving = false
                onSelect(payload)
            }
        }
    }
    
    private func insertTrack(_ track: FeaturedTrack) {
        onSelect(MusicEmbedPayload(
            trackTitle: track.title,
            artist: track.artist,
            previewURLString: track.previewURL,
            appleMusicURLString: track.appleMusicURL,
            isAppleMusic: true
        ))
    }
}
