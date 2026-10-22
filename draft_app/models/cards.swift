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
            taggedFriendIDs: [SampleFriends.stefaniaID],
            items: [
                CanvasItem(
                    id: UUID(),
                    kind: .tapeLabel,
                    position: CGPoint(x: 150, y: 240),
                    size: CGSize(width: 180, height: 45),
                    rotationDegrees: -10,
                    scale: 1.0,
                    zIndex: 1,
                    text: "Sant'Elmo"
                ),
                CanvasItem(
                    id: UUID(),
                    position: CGPoint(x: 195, y: 350),
                    size: CGSize(width: 180, height: 50),
                    rotationDegrees: 2,
                    scale: 1.0,
                    zIndex: 2,
                    taggedFriendIDs: [SampleFriends.stefaniaID],
                    content: .link(LinkPayload(
                        urlString: "https://en.wikipedia.org/wiki/Castel_Sant%27Elmo",
                        title: "Castel Sant'Elmo",
                        host: "wikipedia.org"
                    ))
                )
            ],
            cardTintHex: "#e4c8e4"
        ),
        MemoryCard(
            title: "Coffee with friends",
            date: makeDate(day: 25),
            taggedFriendIDs: [SampleFriends.stefaniaID, SampleFriends.lucaID],
            items: [
                CanvasItem(
                    id: UUID(),
                    position: CGPoint(x: 195, y: 340),
                    size: CGSize(width: 170, height: 56),
                    rotationDegrees: -3,
                    scale: 1.0,
                    zIndex: 1,
                    content: .audioNote(AudioNotePayload(durationSeconds: 8.0))
                ),
                CanvasItem(
                    id: UUID(),
                    position: CGPoint(x: 195, y: 220),
                    size: CGSize(width: 170, height: 120),
                    rotationDegrees: 2,
                    scale: 1.0,
                    zIndex: 2,
                    taggedFriendIDs: [SampleFriends.lucaID],
                    content: .video(VideoPayload(
                        durationSeconds: 15,
                        isMuted: true,
                        videoURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                    ))
                )
            ],
            cardTintHex: "#f7d4d9"
        ),
        MemoryCard(
            title: "Beach Sunset",
            date: makeDate(day: 25),
            taggedFriendIDs: [SampleFriends.chiaraID],
            items: [
                CanvasItem(
                    id: UUID(),
                    position: CGPoint(x: 195, y: 300),
                    size: CGSize(width: 220, height: 60),
                    rotationDegrees: 2,
                    scale: 1.0,
                    zIndex: 1,
                    content: .musicEmbed(MusicEmbedPayload(
                        trackTitle: "Espresso",
                        artist: "Sabrina Carpenter",
                        previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/91/97/bb/9197bb75-9e6b-a2ea-9e0a-0c7f2127ef3e/mzaf_17208107936166795493.plus.aac.p.m4a",
                        appleMusicURLString: "https://music.apple.com/us/album/espresso/1739566914?i=1739566922",
                        isAppleMusic: true
                    ))
                )
            ],
            cardTintHex: "#E2ECF5"
        ),
        MemoryCard(
            title: "Touristing",
            date: makeDate(day: 27),
            taggedFriendIDs: [],
            items: [
                CanvasItem(
                    id: UUID(),
                    position: CGPoint(x: 110, y: 240),
                    size: CGSize(width: 140, height: 180),
                    rotationDegrees: -8,
                    scale: 1.0,
                    zIndex: 1,
                    tapeStyle: .topLeftYellow,
                    taggedFriendIDs: [SampleFriends.stefaniaID],
                    content: .photo(PhotoPayload(
                        caption: "Naples View",
                        isPolaroid: true,
                        latitude: 40.8444,
                        longitude: 14.2389,
                        locationName: "Castel Sant'Elmo, Naples"
                    ))
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


