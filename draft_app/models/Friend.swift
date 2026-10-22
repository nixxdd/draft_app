//
//  Friend.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI

struct Friend: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var displayName: String = ""
    var avatarAsset: String = ""
    var cardAvatarAsset: String? = nil
    var badgeEmoji: String? = nil
    var lastInteractionText: String = ""
    var cosmoPosition: CGPoint = .zero
    var favoriteColor: String = "#E8DDE8"
    var hobbies: String = ""
    var birthday: String = ""
    var isPlaceholderContact: Bool = false
    
    // Contact import fields
    var avatarData: Data? = nil
    var phoneNumber: String? = nil
    var email: String? = nil
    
    var resolvedDisplayName: String {
        if !displayName.isEmpty { return displayName }
        if !name.isEmpty {
            return name.components(separatedBy: " ").first ?? name
        }
        return "Friend"
    }
    
    var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }
    
    /// Parses the friend's hobbies/interests into individual items for floating bubbles
    var hobbyList: [String] {
        let raw = hobbies.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return [] }
        let separators = CharacterSet(charactersIn: ",&/•;\n+")
        let parts = raw.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? [raw] : parts
    }
}

// Default starter friends so the user immediately sees the floating bubble cosmos
enum SampleFriends {
    static let stefaniaID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let lucaID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let chiaraID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let marcoID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    
    static let defaults: [Friend] = [
        Friend(
            id: stefaniaID,
            name: "Stefania Rosciano",
            displayName: "Stef",
            avatarAsset: "",
            badgeEmoji: "✨",
            lastInteractionText: "Castel Sant'Elmo trip",
            cosmoPosition: CGPoint(x: 195, y: 320),
            favoriteColor: "#E4C8E4",
            hobbies: "Photography & Travel",
            birthday: "October 20",
            phoneNumber: "+39 333 123 4567"
        ),
        Friend(
            id: lucaID,
            name: "Luca Bianchi",
            displayName: "Luca",
            avatarAsset: "",
            badgeEmoji: "☕️",
            lastInteractionText: "Coffee in Spaccanapoli",
            cosmoPosition: CGPoint(x: 105, y: 220),
            favoriteColor: "#F5EC87",
            hobbies: "Espresso & Architecture",
            birthday: "March 15",
            phoneNumber: "+39 340 987 6543"
        ),
        Friend(
            id: chiaraID,
            name: "Chiara Moretti",
            displayName: "Chiara",
            avatarAsset: "",
            badgeEmoji: "🎨",
            lastInteractionText: "Sunset at the beach",
            cosmoPosition: CGPoint(x: 295, y: 230),
            favoriteColor: "#F8C8DC",
            hobbies: "Painting & Vinyl Records",
            birthday: "July 8",
            phoneNumber: "+39 328 456 7890"
        ),
        Friend(
            id: marcoID,
            name: "Marco Esposito",
            displayName: "Marco",
            avatarAsset: "",
            badgeEmoji: "🌊",
            lastInteractionText: "Recently added",
            cosmoPosition: CGPoint(x: 195, y: 490),
            favoriteColor: "#D2F7E5",
            hobbies: "Hiking & Music",
            birthday: "December 3",
            phoneNumber: "+39 347 112 2334"
        )
    ]
}
// MARK: - Reusable Avatar View
struct FriendAvatarView: View {
    let friend: Friend
    var size: CGFloat = 60
    
    var body: some View {
        Group {
            if let data = friend.avatarData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else if !friend.avatarAsset.isEmpty, let uiImg = UIImage(named: friend.avatarAsset) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: friend.favoriteColor) ?? .purple.opacity(0.6),
                            Color(hex: friend.favoriteColor)?.opacity(0.4) ?? .blue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(friend.initials)
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.75))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

