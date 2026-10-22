//
//  TextItemEditorSheet.swift
//  draft_app
//

import SwiftUI

struct TextItemEditorSheet: View {
    let store: MemoryStore
    let initialItem: CanvasItem?
    let onSave: (_ text: String, _ bgHex: String, _ textHex: String, _ taggedFriendIDs: [UUID]) -> Void
    let onCancel: () -> Void
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedBgHex: String = "#F5EC87"
    @State private var selectedTextHex: String = "#2C2C2E"
    @State private var taggedFriendIDs: [UUID] = []
    @FocusState private var isTextFieldFocused: Bool
    
    private struct ColorPreset: Identifiable {
        let id: String
        let name: String
        let bgHex: String
        let textHex: String
    }
    
    private let colorPresets: [ColorPreset] = [
        ColorPreset(id: "yellow", name: "Yellow", bgHex: "#F5EC87", textHex: "#2C2C2E"),
        ColorPreset(id: "pink", name: "Pink", bgHex: "#F8C8DC", textHex: "#2C2C2E"),
        ColorPreset(id: "lavender", name: "Lavender", bgHex: "#E4C8E4", textHex: "#2C2C2E"),
        ColorPreset(id: "mint", name: "Mint", bgHex: "#D2F7E5", textHex: "#2C2C2E"),
        ColorPreset(id: "sky", name: "Sky", bgHex: "#E2ECF5", textHex: "#2C2C2E"),
        ColorPreset(id: "peach", name: "Peach", bgHex: "#FAD4C0", textHex: "#2C2C2E"),
        ColorPreset(id: "white", name: "White", bgHex: "#FFFFFF", textHex: "#2C2C2E"),
        ColorPreset(id: "dark", name: "Slate", bgHex: "#2C2C2E", textHex: "#FFFFFF")
    ]
    
    init(
        store: MemoryStore,
        initialItem: CanvasItem?,
        onSave: @escaping (_ text: String, _ bgHex: String, _ textHex: String, _ taggedFriendIDs: [UUID]) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.store = store
        self.initialItem = initialItem
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        
        _taggedFriendIDs = State(initialValue: initialItem?.taggedFriendIDs ?? [])
        
        if let initialItem = initialItem, case .text(let payload) = initialItem.content {
            _text = State(initialValue: payload.text)
            _selectedBgHex = State(initialValue: payload.backgroundColorHex)
            _selectedTextHex = State(initialValue: payload.textColorHex)
        } else {
            _text = State(initialValue: "")
            _selectedBgHex = State(initialValue: "#F5EC87")
            _selectedTextHex = State(initialValue: "#2C2C2E")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live Sticker Preview
                    VStack(spacing: 8) {
                        Text("PREVIEW")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        
                        ZStack(alignment: .bottomTrailing) {
                            Text(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Your Note Here" : text)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: selectedTextHex) ?? .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: selectedBgHex) ?? SketchTheme.yellowStickerColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                                .animation(.easeInOut(duration: 0.15), value: selectedBgHex)
                            
                            // Tagged Friend Avatars Overlay
                            if !taggedFriendIDs.isEmpty {
                                HStack(spacing: -6) {
                                    ForEach(taggedFriendIDs.prefix(3), id: \.self) { friendID in
                                        if let friend = store.friends.first(where: { $0.id == friendID }) {
                                            FriendAvatarView(friend: friend, size: 20)
                                                .clipShape(Circle())
                                                .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                                        }
                                    }
                                    if taggedFriendIDs.count > 3 {
                                        Text("+\(taggedFriendIDs.count - 3)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color.black.opacity(0.7), in: Circle())
                                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
                                    }
                                }
                                .offset(x: 8, y: 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemGray6).opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Text Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note Text")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        HStack {
                            TextField("Enter text...", text: $text)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .focused($isTextFieldFocused)
                            
                            if !text.isEmpty {
                                Button {
                                    text = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Color Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color Style")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colorPresets) { preset in
                                    Button {
                                        selectedBgHex = preset.bgHex
                                        selectedTextHex = preset.textHex
                                    } label: {
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(hex: preset.bgHex) ?? .yellow)
                                                .frame(width: 36, height: 36)
                                                .overlay {
                                                    if selectedBgHex.caseInsensitiveCompare(preset.bgHex) == .orderedSame {
                                                        Circle()
                                                            .strokeBorder(Color.primary, lineWidth: 2.5)
                                                    } else {
                                                        Circle()
                                                            .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                                                    }
                                                }
                                            Text(preset.name)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Tag Friends Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Tag Friends")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !taggedFriendIDs.isEmpty {
                                Text("\(taggedFriendIDs.count) tagged")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.purple)
                            }
                        }
                        .padding(.horizontal)
                        
                        if store.friends.isEmpty {
                            Text("No friends available to tag. Add friends from the Friends Cosmos.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(store.friends) { friend in
                                        let isTagged = taggedFriendIDs.contains(friend.id)
                                        Button {
                                            if isTagged {
                                                taggedFriendIDs.removeAll { $0 == friend.id }
                                            } else {
                                                taggedFriendIDs.append(friend.id)
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack(alignment: .topTrailing) {
                                                    FriendAvatarView(friend: friend, size: 44)
                                                        .clipShape(Circle())
                                                        .overlay(
                                                            Circle()
                                                                .strokeBorder(isTagged ? Color.purple : Color.clear, lineWidth: 2.5)
                                                        )
                                                    
                                                    if isTagged {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundStyle(Color.purple)
                                                            .background(Color.white, in: Circle())
                                                            .offset(x: 2, y: -2)
                                                    }
                                                }
                                                
                                                Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                                                    .font(.caption2.weight(isTagged ? .bold : .regular))
                                                    .foregroundStyle(isTagged ? Color.primary : Color.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 54)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Optional Delete Button (when editing existing)
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Note")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle(initialItem == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines), selectedBgHex, selectedTextHex, taggedFriendIDs)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}
