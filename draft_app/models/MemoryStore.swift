//
//  MemoryStore.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI
import AVFoundation

// Observable means that
// "Whenever any var inside this class changes, automatically redraw any View that reads it."

@Observable
final class MemoryStore {
    var friends: [Friend] = []
    var cards: [MemoryCard]
    var selectedCardID: UUID
    var selectedItemID: UUID? = nil
    var isEditingCard: Bool = false
    
    // Voice note playback / recording simulation & audio state
    var playingVoiceItemID: UUID? = nil
    var voicePlaybackProgress: Double = 0.0
    var isRecordingVoice: Bool = false
    var recordingSeconds: Double = 0.0
    private var playbackTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    // Music playback state
    var playingMusicItemID: UUID? = nil
    var musicPlaybackProgress: Double = 0.0
    private var musicPlayer: AVPlayer?
    private var musicTimer: Timer?
    
    // Video playback state
    var playingVideoItemID: UUID? = nil
    var videoPlayer: AVPlayer?
    
    init(cards: [MemoryCard] = CardsModel().cards) {
        self.cards = cards
        self.selectedCardID = cards.last?.id ?? UUID()
    }
    
    var selectedCard: MemoryCard? {
        cards.first(where: { $0.id == selectedCardID }) ?? cards.last
    }

    var timelineDayGroups: [(day: Int, cards: [MemoryCard])] {
        let grouped = Dictionary(grouping: cards, by: { $0.day })
        return grouped.keys.sorted().map { day in
            (day: day, cards: grouped[day] ?? [])
        }
    }

    func createNewCard(date : Date = .now) {
        let newCard = MemoryCard(
            title: "New Memory",
            date: date ,
            taggedFriendIDs: [],
            items: [],
            cardTintHex: "#E8DDE8"
        )
        cards.append(newCard)
        selectedCardID = newCard.id
        isEditingCard = true
    }

