# Huewaves

An iOS app that turns the world around you into music.

**Swift Student Challenge 2026 submission** â€” built entirely in SwiftUI with Apple-native frameworks only.

## What it does

- **See â†’ Hear** â€” Point your camera at any color and hear it as a unique musical note
- **Hear â†’ See** â€” Capture any sound and watch it transform into living particle art  
- **Feel â†’ Move** â€” Your heartbeat becomes haptic patterns and rhythmic visuals

## Tech stack

- **SwiftUI** â€” the entire UI
- **AVFoundation** â€” real camera hue reading + live microphone analysis
- **Core Haptics** â€” heartbeat, rain, ocean, rhythm patterns
- **12-TET** â€” hue-to-frequency mapping
- **Obsidian glass** â€” dark warm aesthetic with gold + rose accents

## Getting started

1. Open in Xcode 26 or Swift Playgrounds 4.6
2. Build for iOS 26
3. Point camera at colors, make music

## Project structure

```
apple/
â”œâ”€â”€ download/Huewaves.swiftpm/   # iOS app source (Swift)
â”œâ”€â”€ src/                             # Landing page (Next.js)
â”‚   â”œâ”€â”€ app/page.tsx                 # Main landing page
â”‚   â”œâ”€â”€ app/globals.css              # Design system
â”‚   â””â”€â”€ components/Guestbook.tsx     # Feedback form
â”œâ”€â”€ prisma/                          # Database schema
â””â”€â”€ public/                          # Static assets
```

## Running locally

```bash
npm install
npm run dev
# Open http://localhost:3000
```

## License

Made by Subhansh â€” [subhansh.dev](https://subhansh.dev)
