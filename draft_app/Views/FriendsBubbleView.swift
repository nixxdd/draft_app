//
//  FriendsBubbleView.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import SwiftUI
import Contacts

struct FriendsBubbleView: View {
    @Bindable var store: MemoryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingContactPicker = false
    @State private var selectedFriendForDetail: Friend? = nil
    @State private var dragOffsets: [UUID: CGSize] = [:]
    
    // Toast notification for added friends
    @State private var toastMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background Gradient
                SketchTheme.backgroundGradient
                    .ignoresSafeArea()
                
                // Floating Bubbles Playground
                GeometryReader { geo in
                    let availableSize = geo.size
                    
                    if store.friends.isEmpty {
                        emptyStateView
                    } else if availableSize.width > 50 && availableSize.height > 50 {
                        // Sort friends so the most tagged friend takes the prominent center spot
                        let sortedFriends = store.friends.sorted {
                            store.tagCount(for: $0.id) > store.tagCount(for: $1.id)
                        }
                        
                        // Calculate sizes
                        let sizes: [UUID: CGFloat] = Dictionary(
                            uniqueKeysWithValues: sortedFriends.map { ($0.id, calculateBubbleSize(for: $0)) }
                        )
                        
                        // Compute guaranteed non-overlapping positions
                        let positions = computeBubblePositions(for: sortedFriends, sizes: sizes, in: availableSize)
                        
                        ZStack {
                            // Constellation / connector lines between friends
                            constellationLines(for: sortedFriends, positions: positions)
                            
                            // Floating Friend Bubbles
                            ForEach(Array(sortedFriends.enumerated()), id: \.element.id) { index, friend in
                                let bubbleSize = sizes[friend.id] ?? 80
                                let pos = positions[friend.id] ?? CGPoint(x: availableSize.width / 2, y: availableSize.height / 2)
                                let drag = dragOffsets[friend.id] ?? .zero
                                let isMostTagged = friend.id == store.mostTaggedFriendID && store.tagCount(for: friend.id) > 0
                                let tags = store.tagCount(for: friend.id)
                                
                                FloatingBubbleItem(
                                    friend: friend,
                                    bubbleSize: bubbleSize,
                                    isMostTagged: isMostTagged,
                                    tagCount: tags,
                                    seed: index
                                )
                                .offset(drag)
                                .position(x: pos.x, y: pos.y)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffsets[friend.id] = value.translation
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                                dragOffsets[friend.id] = .zero
                                            }
                                        }
                                )
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedFriendForDetail = friend
                                }
                            }
                        }
                        .frame(width: availableSize.width, height: availableSize.height)
                    }
                }
                
                // Bottom Floating CTA Bar (clean floating button with NO gradient color block)
                bottomActionBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Friends")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.primary)
                        Text("\(store.friends.count) friends • Biggest bubble = Most tagged")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                // Simple circular close button in top right corner
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.secondarySystemBackground), in: Circle())
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $isShowingContactPicker) {
                ContactPickerView(
                    onSelectContacts: { contacts in
                        store.addFriendsFromContacts(contacts)
                        if contacts.count == 1, let name = contacts.first?.givenName {
                            showToast("Added \(name)")
                        } else if contacts.count > 1 {
                            showToast("Added \(contacts.count) friends")
                        }
                    }
                )
            }
            .sheet(item: $selectedFriendForDetail) { friend in
                FriendDetailSheet(friend: friend, store: store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .overlay(alignment: .top) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.85), in: Capsule())
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Safe Organic Positioning & Non-Overlapping Layout
    
    /// Calculate bubble diameter based on friend's tag frequency across all cards
    private func calculateBubbleSize(for friend: Friend) -> CGFloat {
        let tagCount = store.tagCount(for: friend.id)
        let maxCount = store.maxTagCount()
        
        let minSize: CGFloat = 68
        let maxSize: CGFloat = 112
        
        if maxCount == 0 {
            return 82
        }
        
        let ratio = CGFloat(tagCount) / CGFloat(maxCount)
        return minSize + (maxSize - minSize) * ratio
    }
    
    /// Computes organic positions for all friends with guaranteed separation so no bubbles overlap or go out of bounds
    private func computeBubblePositions(for friends: [Friend], sizes: [UUID: CGFloat], in containerSize: CGSize) -> [UUID: CGPoint] {
        let count = friends.count
        guard count > 0 else { return [:] }
        
        let topSafe: CGFloat = 20
        let bottomSafe: CGFloat = containerSize.height - 110
        let usableHeight = max(100, bottomSafe - topSafe)
        let centerX = containerSize.width / 2.0
        let centerY = topSafe + usableHeight / 2.0
        
        var positions: [UUID: CGPoint] = [:]
        
        if count == 1, let first = friends.first {
            positions[first.id] = CGPoint(x: centerX, y: centerY)
            return positions
        }
        
        // Initial dispersion in organic constellation patterns
        for (index, friend) in friends.enumerated() {
            let bSize = sizes[friend.id] ?? 80
            let radius = bSize / 2.0
            
            var basePos: CGPoint
            if index == 0 {
                // Prime upper-center position for most-tagged friend
                basePos = CGPoint(x: centerX, y: centerY - 25)
            } else {
                let totalOthers = max(1, count - 1)
                let otherIndex = index - 1
                let angleStep = (2.0 * .pi) / Double(totalOthers)
                let angle = 0.75 * .pi + Double(otherIndex) * angleStep
                let ringRadiusX = min(containerSize.width * 0.34, 130.0)
                let ringRadiusY = min(usableHeight * 0.38, 140.0)
                let x = centerX + CGFloat(cos(angle)) * ringRadiusX
                let y = centerY + CGFloat(sin(angle)) * ringRadiusY + 15
                basePos = CGPoint(x: x, y: y)
            }
            
            let labelPad: CGFloat = 24
            let minX = radius + 16
            let maxX = max(minX + 1, containerSize.width - radius - 16)
            let minY = topSafe + radius + 8
            let maxY = max(minY + 1, bottomSafe - radius - labelPad)
            
            positions[friend.id] = CGPoint(
                x: max(minX, min(maxX, basePos.x)),
                y: max(minY, min(maxY, basePos.y))
            )
        }
        
        // Relaxation loop: Repel any bubbles that are closer than (r1 + r2 + clearanceGap)
        let iterations = 24
        for _ in 0..<iterations {
            for i in 0..<count {
                let idI = friends[i].id
                guard var posI = positions[idI] else { continue }
                let radiusI = (sizes[idI] ?? 80) / 2.0
                
                for j in (i + 1)..<count {
                    let idJ = friends[j].id
                    guard var posJ = positions[idJ] else { continue }
                    let radiusJ = (sizes[idJ] ?? 80) / 2.0
                    
                    let minAllowedDist = radiusI + radiusJ + 16.0
                    var dx = posJ.x - posI.x
                    var dy = posJ.y - posI.y
                    var dist = hypot(dx, dy)
                    
                    if dist < 0.001 {
                        dx = 2.0
                        dy = 2.0
                        dist = hypot(dx, dy)
                    }
                    
                    if dist < minAllowedDist {
                        let overlap = minAllowedDist - dist
                        let nx = dx / dist
                        let ny = dy / dist
                        let move = overlap * 0.5
                        
                        posI.x -= nx * move
                        posI.y -= ny * move
                        posJ.x += nx * move
                        posJ.y += ny * move
                        
                        positions[idJ] = posJ
                    }
                }
                
                let labelPad: CGFloat = 24
                let minX = radiusI + 16
                let maxX = max(minX + 1, containerSize.width - radiusI - 16)
                let minY = topSafe + radiusI + 8
                let maxY = max(minY + 1, bottomSafe - radiusI - labelPad)
                
                posI.x = max(minX, min(maxX, posI.x))
                posI.y = max(minY, min(maxY, posI.y))
                positions[idI] = posI
            }
        }
        
        return positions
    }
    
    // MARK: - Subviews
    
    private var bottomActionBar: some View {
        Button {
            isShowingContactPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 17, weight: .bold))
                Text("Add from Contacts")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 24)
            .frame(height: 50)
            .background(Color.primary, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 6)
            
            Text("No Friends Yet")
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
            
            Text("Add friends from your contacts to see them float in your cosmos and tag them in your memories!")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func constellationLines(for friends: [Friend], positions: [UUID: CGPoint]) -> some View {
        Path { path in
            let points = friends.compactMap { positions[$0.id] }
            guard points.count >= 2 else { return }
            for i in 0..<(points.count - 1) {
                path.move(to: points[i])
                path.addLine(to: points[i + 1])
            }
        }
        .stroke(
            Color.black.opacity(0.10),
            style: StrokeStyle(lineWidth: 1.0, dash: [4, 6])
        )
        .allowsHitTesting(false)
    }
    
    private func showToast(_ text: String) {
        withAnimation {
            toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                if toastMessage == text {
                    toastMessage = nil
                }
            }
        }
    }
}

