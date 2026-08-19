# ChequeMate

> Split the tab. Settle it. Checkmate.

ChequeMate is a group-expense app for iOS 26 that turns the post-night-out math argument into a two-tap ritual — and then roasts everyone involved.

Built entirely with Apple-native frameworks in SwiftUI, styled with the **Liquid Dusk** design system (deep black glass, warm peach energy, mint + coral accents).

## What it does

- **Squad** — Add your friends and log who paid for what. Live totals and per-head share update as you go.
- **Settle** — One tap computes who owes whom with the fewest possible transfers. Track who's paid up and who's still dodging.
- **The Roast** — Context-aware commentary on your actual numbers. Three moods: **Roast**, **Wholesome**, or **Stoic**. Reroll as many takes as you want.

## Features

- Equal-share splitting with minimal-transaction settlement math
- "Still to pay" tracking with one-tap Mark Paid
- Local-first — everything is stored on-device, no accounts, no data leaving your phone
- 4 currencies (₹, $, €, £) with Indian number formatting
- Haptics, glass cards, particle-clean visuals, and a demo squad for instant exploration

## Tech stack

- SwiftUI + iOS 26 Liquid Glass
- Foundation / Combine / UserDefaults for the local store
- A small deterministic comedy engine for the roast generator

## Getting started

1. Open in Xcode 26
2. Build for the iOS 26 simulator or a device
3. Tap "Load example squad" or add your own people and expenses

## Structure

```
Sources/
├── ChequeMateApp.swift   # App entry, store, haptics, tabs
├── Models.swift          # People, expenses, settlement engine
├── SassEngine.swift      # The roast generator
├── SquadView.swift       # Friends + expenses
├── SettleView.swift      # Balances + mark paid
├── RoastView.swift       # The commentary
└── DesignSystem.swift    # Liquid Dusk design system

Made by Subhansh