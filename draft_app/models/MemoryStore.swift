//
//  MemoryStore.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI
import AVFoundation
import Contacts

// Observable means that
// "Whenever any var inside this class changes, automatically redraw any View that reads it."

@Observable
final class MemoryStore {
    var friends: [Friend] = SampleFriends.defaults
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
    
    init(cards: [MemoryCard] = CardsModel().cards, friends: [Friend] = SampleFriends.defaults) {
        let sortedCards = cards.sorted(by: { $0.date < $1.date })
        self.cards = sortedCards
        self.friends = friends
        self.selectedCardID = sortedCards.last?.id ?? UUID()
    }
    
    // MARK: - Friends & Tagging Statistics
    
    /// Returns the total number of times a friend is tagged across all memory cards and their canvas items
    func tagCount(for friendID: UUID) -> Int {
        var count = 0
        for card in cards {
            if card.taggedFriendIDs.contains(friendID) {
                count += 1
            }
            for item in card.items {
                if item.taggedFriendIDs.contains(friendID) {
                    count += 1
                }
                if case .contact(let p) = item.content, p.friendID == friendID {
                    count += 1
                }
            }
        }
        return count
    }
    
    var mostTaggedFriendID: UUID? {
        guard !friends.isEmpty else { return nil }
        let friendCounts = friends.map { ($0.id, tagCount(for: $0.id)) }
        let maxCount = friendCounts.map { $0.1 }.max() ?? 0
        guard maxCount > 0 else { return nil }
        return friendCounts.first(where: { $0.1 == maxCount })?.0
    }
    
    func maxTagCount() -> Int {
        friends.map { tagCount(for: $0.id) }.max() ?? 0
    }
    
    func cardsFeaturingFriend(_ friendID: UUID) -> [MemoryCard] {
        cards.filter { card in
            card.taggedFriendIDs.contains(friendID) ||
            card.items.contains { item in
                item.taggedFriendIDs.contains(friendID) ||
                {
                    if case .contact(let p) = item.content { return p.friendID == friendID }
                    return false
                }()
            }
        }
    }
    
    // MARK: - Contacts Import
    
    func addFriendFromContact(_ contact: CNContact) {
        let fullName = [contact.givenName, contact.middleName, contact.familyName]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
        let name = fullName.isEmpty ? (contact.organizationName.isEmpty ? "Friend" : contact.organizationName) : fullName
        let displayName = contact.nickname.isEmpty ? (contact.givenName.isEmpty ? name : contact.givenName) : contact.nickname
        
        // If friend with same name exists, update avatar and details
        if let existingIdx = friends.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            if friends[existingIdx].avatarData == nil {
                friends[existingIdx].avatarData = contact.imageData ?? contact.thumbnailImageData
            }
            return
        }
        
        // Birthday formatting
        var birthdayStr = ""
        if let bday = contact.birthday {
            var comps = DateComponents()
            comps.month = bday.month
            comps.day = bday.day
            comps.year = bday.year
            if let date = Calendar.current.date(from: comps) {
                let formatter = DateFormatter()
                if bday.year == nil {
                    formatter.setLocalizedDateFormatFromTemplate("MMMM d")
                } else {
                    formatter.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
                }
                birthdayStr = formatter.string(from: date)
            }
        }
        
        let phone = contact.phoneNumbers.first?.value.stringValue
        let email = contact.emailAddresses.first?.value as String?
        let job = [contact.jobTitle, contact.departmentName, contact.organizationName]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " • ")
        
        let pastelColors = ["#E4C8E4", "#F5EC87", "#F8C8DC", "#D2F7E5", "#E2ECF5", "#FAD4C0"]
        let assignedColor = pastelColors.randomElement() ?? "#E4C8E4"
        
        let newFriend = Friend(
            id: UUID(),
            name: name,
            displayName: displayName,
            avatarAsset: "",
            badgeEmoji: "✨",
            lastInteractionText: "Added from Contacts",
            cosmoPosition: CGPoint(x: CGFloat.random(in: 100...280), y: CGFloat.random(in: 200...500)),
            favoriteColor: assignedColor,
            hobbies: job.isEmpty ? "Friend" : job,
            birthday: birthdayStr,
            avatarData: contact.imageData ?? contact.thumbnailImageData,
            phoneNumber: phone,
            email: email
        )
        
        friends.append(newFriend)
    }
    
    func addFriendsFromContacts(_ contacts: [CNContact]) {
        for contact in contacts {
            addFriendFromContact(contact)
        }
    }
    
    func deleteFriend(id: UUID) {
        friends.removeAll(where: { $0.id == id })
        for cardIdx in cards.indices {
            cards[cardIdx].taggedFriendIDs.removeAll(where: { $0 == id })
            for itemIdx in cards[cardIdx].items.indices {
                cards[cardIdx].items[itemIdx].taggedFriendIDs.removeAll(where: { $0 == id })
            }
        }
    }
    
    func addHobby(to friendID: UUID, hobby: String) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }
        let trimmed = hobby.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var currentList = friends[idx].hobbyList
        if !currentList.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            currentList.append(trimmed)
            friends[idx].hobbies = currentList.joined(separator: ", ")
        }
    }
    
    func removeHobby(from friendID: UUID, hobby: String) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }
        var currentList = friends[idx].hobbyList
        currentList.removeAll(where: { $0.caseInsensitiveCompare(hobby) == .orderedSame })
        friends[idx].hobbies = currentList.joined(separator: ", ")
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

    @discardableResult
    func createNewCard(date: Date = .now, startEditing: Bool = false) -> MemoryCard {
        let newCard = MemoryCard(
            title: "New Memory",
            date: date,
            taggedFriendIDs: [],
            items: [],
            cardTintHex: "#E8DDE8"
        )
        cards.append(newCard)
        cards.sort(by: { $0.date < $1.date })
        selectedCardID = newCard.id
        if startEditing {
            isEditingCard = true
        }
        return newCard
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

    func addItem(_ item: CanvasItem) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }) else { return }
        cards[cardIndex].items.append(item)
    }

    func addItem(content: CanvasContent, size: CGSize = CGSize(width: 140, height: 140), position: CGPoint = CGPoint(x: 180, y: 260), taggedFriendIDs: [UUID] = []) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == selectedCardID }) else { return }
        let newItem = CanvasItem(
            id: UUID(),
            position: position,
            size: size,
            rotationDegrees: Double.random(in: -8...8),
            scale: 1.0,
            zIndex: Double(cards[cardIndex].items.count + 1),
            taggedFriendIDs: taggedFriendIDs,
            content: content
        )
        cards[cardIndex].items.append(newItem)
    }
}
