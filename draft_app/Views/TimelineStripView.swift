import SwiftUI

struct TimelineStripView: View {
    @Bindable var store: MemoryStore

    @State private var showDatePicker: Bool = false
    @State private var newCardDate: Date = .now
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Timeline")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(SketchTheme.connectorLineColor)
                    .frame(height: 4.5)
                    .offset(y: 12)
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 26) {
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
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
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

// MARK: - Single Day Slot (Supports Stacked Cards like Day 25 in Sketch)

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
            // Back card (if multiple memories on this day or selected, matching Rectangle 3 & Rectangle 4 on Day 25 in Sketch)
            if dayCards.count > 1 {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(red: 0.88, green: 0.88, blue: 0.90).opacity(0.72))
                    .frame(width: 102, height: 145)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                    )
                
                cardThumbnail(for: activeCardForDay, isFrontStack: true)
                    .offset(x: 11, y: 11)
            } else if let singleCard = dayCards.first {
                cardThumbnail(for: singleCard, isFrontStack: false)
            }
            
            SketchDateBadge(day: day, isSelected: isSelectedDay)
                .offset(x: 4, y: -16)
            
            if dayCards.count > 1 {
                let currentIdx = (dayCards.firstIndex(where: { $0.id == activeCardForDay.id }) ?? 0) + 1
                Text("\(currentIdx)/\(dayCards.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(SketchTheme.dateBadgeColor))
                    .offset(x: 74, y: -8)
            }
        }
        .frame(width: dayCards.count > 1 ? 113 : 102, height: 156, alignment: .topLeading)
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
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    isCurrent
                    ? Color(red: 0.84, green: 0.84, blue: 0.86).opacity(0.92)
                    : Color(red: 0.90, green: 0.90, blue: 0.92).opacity(0.82)
                )
            
            // Subtle miniature preview of the card's actual items
            // MemoryCardMiniPreview(store: store, card: card)
            //    .opacity(isCurrent ? 0.55 : 0.32)
            //    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .frame(width: 102, height: 145)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(
                    isCurrent || isFrontStack
                    ? Color(red: 0.711, green: 0.674, blue: 0.674)
                    : Color.white.opacity(0.6),
                    lineWidth: isCurrent ? 1.5 : 1.0
                )
        )
        .shadow(
            color: .black.opacity(isCurrent ? 0.14 : 0.05),
            radius: isCurrent ? 8 : 4,
            x: 0,
            y: 4
        )
        .scaleEffect(isCurrent ? 1.02 : 1.0)
    }
}


private struct NewTimelineCardButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SketchTheme.dateBadgeColor)
                Text("New Card")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.65))
            }
            .frame(width: 102, height: 145)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(
                                SketchTheme.dateBadgeColor.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
