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
}
