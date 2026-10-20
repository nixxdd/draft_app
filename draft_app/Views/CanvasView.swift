import SwiftUI
import Foundation

// Every CanvasItem has a unique ID, so we can identify it in the array of items on the card.
// This is important for editing, deleting, and reordering items

// It also saves the position : CGPoint (x,y) coordinates when the user puts their fingers on the canvas

// While draggging wiftUI gives you value.translation
// how far the finger moved (width = horizontal move, height = vertical move) from where the drag started.
// We store that in a temporary @State private var dragOffset: CGSize = .zero so the item follows your finger smoothly at 60fps

// When the finger is lifted, the drag gesture ends and we add the dragOffset to the item's position and reset dragOffset to zero.

struct CanvasView: View {
    @Bindable var store: MemoryStore
    
    var body: some View {
        ZStack {
            SketchTheme.backgroundGradient
                .ignoresSafeArea()
            
            if let card = store.selectedCard {
                CanvasItemsLayer(store: store, card: card, isEditable: true)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        withAnimation(.spring(response: 0.9, dampingFraction: 0.9)) {
                            store.isEditingCard = false
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(SketchTheme.editPillGradient, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                HStack {
                    bottomToolbar
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
  
    private var bottomToolbar: some View {
        HStack(spacing: 22) {
            Button {
                store.addItem(kind: .friendAvatar, text: "😊")
            } label: {
                Image(systemName: "face.smiling")
            }
            
            Button {
                store.addItem(kind: .tapeLabel, text: "New Note")
            } label: {
                Image(systemName: "character.textbox")
            }
            
            Menu {
                Button {
                    store.addItem(kind: .voiceNote)
                } label: {
                    Label("Voice Note", systemImage: "waveform")
                }
                Button {
                    store.addItem(kind: .mapLocation, text: "Location")
                } label: {
                    Label("Location", systemImage: "map")
                }
                Button {
                    store.addItem(kind: .musicTag, text: "Favorite Song")
                } label: {
                    Label("Music", systemImage: "music.note")
                }
            } label: {
                Image(systemName: "link")
            }
            
            Button {
                store.addItem(kind: .polaroidPhoto)
            } label: {
                Image(systemName: "photo.badge.plus")
            }
        }
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(.black.opacity(0.85))
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

struct CanvasItemsLayer: View {
    @Bindable var store: MemoryStore
    let card: MemoryCard
    var isEditable: Bool

    let fullCanvasSize = CGSize(width: 390, height: 720)
    
    var body: some View {

        GeometryReader {
            geo in
            let scaleX = geo.size.width / fullCanvasSize.width
            let scaleY = geo.size.height / fullCanvasSize.height
            let scale = isEditable ? 1.0 : min(scaleX, scaleY)

            ZStack {
                ForEach(card.items) { item in
                    DraggableCanvasItem(store: store, item: item, isEditable: isEditable)
                }
            }
            .frame(width: fullCanvasSize.width, height: fullCanvasSize.height)
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}


struct DraggableCanvasItem: View {
    @Bindable var store: MemoryStore
    let item: CanvasItem
    var isEditable: Bool
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        itemVisual
            .rotationEffect(.degrees(item.rotationDegrees))
            .position(
                x: item.position.x + dragOffset.width,
                y: item.position.y + dragOffset.height
            )
            .gesture(
                isEditable ?
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        var updated = item
                        updated.position.x += value.translation.width
                        updated.position.y += value.translation.height
                        dragOffset = .zero
                        store.updateItem(updated)
                    }
                : nil
            )
    }
    
    @ViewBuilder
    private var itemVisual: some View {
        switch item.kind {
        case .polaroidPhoto:
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: item.size.width, height: item.size.height)
                .padding(8)
                .background(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 4, y: 6)
        case .tapeLabel:
            Text(item.text ?? "Touristing")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(SketchTheme.yellowStickerColor)
        case .mapLocation:
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.blue.opacity(0.2))
                .frame(width: item.size.width, height: item.size.height)
                .overlay(Image(systemName: "mappin.and.ellipse").font(.largeTitle))
                .padding(6)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
                .shadow(radius: 4)
        default:
            Text(item.text ?? "✨")
                .font(.largeTitle)
                .padding(12)
                .background(.white, in: Capsule())
                .shadow(radius: 3)
        }
    }
}
