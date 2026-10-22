//
//  EmojiPickerView.swift
//  draft_app
//

import SwiftUI

struct EmojiPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryIndex: Int = 0
    @State private var searchText: String = ""
    
    private struct EmojiCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let emojis: [String]
    }
    
    private let categories: [EmojiCategory] = [
        EmojiCategory(
            name: "Smileys",
            icon: "face.smiling",
            emojis: [
                "😊", "😂", "🥰", "😍", "🤩", "😎", "🥳", "🥺", "😋", "😜",
                "🤪", "🤔", "🤫", "😴", "🤯", "😇", "🤠", "🥹", "😭", "😤",
                "🫠", "🫣", "🫡", "🤗", "🤤", "🥱", "😷", "🤒", "👻", "💀"
            ]
        ),
        EmojiCategory(
            name: "Hearts",
            icon: "heart.fill",
            emojis: [
                "❤️", "💖", "✨", "🔥", "🌟", "💫", "⚡️", "🌈", "☀️", "🌙",
                "☁️", "🫧", "💕", "💞", "💓", "💗", "💘", "💝", "💌", "❤️‍🔥",
                "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💥", "⭐️"
            ]
        ),
        EmojiCategory(
            name: "Gestures",
            icon: "hand.thumbsup.fill",
            emojis: [
                "👍", "👎", "✌️", "🤞", "🫰", "🤟", "🤘", "🤙", "👌", "🤌",
                "👏", "🙌", "🫶", "👐", "🤝", "🙏", "💪", "💅", "🤳", "✍️",
                "👋", "✋", "🖐️", "✊", "👊", "👈", "👉", "👆", "👇", "☝️"
            ]
        ),
        EmojiCategory(
            name: "Fun",
            icon: "party.popper.fill",
            emojis: [
                "🎉", "🎊", "🎈", "🎁", "🎀", "🪄", "🪅", "🎨", "🎬", "🎤",
                "🎧", "🎵", "🎶", "🎸", "🎹", "🥁", "🎮", "🎲", "🎯", "🎳",
                "🛹", "🚲", "🏄‍♂️", "🏊‍♀️", "⛺️", "🏖️", "🎡", "🎢", "📸", "🍿"
            ]
        ),
        EmojiCategory(
            name: "Food",
            icon: "cup.and.saucer.fill",
            emojis: [
                "☕️", "🍵", "🧋", "🥤", "🍦", "🍧", "🍨", "🍩", "🍪", "🎂",
                "🍰", "🧁", "🍫", "🍬", "🍭", "🍕", "🍔", "🍟", "🌮", "🌯",
                "🍣", "🍜", "🍝", "🥐", "🥨", "🥑", "🍓", "🍒", "🍑", "🍉"
            ]
        ),
        EmojiCategory(
            name: "Nature",
            icon: "pawprint.fill",
            emojis: [
                "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
                "🦁", "🐮", "🐷", "🐸", "🐵", "🦄", "🦋", "🐝", "🐞", "🌸",
                "🌺", "🌻", "🌹", "🌷", "🌼", "🍀", "🌿", "🌴", "🌵", "🍁"
            ]
        ),
        EmojiCategory(
            name: "Travel",
            icon: "airplane",
            emojis: [
                "✈️", "🚀", "⛵️", "🏖️", "🏔️", "🏕️", "🗺️", "🧳", "🚗", "🚕",
                "🏎️", "🛴", "🛵", "🚂", "🌅", "🌄", "🌇", "🌆", "🌃", "🏰",
                "🗼", "🗽", "🏟️", "🎡", "🎢", "🏠", "🏡", "🏝️", "🛳️", "🚲"
            ]
        )
    ]
    
    private var allEmojis: [String] {
        categories.flatMap { $0.emojis }
    }
    
    private var displayedEmojis: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return categories[selectedCategoryIndex].emojis
        }
        let lowerQuery = trimmed.lowercased()
        return allEmojis.filter { emoji in
            if emoji.contains(lowerQuery) { return true }
            let name = emoji.applyingTransform(StringTransform("Any-Name"), reverse: false)?.lowercased() ?? ""
            return name.contains(lowerQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search emojis...", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                
                // Category Pills (shown when not searching)
                if searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                                Button {
                                    selectedCategoryIndex = index
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                        Text(category.name)
                                    }
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategoryIndex == index
                                        ? Color.black.opacity(0.85)
                                        : Color(.systemGray6),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        selectedCategoryIndex == index
                                        ? Color.white
                                        : Color.primary
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Emoji Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                        ForEach(displayedEmojis, id: \.self) { emoji in
                            Button {
                                onSelect(emoji)
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 34))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("Add Emoji Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