// MARK: - Floating Friend Bubble Item

struct FloatingBubbleItem: View {
    let friend: Friend
    let bubbleSize: CGFloat
    let isMostTagged: Bool
    let tagCount: Int
    let seed: Int
    
    // Self-contained subtle drifting state
    @State private var isDrifting = false
    
    var body: some View {
        VStack(spacing: 5) {
            // Main Bubble Sphere
            ZStack {
                // Outer Ambient Glow Ring (subtle)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (Color(hex: friend.favoriteColor) ?? .purple).opacity(0.24),
                                (Color(hex: friend.favoriteColor) ?? .purple).opacity(0.04),
                                .clear
                            ],
                            center: .center,
                            startRadius: bubbleSize * 0.4,
                            endRadius: bubbleSize * 0.58
                        )
                    )
                    .frame(width: bubbleSize * 1.18, height: bubbleSize * 1.18)
                
                // Translucent Glass Sphere Backdrop
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: bubbleSize, height: bubbleSize)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: isMostTagged
                                        ? [Color.purple.opacity(0.9), Color.yellow.opacity(0.9)]
                                        : [Color.white.opacity(0.85), Color.white.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isMostTagged ? 2.5 : 1.5
                            )
                    )
                    .shadow(
                        color: (Color(hex: friend.favoriteColor) ?? .black).opacity(0.12),
                        radius: 5,
                        x: 0,
                        y: 3
                    )
                
                // Friend Avatar / Memoji
                FriendAvatarView(friend: friend, size: bubbleSize * 0.82)
                
                // "Most Tagged" Crown Badge
                if isMostTagged {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.yellow)
                                .padding(5)
                                .background(Color.black.opacity(0.75), in: Circle())
                                .overlay(Circle().strokeBorder(Color.yellow, lineWidth: 1.2))
                                .shadow(radius: 2)
                                .offset(x: 2, y: -2)
                        }
                        Spacer()
                    }
                    .frame(width: bubbleSize, height: bubbleSize)
                }
            }
            
            // Name Capsule with High Contrast Crisp Styling
            HStack(spacing: 4) {
                Text(friend.resolvedDisplayName)
                    .font(.system(size: max(12, min(14, bubbleSize * 0.13)), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                if tagCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 8))
                        Text("\(tagCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.purple, in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 3, y: 1.5)
        }
        // Very slight, gentle floating motion (±2.5pt vertical, ±1.5pt horizontal)
        .offset(
            x: isDrifting ? floatXOffset : -floatXOffset,
            y: isDrifting ? floatYOffset : -floatYOffset
        )
        .animation(
            .easeInOut(duration: 2.8 + Double(seed % 4) * 0.4)
                .repeatForever(autoreverses: true),
            value: isDrifting
        )
        .onAppear {
            isDrifting = true
        }
    }
    
    private var floatXOffset: CGFloat {
        let offsets: [CGFloat] = [1.5, -1.8, 1.2, -1.5]
        return offsets[seed % offsets.count]
    }
    
    private var floatYOffset: CGFloat {
        let offsets: [CGFloat] = [-2.5, 2.8, -2.2, 2.5]
        return offsets[seed % offsets.count]
    }
}

