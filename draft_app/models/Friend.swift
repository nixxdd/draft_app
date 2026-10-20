//
//  Friend.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI

struct Friend : Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID() // automatically generate the IDs
    var name: String
    var displayName: String
    var avatarAsset: String
    var cardAvatarAsset: String?
    var badgeEmoji: String?
    var lastInteractionText: String
    var cosmoPosition: CGPoint
    var favoriteColor: String // the same for the glow color
    var hobbies: String
    var birthday: String
    var isPlaceholderContact: Bool = false
    
}


