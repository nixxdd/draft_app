//
//  TextItemEditorSheet.swift
//  draft_app
//

import SwiftUI

struct TextItemEditorSheet: View {
    let initialItem: CanvasItem?
    let onSave: (_ text: String, _ bgHex: String, _ textHex: String) -> Void
    let onCancel: () -> Void
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedBgHex: String = "#F5EC87"
    @State private var selectedTextHex: String = "#2C2C2E"
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
        initialItem: CanvasItem?,
        onSave: @escaping (_ text: String, _ bgHex: String, _ textHex: String) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.initialItem = initialItem
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        
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
            VStack(spacing: 20) {
                // Live Sticker Preview
                VStack(spacing: 8) {
                    Text("PREVIEW")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    
                    Text(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Your Note Here" : text)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: selectedTextHex) ?? .black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: selectedBgHex) ?? SketchTheme.yellowStickerColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .animation(.easeInOut(duration: 0.15), value: selectedBgHex)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
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
                
                Spacer()
                
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
                    .padding(.bottom, 8)
                }
            }
            .padding(.top, 12)
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
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines), selectedBgHex, selectedTextHex)
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
