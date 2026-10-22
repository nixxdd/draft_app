# BuddyBook
## Memory Scrapbook & Visual Diary

**BuddyBook** is a tactile, multimedia digital scrapbook and visual diary. It lets users to capture, design, and explore life moments through customizable memory cards.

- Github link : 

---

## Core App Purpose

- **Preserve Life Moments**: Transform photos, voice notes, songs, locations, and notes into visual memory cards.
- **Relive Memories Seamlessly**: Navigate memories chronologically with the timeline.
- **Social Memory Graph**: Connect memories to friends, tracking shared experiences and personal interests.

---

## Key Features

### Memory Cards
- **Cards Navigation**: Swipe horizontally to browse through cards.
- **Cards organization**: Cards are organized chronologically in the timeline. If more cards are added for the same day, they will pile up on the date and the user can click on them to change the current view (by default the most recent one will be showed).
- **Slide-to-Create Memory**: Sliding past the last card presents a date picker prompt. Selecting any date (including past dates) creates a new blank card and automatically reorders all cards chronologically.
- **One-Tap Editing**: Tap **Edit** to transition directly into the freeform canvas studio.

### Cards Editor (`CanvasView`, it is called like that even though we did not use the Canvas component but simpler ZStacks :))
- **Drag, Rotate & Scale**: Freely position stickers, photos, audio clips, and notes anywhere on the canvas card.
- **Trash Drop Zone**: Drag any item to the bottom trash zone with haptic feedback to delete.
- **Clipboard & Reordering**: Cut, copy, paste, and adjust Z-index layering for scrapbook depth.

### Multimedia Elements
- **Photos & Polaroids**: Add photos from the library with custom captions and vintage Polaroid frames.
- **Audio Voice Notes**: Built-in voice recorder with live waveform visualization and tap-to-play playback.
- **Music Embeds**: Styled music previews with animated equalizer bars (also videos but we need to improve it).
- **Interactive Maps & Pins**: Geotag locations with Apple Maps previews and custom pin placement.
- **Stickers & Emojis**: Categorized emoji drawer with scalable sticker stamps.
- **Text & Tape Labels**: Rotatable tape labels, handwritten notes, and styled typography.
- **Files & Web Links**: Attached documents with QuickLook preview and clickable website bookmarks.

### Friends & Floating Social Graph (`FriendsBubbleView`)
- **Physics-Inspired Floating Bubbles**: Friends float organically in a dynamic bubble cluster.
- **Tag-Weighted Sizing**: The friend tagged the most across your memory cards automatically appears as the largest bubble.
- **Contacts Integration**: Import friends directly from Apple Contacts with automatic photo/Memoji, birthday, and phone number retrieval.
- **Friend Detail Profile**:
  - View contact details, birthday, and tagged card count.
  - **Hobbies & Interests**: Add custom hobbies as interactive chips, which float as satellite bubbles around the friend's avatar.
  - Filter and view all memory cards featuring that friend.
---

## Architecture & Tech Stack

| Layer | Technologies |
|---|---|
| **Framework** | SwiftUI, Observation (`@Observable`) |
| **Media & Audio** | AVFoundation (`AVAudioRecorder`, `AVPlayer`), QuickLook |
| **System Integrations** | Contacts (`CNContactPickerViewController`), MapKit |
| **Data Architecture** | `MemoryStore`, `MemoryCard`, `CanvasItem`, `Friend` |
