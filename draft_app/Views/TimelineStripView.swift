import SwiftUI

struct TimelineStripView: View {
    @Bindable var store: MemoryStore
    var showTitle: Bool = true

    @State private var showDatePicker: Bool = false
    @State private var newCardDate: Date = .now
    
    var body: some View {
        VStack(spacing: 2) {
            if showTitle {
                Text("Timeline")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(SketchTheme.connectorLineColor)
                    .frame(height: 2.5)
                    .offset(y: 6)
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(store.timelineDayGroups, id: \.day) { group in
                                TimelineDaySlotView(
                                    store: store,
                                    day: group.day,
                                    dayCards: group.cards
                                )
                                .id(group.day)
                            }
                            
                            NewTimelineCardButton {
                                newCardDate = .now
                                showDatePicker = true
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                    }
                    .scrollClipDisabled()
                    .onChange(of: store.selectedCardID) { _, newID in
                        if let card = store.cards.first(where: { $0.id == newID }) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                proxy.scrollTo(card.day, anchor: .center)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                VStack(spacing: 20) {
                    Text("When was this memory?")
                        .font(.headline)
                    
                    DatePicker("Select Date", selection: $newCardDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(SketchTheme.dateBadgeColor)
                    
                    PastelGradientButton(title: "Create Card") {
                        showDatePicker = false
                        store.createNewCard(date: newCardDate)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Single Day Slot (Compact & Polished)

private struct TimelineDaySlotView: View {
    @Bindable var store: MemoryStore
    let day: Int
    let dayCards: [MemoryCard]
    
    private var isSelectedDay: Bool {
        dayCards.contains(where: { $0.id == store.selectedCardID })
    }
    
    private var activeCardForDay: MemoryCard {
        dayCards.first(where: { $0.id == store.selectedCardID }) ?? dayCards[0]
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Back card (if multiple memories on this day)
            if dayCards.count > 1 {
                let inactiveCard = dayCards.first(where: { $0.id != activeCardForDay.id }) ?? dayCards[1]
                let backBgColor = Color(hex: inactiveCard.cardTintHex) ?? Color(red: 0.88, green: 0.88, blue: 0.90)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(backBgColor.opacity(0.85))
                    
                    CanvasItemsLayer(store: store, card: inactiveCard, isEditable: false, isThumbnail: true)
                        .frame(width: 64, height: 86)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .allowsHitTesting(false)
                        .opacity(0.65)
                }
                .frame(width: 64, height: 86)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                )
                
                cardThumbnail(for: activeCardForDay, isFrontStack: true)
                    .offset(x: 6, y: 6)
            } else if let singleCard = dayCards.first {
                cardThumbnail(for: singleCard, isFrontStack: false)
            }
            
            // Compact Day Badge
            HStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isSelectedDay ? Color.white : SketchTheme.dateBadgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                isSelectedDay ? SketchTheme.dateBadgeColor : Color(.secondarySystemBackground),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(SketchTheme.dateBadgeColor.opacity(isSelectedDay ? 0 : 0.35), lineWidth: 1)
            )
            .shadow(color: isSelectedDay ? SketchTheme.dateBadgeColor.opacity(0.35) : .black.opacity(0.04), radius: 3, y: 1)
            .offset(x: 2, y: -10)
            
            if dayCards.count > 1 {
                let currentIdx = (dayCards.firstIndex(where: { $0.id == activeCardForDay.id }) ?? 0) + 1
                Text("\(currentIdx)/\(dayCards.count)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(SketchTheme.dateBadgeColor))
                    .offset(x: 44, y: -6)
            }
        }
        .frame(width: dayCards.count > 1 ? 70 : 64, height: 92, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if isSelectedDay, dayCards.count > 1,
                   let currentIdx = dayCards.firstIndex(where: { $0.id == store.selectedCardID }) {
                    // Cycle to the next card in this day's stack
                    let nextIdx = (currentIdx + 1) % dayCards.count
                    store.selectedCardID = dayCards[nextIdx].id
                } else if let first = dayCards.first {
                    store.selectedCardID = first.id
                }
                store.selectedItemID = nil
            }
        }
    }
    
    @ViewBuilder
    private func cardThumbnail(for card: MemoryCard, isFrontStack: Bool) -> some View {
        let isCurrent = card.id == store.selectedCardID
        let cardBgColor = Color(hex: card.cardTintHex) ?? Color(red: 0.90, green: 0.90, blue: 0.92)
        
        ZStack {
            // Card background tint
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBgColor)
            
            // Live canvas miniature preview
            CanvasItemsLayer(store: store, card: card, isEditable: false, isThumbnail: true)
                .frame(width: 64, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .allowsHitTesting(false)
            
            if card.items.isEmpty {
                VStack(spacing: 3) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.black.opacity(0.25))
                    Text(card.title)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .lineLimit(2)
                }
            }
        }
        .frame(width: 64, height: 86)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isCurrent
                    ? SketchTheme.dateBadgeColor
                    : (isFrontStack ? Color.primary.opacity(0.2) : Color.white.opacity(0.7)),
                    lineWidth: isCurrent ? 2.0 : 0.8
                )
        )
        .shadow(
            color: isCurrent ? SketchTheme.dateBadgeColor.opacity(0.35) : .black.opacity(0.06),
            radius: isCurrent ? 6 : 3,
            x: 0,
            y: 2
        )
        .scaleEffect(isCurrent ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCurrent)
    }
}

// MARK: - New Timeline Card Button (Compact)

private struct NewTimelineCardButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SketchTheme.dateBadgeColor)
                Text("New")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.75))
            }
            .frame(width: 64, height: 86)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                SketchTheme.dateBadgeColor.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                            )
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 3, y: 1.5)
        }
        .buttonStyle(.plain)
    }
}
