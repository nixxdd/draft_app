//
//  MemoryCard.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import Foundation
import SwiftUI

struct MemoryCard : Identifiable, Codable, Equatable {
    var id : UUID = UUID()
    var title : String
    var date : Date // we can extract the day number from the date
    var taggedFriendIDs : [UUID]
    var items : [CanvasItem]
    var cardTintHex : String
    var day: Int {
            Calendar.current.component(.day, from: date)
        }
}