    func updateItem(_ updatedItem: CanvasItem) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }),
              let itemIndex = cards[cardIndex].items.firstIndex(where: { $0.id == updatedItem.id }) else { return }
        cards[cardIndex].items[itemIndex] = updatedItem
    }
    
    func deleteItem(id: UUID) {
        if playingVoiceItemID == id {
            stopVoiceNotePlayback()
        }
        if playingMusicItemID == id {
            stopMusicPlayback()
        }
        if playingVideoItemID == id {
            stopVideoPlayback()
        }
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }) else { return }
        cards[cardIndex].items.removeAll(where: { $0.id == id })
    }
    
    // MARK: - Voice Note Playback
    
    func toggleVoiceNotePlayback(for item: CanvasItem) {
        if playingVoiceItemID == item.id {
            stopVoiceNotePlayback()
        } else {
            startVoiceNotePlayback(for: item)
        }
    }
    
    func startVoiceNotePlayback(for item: CanvasItem) {
        stopVoiceNotePlayback()
        stopMusicPlayback()
        stopVideoPlayback()
        guard case .audioNote(let payload) = item.content else { return }
        
        playingVoiceItemID = item.id
        voicePlaybackProgress = 0.0
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        
        if let data = payload.audioData, let player = try? AVAudioPlayer(data: data) {
            audioPlayer = player
            player.play()
            let duration = max(0.5, player.duration)
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self, let p = self.audioPlayer, p.isPlaying else {
                    self?.stopVoiceNotePlayback()
                    return
                }
                self.voicePlaybackProgress = min(1.0, p.currentTime / duration)
            }
        } else {
            // Simulated playback for voice notes without audioData
            let duration = max(1.0, payload.durationSeconds)
            var elapsed = 0.0
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                elapsed += 0.1
                self.voicePlaybackProgress = min(1.0, elapsed / duration)
                if elapsed >= duration {
                    self.stopVoiceNotePlayback()
                }
            }
        }
    }
    
    func stopVoiceNotePlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingVoiceItemID = nil
        voicePlaybackProgress = 0.0
    }
    
    // MARK: - Music Playback
    
    func toggleMusicPlayback(for item: CanvasItem) {
        if playingMusicItemID == item.id {
            stopMusicPlayback()
        } else {
            startMusicPlayback(for: item)
        }
    }
    
    func startMusicPlayback(for item: CanvasItem) {
        stopVoiceNotePlayback()
        stopMusicPlayback()
        stopVideoPlayback()
        
        guard case .musicEmbed(let payload) = item.content else { return }
        playingMusicItemID = item.id
        musicPlaybackProgress = 0.0
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        
        if let previewStr = payload.previewURLString, let url = URL(string: previewStr) {
            let player = AVPlayer(url: url)
            musicPlayer = player
            player.play()
            
            musicTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let p = self.musicPlayer else { return }
                let current = CMTimeGetSeconds(p.currentTime())
                let duration = 30.0
                self.musicPlaybackProgress = min(1.0, current / duration)
                if current >= duration || (p.timeControlStatus == .paused && current > 0.5) {
                    self.stopMusicPlayback()
                }
            }
        } else {
            // Simulated preview playback (30 seconds)
            var elapsed = 0.0
            let duration = 30.0
            musicTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                elapsed += 0.1
                self.musicPlaybackProgress = min(1.0, elapsed / duration)
                if elapsed >= duration {
                    self.stopMusicPlayback()
                }
            }
        }
    }
    
    func stopMusicPlayback() {
        musicTimer?.invalidate()
        musicTimer = nil
        musicPlayer?.pause()
        musicPlayer = nil
        playingMusicItemID = nil
        musicPlaybackProgress = 0.0
    }
    
    // MARK: - Video Playback
    
    func toggleVideoPlayback(for item: CanvasItem) {
        if playingVideoItemID == item.id {
            stopVideoPlayback()
        } else {
            startVideoPlayback(for: item)
        }
    }
    
    func startVideoPlayback(for item: CanvasItem) {
        guard case .video(let payload) = item.content else { return }
        
        // If video has audio (not muted), stop voice notes and music
        if !payload.isMuted {
            stopVoiceNotePlayback()
            stopMusicPlayback()
        }
        stopVideoPlayback()
        
        playingVideoItemID = item.id
        
        let playURL: URL? = {
            if let str = payload.videoURLString, let u = URL(string: str), FileManager.default.fileExists(atPath: u.path) {
                return u
            }
            if let data = payload.videoData {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(item.id.uuidString).mp4")
                if !FileManager.default.fileExists(atPath: tempURL.path) {
                    try? data.write(to: tempURL)
                }
                return tempURL
            }
            // Fallback sample video URL (Apple sample)
            return URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")
        }()
        
        if let url = playURL {
            let player = AVPlayer(url: url)
            player.isMuted = payload.isMuted
            videoPlayer = player
            player.play()
            
            NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
    }
    
    func stopVideoPlayback() {
        videoPlayer?.pause()
        videoPlayer = nil
        playingVideoItemID = nil
    }
    
    // MARK: - Card Switch & Autoplay Logic
    
    func handleCardSwitchAutoplay() {
        guard !isEditingCard else { return }
        
        // Stop any playing voice note or video when switching cards
        stopVoiceNotePlayback()
        stopVideoPlayback()
        
        guard let card = selectedCard else {
            stopMusicPlayback()
            return
        }
        
        // Autoplay music if present on the active card outside edit mode
        if let musicItem = card.items.first(where: {
            if case .musicEmbed = $0.content { return true }
            return false
        }) {
            startMusicPlayback(for: musicItem)
        } else {
            // Card has no music, stop playing
            stopMusicPlayback()
        }
    }

    // Adds a new item (photo, friend, text, voice note, etc.) to the center of the canvas
    func addItem(kind: CanvasItemKind, text: String? = nil, friendID: UUID? = nil) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }) else { return }
        let newItem = CanvasItem(
            id: UUID(),
            kind: kind,
            position: CGPoint(x: 180, y: 260), // Starts near the center
            size: CGSize(width: 140, height: 140),
            rotationDegrees: Double.random(in: -8...8),
            scale: 1.0,
            zIndex: Double(cards[cardIndex].items.count + 1),
            text: text,
            friendID: friendID
        )
        cards[cardIndex].items.append(newItem)
    }

    func addItem(content: CanvasContent, size: CGSize = CGSize(width: 140, height: 140), position: CGPoint = CGPoint(x: 180, y: 260)) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }) else { return }
        let newItem = CanvasItem(
            id: UUID(),
            position: position,
            size: size,
            rotationDegrees: Double.random(in: -8...8),
            scale: 1.0,
            zIndex: Double(cards[cardIndex].items.count + 1),
            content: content
        )
        cards[cardIndex].items.append(newItem)
    }
}
