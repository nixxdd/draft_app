import SwiftUI

struct MemoriesView: View {
    @State private var store = MemoryStore()
    let fullCanvasSize = CGSize(width: 390, height: 720)

    var body: some View {
        ZStack {
            SketchTheme.backgroundGradient
                .ignoresSafeArea()
            
            if store.isEditingCard {
                CanvasView(store: store)
            } else {
                VStack {
                    ZStack {
                        GlassOvalButton(systemImage: "person.2") {
                            // action for later
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Memories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 28)
                        .fill(SketchTheme.canvasCardGradient)
                        .overlay {
                            if let card = store.selectedCard {
                                CanvasItemsLayer(store: store, card: card, isEditable: false)
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            Button("Edit") {
                                withAnimation(.spring(response: 0.9, dampingFraction: 0.9)) {
                                    store.isEditingCard = true
                                }
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(SketchTheme.editPillGradient, in: Capsule())
                            .padding(16)
                        }
                        .padding(.horizontal)
                    
             
                    TimelineStripView(store: store)
                }
            }
        }
    }
}

#Preview {
    MemoriesView()
}
