//
//  cards.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation

func makeDate(day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: day)) ?? .now
}

class CardsModel {
    
    var cards: [MemoryCard] = [
        MemoryCard(
            title: "Monte Sant'Elmo Day",
            date: makeDate(day: 24),
            taggedFriendIDs: [],
            items: [
                CanvasItem(
                    id: UUID(),
                    kind: .tapeLabel,
                    position: CGPoint(x: 150, y: 300),
                    size: CGSize(width: 180, height: 45),
                    rotationDegrees: -10,
                    scale: 1.0,
                    zIndex: 1,
                    text: "Sant'Elmo"
                )
            ],
            cardTintHex: "#e4c8e4"
        ),
        MemoryCard(
            title: "Coffee with friends",
            date: makeDate(day: 25),
            taggedFriendIDs: [],
            items: [],
            cardTintHex: "#f7d4d9"
        ),
        MemoryCard(
            title: "Beach Sunset",
            date: makeDate(day: 25),
            taggedFriendIDs: [],
            items: [],
            cardTintHex: "#E2ECF5"
        ),
        MemoryCard(
            title: "Touristing",
            date: makeDate(day: 27),
            taggedFriendIDs: [],
            items: [
                CanvasItem(
                    id: UUID(),
                    kind: .polaroidPhoto,
                    position: CGPoint(x: 110, y: 240),
                    size: CGSize(width: 140, height: 180),
                    rotationDegrees: -8,
                    scale: 1.0,
                    zIndex: 1,
                    tapeStyle: .topLeftYellow
                ),
                CanvasItem(
                    id: UUID(),
                    kind: .polaroidPhoto,
                    position: CGPoint(x: 240, y: 150),
                    size: CGSize(width: 140, height: 160),
                    rotationDegrees: 0,
                    scale: 1.0,
                    zIndex: 2,
                    tapeStyle: .topRightCream
                ),
                CanvasItem(
                    id: UUID(),
                    kind: .tapeLabel,
                    position: CGPoint(x: 100, y: 390),
                    size: CGSize(width: 150, height: 44),
                    rotationDegrees: -20,
                    scale: 1.0,
                    zIndex: 3,
                    text: "Touristing"
                ),
                CanvasItem(
                    id: UUID(),
                    kind: .mapLocation,
                    position: CGPoint(x: 230, y: 380),
                    size: CGSize(width: 160, height: 110),
                    rotationDegrees: 0,
                    scale: 1.0,
                    zIndex: 2,
                    latitude: 42.6986,
                    longitude: 2.8956
                )
            ],
            cardTintHex: "#d2f7e5"
        )
    ]
}


