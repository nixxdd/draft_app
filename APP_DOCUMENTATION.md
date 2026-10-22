# Draft App — Memory Scrapbook & Visual Diary

**Draft App** is a tactile, multimedia digital scrapbook and visual diary built natively for iOS with SwiftUI. It empowers users to capture, design, and explore life moments through customizable memory cards, a collapsible timeline, and a floating social graph connecting friends to shared experiences.

---

## 🌟 Core App Purpose

- **Preserve Life Moments**: Transform photos, voice notes, songs, locations, and notes into visual scrapbook cards.
- **Relive Memories Seamlessly**: Navigate memories chronologically with gestures and an adaptive timeline.
- **Social Memory Graph**: Connect memories to friends, tracking shared experiences and personal interests.

---

## 🚀 Key Features

### 1. 📖 Memories Slide & Scrapbook Cards
- **Gesture Slide Navigation**: Swipe horizontally to browse through cards with native iOS paging physics.
- **Dynamic Resizing**: When the timeline is revealed, the canvas card automatically contracts to fit above it without being obscured; when the timeline is dismissed, the card smoothly expands back to full screen.
- **Slide-to-Create Memory**: Sliding past the last card presents a date picker prompt. Selecting any date (including past dates) creates a new blank card and automatically reorders all cards chronologically.
- **One-Tap Editing**: Tap **Edit** to transition directly into the freeform canvas studio.

### 2. 🗓️ Collapsible Timeline Strip
- **Hidden by Default**: Keeps the focus on full-screen scrapbook cards.
- **Gesture Controls**:
  - **Swipe Up / Tap Pill**: Expands the compact timeline below the card.
  - **Drag Down on Grab Handle**: Smoothly collapses the timeline back.
- **Two-Way Synchronization**: Swiping cards automatically highlights the active day and centers the card in the timeline.
- **Compact Filmstrip**: Miniature live previews of cards with day badges and multi-card stack count indicators (`"1/2"`).

### 3. 🎨 Freeform Canvas Editor (`CanvasView`)
- **Drag, Rotate & Scale**: Freely position stickers, photos, audio clips, and notes anywhere on the canvas card.
- **Trash Drop Zone**: Drag any item to the bottom trash zone with haptic feedback to delete.
- **Clipboard & Reordering**: Cut, copy, paste, and adjust Z-index layering for scrapbook depth.

### 4. 📎 Multimedia Elements
- **Photos & Polaroids**: Add photos from the library with custom captions and vintage Polaroid frames.
- **Audio Voice Notes**: Built-in voice recorder with live waveform visualization and tap-to-play playback.
- **Music Embeds**: Styled music previews with animated equalizer bars.
- **Videos**: In-canvas video clips with inline playback controls.
- **Interactive Maps & Pins**: Geotag locations with Apple Maps previews and custom pin placement.
- **Stickers & Emojis**: Categorized emoji drawer with scalable sticker stamps.
- **Text & Tape Labels**: Rotatable washi tape labels, handwritten notes, and styled typography.
- **Files & Web Links**: Attached documents with QuickLook preview and clickable website bookmarks.

### 5. 👥 Friends & Floating Social Graph (`FriendsBubbleView`)
- **Physics-Inspired Floating Bubbles**: Friends float organically in a dynamic bubble cluster.
- **Tag-Weighted Sizing**: The friend tagged the most across your memory cards automatically appears as the largest bubble.
- **Contacts Integration**: Import friends directly from Apple Contacts with automatic photo/Memoji, birthday, and phone number retrieval.
- **Friend Detail Profile**:
  - View contact details, birthday, and tagged card count.
  - **Hobbies & Interests**: Add custom hobbies as interactive chips, which float as satellite bubbles around the friend's avatar.
  - Filter and view all memory cards featuring that friend.

### 6. 🌓 Adaptive Light & Dark Mode
- Built using **`SketchTheme`** with dynamic semantic gradients, glassmorphic blur materials, and high-contrast typography across both Light and Dark modes.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technologies |
|---|---|
| **Framework** | SwiftUI, Observation (`@Observable`) |
| **Media & Audio** | AVFoundation (`AVAudioRecorder`, `AVPlayer`), QuickLook |
| **System Integrations** | Contacts (`CNContactPickerViewController`), MapKit |
| **Data Architecture** | `MemoryStore`, `MemoryCard`, `CanvasItem`, `Friend` |