// MARK: - Flow Layout for Tag Wrapping

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: width, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Friend Detail Sheet

struct FriendDetailSheet: View {
    let friend: Friend
    @Bindable var store: MemoryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAddingHobbyInline: Bool = false
    @State private var newHobbyText: String = ""
    @FocusState private var isHobbyInputFocused: Bool
    
    private var currentFriend: Friend {
        store.friends.first(where: { $0.id == friend.id }) ?? friend
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Large Avatar with floating hobby / interest bubbles around it
                    ZStack {
                        // Ambient Glow
                        Circle()
                            .fill((Color(hex: currentFriend.favoriteColor) ?? .purple).opacity(0.15))
                            .frame(width: 120, height: 120)
                            .blur(radius: 10)
                        
                        // Avatar Photo / Memoji
                        FriendAvatarView(friend: currentFriend, size: 104)
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        
                        // Floating hobby / interest bubbles around the photo
                        let hobbies = currentFriend.hobbyList
                        if hobbies.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isAddingHobbyInline = true
                                    isHobbyInputFocused = true
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.purple)
                                    Text("Add Hobby")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.primary)
                                }
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.purple.opacity(0.4), lineWidth: 1.2))
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                                .offset(x: 82, y: -34)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(Array(hobbies.prefix(6).enumerated()), id: \.offset) { index, hobby in
                                FloatingHobbyBubble(
                                    hobby: hobby,
                                    icon: iconForHobby(hobby),
                                    tintColor: Color(hex: currentFriend.favoriteColor) ?? .purple,
                                    offset: hobbyOffset(index: index, total: min(hobbies.count, 6)),
                                    seed: index
                                )
                            }
                        }
                    }
                    .frame(height: 140)
                    .padding(.top, 14)
                    
                    // Name & Details
                    VStack(spacing: 4) {
                        Text(currentFriend.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                        
                        if !currentFriend.displayName.isEmpty && currentFriend.displayName != currentFriend.name {
                            Text("\"\(currentFriend.displayName)\"")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    
                    // Tags & Memories Stat Pill (Clean Solid Cards)
                    let count = store.tagCount(for: currentFriend.id)
                    HStack(spacing: 14) {
                        VStack(spacing: 3) {
                            Text("\(count)")
                                .font(.title3.bold())
                                .foregroundStyle(Color.purple)
                            Text("Total Tags")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        
                        let memoryCount = store.cardsFeaturingFriend(currentFriend.id).count
                        VStack(spacing: 3) {
                            Text("\(memoryCount)")
                                .font(.title3.bold())
                                .foregroundStyle(Color.blue)
                            Text("Cards")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Hobbies & Interests Card (Add / Remove Hobbies with Text)
                    hobbiesCard
                    
                    // Information from Contacts (Note/Role removed, only Birthday, Phone, Email)
                    let hasDetails = !currentFriend.birthday.isEmpty || (currentFriend.phoneNumber != nil && !currentFriend.phoneNumber!.isEmpty) || (currentFriend.email != nil && !currentFriend.email!.isEmpty)
                    if hasDetails {
                        VStack(alignment: .leading, spacing: 14) {
                            if !currentFriend.birthday.isEmpty {
                                detailRow(icon: "birthday.cake.fill", title: "Birthday", value: currentFriend.birthday, tint: .pink)
                            }
                            
                            if let phone = currentFriend.phoneNumber, !phone.isEmpty {
                                detailRow(icon: "phone.fill", title: "Phone", value: phone, tint: .green)
                            }
                            
                            if let email = currentFriend.email, !email.isEmpty {
                                detailRow(icon: "envelope.fill", title: "Email", value: email, tint: .blue)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Cards featuring this friend
                    let featuredCards = store.cardsFeaturingFriend(currentFriend.id)
                    if !featuredCards.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tagged in Cards")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(featuredCards) { card in
                                        Button {
                                            store.selectedCardID = card.id
                                            dismiss()
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(card.title)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(Color.primary)
                                                    .lineLimit(1)
                                                Text("Day \(card.day)")
                                                    .font(.caption.weight(.medium))
                                                    .foregroundStyle(Color.secondary)
                                            }
                                            .padding(12)
                                            .frame(width: 140, alignment: .leading)
                                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                                            .shadow(color: .black.opacity(0.04), radius: 3, y: 1.5)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Delete Friend Option
                    Button(role: .destructive) {
                        store.deleteFriend(id: currentFriend.id)
                        dismiss()
                    } label: {
                        Label("Remove Friend", systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Friend Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                }
            }
        }
    }
    
    // MARK: - Hobbies & Interests View Section
    
    private var hobbiesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.purple)
                    .font(.subheadline.bold())
                Text("Hobbies & Interests")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isAddingHobbyInline.toggle()
                        if isAddingHobbyInline {
                            isHobbyInputFocused = true
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAddingHobbyInline ? "xmark" : "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text(isAddingHobbyInline ? "Cancel" : "Add Hobby")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Inline text input to add friend's hobbies
            if isAddingHobbyInline {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Photography, Hiking, Coffee...", text: $newHobbyText)
                            .font(.subheadline)
                            .focused($isHobbyInputFocused)
                            .onSubmit {
                                submitNewHobby()
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    
                    Button {
                        submitNewHobby()
                    } label: {
                        Text("Add")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                newHobbyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray.opacity(0.4)
                                : Color.purple,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(newHobbyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Interactive tags with dynamic icons and delete buttons
            let hobbies = currentFriend.hobbyList
            if hobbies.isEmpty {
                Text("No hobbies added yet. Tap \"Add Hobby\" to add interests that will float around their photo!")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .padding(.vertical, 2)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(hobbies, id: \.self) { hobby in
                        HStack(spacing: 6) {
                            Image(systemName: iconForHobby(hobby))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: currentFriend.favoriteColor) ?? .purple)
                            
                            Text(hobby)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    store.removeHobby(from: currentFriend.id, hobby: hobby)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground), in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
    
    private func submitNewHobby() {
        let trimmed = newHobbyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            store.addHobby(to: currentFriend.id, hobby: trimmed)
            newHobbyText = ""
            isAddingHobbyInline = false
        }
    }
    
    private func detailRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
    }
    
    private func hobbyOffset(index: Int, total: Int) -> CGSize {
        switch total {
        case 1:
            return CGSize(width: 86, height: -36)
        case 2:
            return index == 0 ? CGSize(width: -88, height: -36) : CGSize(width: 88, height: 36)
        case 3:
            if index == 0 { return CGSize(width: -88, height: -36) }
            if index == 1 { return CGSize(width: 88, height: -36) }
            return CGSize(width: 88, height: 36)
        case 4:
            if index == 0 { return CGSize(width: -88, height: -36) }
            if index == 1 { return CGSize(width: 88, height: -36) }
            if index == 2 { return CGSize(width: -88, height: 36) }
            return CGSize(width: 88, height: 36)
        default:
            let angle = Double(index) * (2.0 * .pi / Double(total)) - .pi / 4.0
            return CGSize(width: cos(angle) * 92.0, height: sin(angle) * 55.0)
        }
    }
    
    private func iconForHobby(_ hobby: String) -> String {
        let lower = hobby.lowercased()
        if lower.contains("photo") || lower.contains("camera") { return "camera.fill" }
        if lower.contains("travel") || lower.contains("trip") { return "airplane" }
        if lower.contains("coffee") || lower.contains("espresso") { return "cup.and.saucer.fill" }
        if lower.contains("arch") { return "building.columns.fill" }
        if lower.contains("paint") || lower.contains("art") { return "paintpalette.fill" }
        if lower.contains("music") || lower.contains("record") || lower.contains("vinyl") { return "music.note" }
        if lower.contains("hike") || lower.contains("hiking") || lower.contains("nature") { return "figure.hiking" }
        if lower.contains("food") || lower.contains("cook") { return "fork.knife" }
        if lower.contains("read") || lower.contains("book") { return "book.fill" }
        if lower.contains("sport") || lower.contains("run") || lower.contains("gym") { return "figure.run" }
        return "sparkles"
    }
}

// MARK: - Floating Hobby Bubble Item

struct FloatingHobbyBubble: View {
    let hobby: String
    let icon: String
    let tintColor: Color
    let offset: CGSize
    let seed: Int
    
    @State private var isDrifting = false
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tintColor)
            
            Text(hobby)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .overlay(
            Capsule().strokeBorder(tintColor.opacity(0.4), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .offset(offset)
        .offset(y: isDrifting ? -3.0 : 3.0)
        .animation(
            .easeInOut(duration: 2.2 + Double(seed % 3) * 0.4)
                .repeatForever(autoreverses: true),
            value: isDrifting
        )
        .onAppear {
            isDrifting = true
        }
    }
}
