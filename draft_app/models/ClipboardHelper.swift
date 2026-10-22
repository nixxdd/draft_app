//
//  ClipboardHelper.swift
//  draft_app
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardHelper {
    
    struct PastedResult {
        let content: CanvasContent
        let size: CGSize
        let message: String
    }
    
    @MainActor
    static func processClipboard() async -> PastedResult? {
        let pasteboard = UIPasteboard.general
        
        // 1. Check for Photo / Image
        if let image = pasteboard.image, let data = image.jpegData(compressionQuality: 0.85) {
            let photoPayload = PhotoPayload(
                caption: nil,
                isPolaroid: true,
                imageData: data
            )
            return PastedResult(
                content: .photo(photoPayload),
                size: CGSize(width: 160, height: 180),
                message: "Pasted Photo from Clipboard"
            )
        }
        
        if let imageData = pasteboard.data(forPasteboardType: UTType.image.identifier) ??
                          pasteboard.data(forPasteboardType: UTType.png.identifier) ??
                          pasteboard.data(forPasteboardType: UTType.jpeg.identifier) {
            let photoPayload = PhotoPayload(
                caption: nil,
                isPolaroid: true,
                imageData: imageData
            )
            return PastedResult(
                content: .photo(photoPayload),
                size: CGSize(width: 160, height: 180),
                message: "Pasted Photo from Clipboard"
            )
        }
        
        // 2. Check for Audio / Voice Note
        let audioTypes = [
            UTType.audio.identifier,
            UTType.mp3.identifier,
            UTType.mpeg4Audio.identifier,
            "com.apple.m4a-audio",
            "public.audio"
        ]
        for type in audioTypes {
            if let audioData = pasteboard.data(forPasteboardType: type) {
                let notePayload = AudioNotePayload(
                    durationSeconds: 10.0,
                    waveformSamples: [0.3, 0.6, 0.9, 0.4, 0.8, 0.5, 0.7, 0.4],
                    audioData: audioData
                )
                return PastedResult(
                    content: .audioNote(notePayload),
                    size: CGSize(width: 170, height: 56),
                    message: "Pasted Voice Note from Clipboard"
                )
            }
        }
        
        // 3. Check for String or URL
        var textCandidate = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        if textCandidate == nil || textCandidate?.isEmpty == true {
            if let url = pasteboard.url {
                textCandidate = url.absoluteString
            }
        }
        
        if let text = textCandidate, !text.isEmpty {
            // Check if it's an Apple Music Link
            if text.contains("music.apple.com") {
                let musicPayload = await resolveAppleMusicLink(text)
                return PastedResult(
                    content: .musicEmbed(musicPayload),
                    size: CGSize(width: 220, height: 74),
                    message: "Pasted Apple Music: \(musicPayload.trackTitle)"
                )
            }
            
            // Check if it's a general web link
            if text.hasPrefix("http://") || text.hasPrefix("https://") || text.hasPrefix("www.") {
                let urlString = text.hasPrefix("www.") ? "https://" + text : text
                let host = URL(string: urlString)?.host ?? "Link"
                let cleanHost = host.replacingOccurrences(of: "www.", with: "")
                let linkPayload = LinkPayload(
                    urlString: urlString,
                    title: cleanHost.capitalized,
                    host: cleanHost
                )
                return PastedResult(
                    content: .link(linkPayload),
                    size: CGSize(width: 180, height: 75),
                    message: "Pasted Link (\(cleanHost))"
                )
            }
            
            // Check if single emoji or emoji-only
            if isSingleEmoji(text) {
                return PastedResult(
                    content: .emoji(EmojiPayload(emoji: text, fontSize: 52)),
                    size: CGSize(width: 80, height: 80),
                    message: "Pasted Emoji Sticker"
                )
            }
            
            // Plain text note
            return PastedResult(
                content: .text(TextPayload(text: text)),
                size: CGSize(width: 160, height: 90),
                message: "Pasted Text Note"
            )
        }
        
        // 4. Check for File / Document
        let docTypes = [
            UTType.pdf.identifier,
            UTType.compositeContent.identifier,
            "public.data"
        ]
        for type in docTypes {
            if let _ = pasteboard.data(forPasteboardType: type) {
                return PastedResult(
                    content: .file(FilePayload(filename: "Pasted Document", fileSizeDescription: "File")),
                    size: CGSize(width: 170, height: 72),
                    message: "Pasted File Document"
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Apple Music Resolver
    
    static func resolveAppleMusicLink(_ linkString: String) async -> MusicEmbedPayload {
        guard let url = URL(string: linkString) else {
            return MusicEmbedPayload(trackTitle: "Apple Music Track", artist: "Apple Music", appleMusicURLString: linkString, isAppleMusic: true)
        }
        
        // Parse track ID if present (?i=123456 or /album/.../12345)
        var trackId: String? = nil
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            trackId = components.queryItems?.first(where: { $0.name == "i" })?.value
        }
        if trackId == nil {
            let last = url.lastPathComponent
            if !last.isEmpty && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: last)) {
                trackId = last
            }
        }
        
        // Fallback title from URL slug
        var fallbackTitle = "Apple Music Track"
        let pathParts = url.pathComponents.filter {
            $0 != "/" && $0 != "album" && $0 != "song" && $0 != "us" && $0 != "music" && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0))
        }
        if let slug = pathParts.last {
            fallbackTitle = slug.replacingOccurrences(of: "-", with: " ").capitalized
        }
        
        // If we have trackId, query iTunes search API for real preview & artwork
        if let id = trackId, let lookupURL = URL(string: "https://itunes.apple.com/lookup?id=\(id)") {
            do {
                let (data, _) = try await URLSession.shared.data(from: lookupURL)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let first = results.first {
                    let title = first["trackName"] as? String ?? fallbackTitle
                    let artist = first["artistName"] as? String ?? "Apple Music"
                    let previewUrl = first["previewUrl"] as? String
                    
                    var artworkData: Data? = nil
                    if let artUrlStr = first["artworkUrl100"] as? String,
                       let artUrl = URL(string: artUrlStr) {
                        artworkData = try? await URLSession.shared.data(from: artUrl).0
                    }
                    
                    return MusicEmbedPayload(
                        trackTitle: title,
                        artist: artist,
                        previewURLString: previewUrl,
                        appleMusicURLString: linkString,
                        artworkData: artworkData,
                        isAppleMusic: true
                    )
                }
            } catch {
                // fall through to fallback
            }
        }
        
        return MusicEmbedPayload(
            trackTitle: fallbackTitle,
            artist: "Apple Music",
            appleMusicURLString: linkString,
            isAppleMusic: true
        )
    }
    
    private static func isSingleEmoji(_ text: String) -> Bool {
        guard text.count <= 3 else { return false }
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                return true
            }
        }
        return false
    }
}
