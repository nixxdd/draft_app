import SwiftUI

struct MemoriesView: View {
    @State private var store = MemoryStore()
    @State private var isShowingFriendsView = false
    @State private var isShowingTimeline = false
    
    // Placeholder ID representing the slide after the last card
    private let newCardPlaceholderID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
    @State private var showNewCardPrompt = false
    @State private var newCardDate: Date = .now
    
    let fullCanvasSize = CGSize(width: 390, height: 720)

    var body: some View {
        ZStack {
            SketchTheme.backgroundGradient
                .ignoresSafeArea()
            
            if store.isEditingCard {
                CanvasView(store: store)
            } else {
                VStack(spacing: 6) {
                    // Top Navigation Header
                    ZStack {
                        GlassOvalButton(systemImage: "person.2") {
                            isShowingFriendsView = true
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Memories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Slide Paged Cards (Expands when timeline hidden, shrinks when timeline shown)
                    TabView(selection: $store.selectedCardID) {
                        ForEach(Array(store.cards.enumerated()), id: \.element.id) { index, card in
                            SingleCardPageView(
                                store: store,
                                card: card,
                                pageIndex: index,
                                totalPages: store.cards.count,
                                isCurrentPage: card.id == store.selectedCardID,
                                onEdit: {
                                    withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                                        store.isEditingCard = true
                                    }
                                }
                            )
                            .tag(card.id)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 2)
                        }
                        
                        // Slide after the last card: triggers date prompt to create a new card
                        NewCardSlidePlaceholder(
                            action: {
                                newCardDate = .now
                                showNewCardPrompt = true
                            }
                        )
                        .tag(newCardPlaceholderID)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Swipe up on cards reveals the timeline
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.height < -30 && abs(value.translation.height) > abs(value.translation.width) {
                                    if !isShowingTimeline {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                            isShowingTimeline = true
                                        }
                                    }
                                }
                            }
                    )
                    
                    // Bottom Section: Inline Timeline (Resizes the canvas card above, does NOT cover it)
                    if isShowingTimeline {
                        VStack(spacing: 2) {
                            // Grab handle to hide timeline when dragged down or tapped
                            Capsule()
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 40, height: 4.5)
                                .padding(.top, 8)
                                .padding(.bottom, 2)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 8)
                                        .onEnded { value in
                                            if value.translation.height > 12 {
                                                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                                    isShowingTimeline = false
                                                }
                                            }
                                        }
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                        isShowingTimeline = false
                                    }
                                }
                            
                            TimelineStripView(store: store, showTitle: false)
                                .padding(.bottom, 4)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 15)
                                .onEnded { value in
                                    // Dragging down on the timeline hides it
                                    if value.translation.height > 20 && abs(value.translation.height) > abs(value.translation.width) {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                            isShowingTimeline = false
                                        }
                                    }
                                }
                        )
                    } else {
                        // Compact Pull Pill at bottom when timeline is hidden
                        Button {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                isShowingTimeline = true
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.4))
                                    .frame(width: 36, height: 3.5)
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(SketchTheme.dateBadgeColor)
                                    Text("Timeline")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                            .shadow(color: .black.opacity(0.04), radius: 3, y: 1.5)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.84), value: isShowingTimeline)
            }
        }
        .onAppear {
            store.handleCardSwitchAutoplay()
        }
        .onChange(of: store.selectedCardID) { _, newID in
            if newID == newCardPlaceholderID {
                // Slid past the last card: prompt for date first
                newCardDate = .now
                showNewCardPrompt = true
            } else {
                store.handleCardSwitchAutoplay()
            }
        }
        .onChange(of: store.isEditingCard) { _, isEditing in
            if !isEditing {
                store.handleCardSwitchAutoplay()
            }
        }
        .sheet(isPresented: $showNewCardPrompt, onDismiss: {
            // If user dismissed without creating, revert selection back to last card
            if store.selectedCardID == newCardPlaceholderID {
                if let last = store.cards.last {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        store.selectedCardID = last.id
                    }
                }
            }
        }) {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("New Memory Card")
                            .font(.title3.bold())
                        Text("When did this memory happen?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 14)
                    
                    DatePicker(
                        "Memory Date",
                        selection: $newCardDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(SketchTheme.dateBadgeColor)
                    .padding(.horizontal)
                    
                    Button {
                        showNewCardPrompt = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            // Creates card, sorts chronologically, and selects it
                            let newCard = store.createNewCard(date: newCardDate, startEditing: false)
                            store.selectedCardID = newCard.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Card")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SketchTheme.dateBadgeColor, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showNewCardPrompt = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowingFriendsView) {
            FriendsBubbleView(store: store)
        }
    }
}

// MARK: - Slide Placeholder for creating a new card

private struct NewCardSlidePlaceholder: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SketchTheme.dateBadgeColor.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 38))
                        .foregroundStyle(SketchTheme.dateBadgeColor)
                }
                
                VStack(spacing: 6) {
                    Text("New Memory Card")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Swipe or tap to pick a date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text("Choose Date")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(SketchTheme.dateBadgeColor, in: Capsule())
                .shadow(color: SketchTheme.dateBadgeColor.opacity(0.3), radius: 6, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                SketchTheme.dateBadgeColor.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Single Card Page View (Clean Scrapbook Card)

struct SingleCardPageView: View {
    @Bindable var store: MemoryStore
    let card: MemoryCard
    let pageIndex: Int
    let totalPages: Int
    var isCurrentPage: Bool = false
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Main Card Surface
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SketchTheme.canvasCardGradient)
                .overlay {
                    CanvasItemsLayer(store: store, card: card, isEditable: false)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 4)
            
            // Top Controls: Edit Button & Page Badge
            if isCurrentPage {
                VStack {
                    HStack {
                        if let onEdit {
                            Button("Edit") {
                                onEdit()
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(SketchTheme.editPillGradient, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        }
                        
                        Spacer()
                        
                        // Page Badge
                        HStack(spacing: 5) {
                            Text("\(pageIndex + 1) / \(totalPages)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8))
                    }
                    .padding(14)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    MemoriesView()
}
