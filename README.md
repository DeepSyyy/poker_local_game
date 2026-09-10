# Texas Hold'em Poker Chip Simulator

A virtual chip manager and table simulator for Texas Hold'em poker built with Flutter. Designed specifically for casual, in-person home games with physical playing cards, eliminating the need for physical chip sets while maintaining zero real-money gambling mechanics.

---

## Overview

### Shared Table Mode
Place a smartphone or tablet flat in the center of the table. The application acts as a shared digital felt and chip tray, allowing each player around the physical table to track pot sizes, view current betting streets, and execute betting actions on their respective turns.

---

## Key Features

### 1. Flexible Table Setup (2–8 Players)
- **Player Capacity**: Supports 2 to 8 players with balanced perimeter seat positioning.
- **Customization**: Customizable player names to match real-life participants.
- **Starting Stack**: Presets for starting chip counts (500, 1,000, 2,000, 5,000 chips) or custom amounts.
- **Blind Structure**: Configurable Small Blind (SB) and Big Blind (BB) automation, with an option for casual play without forced blinds.

### 2. Standard Texas Hold'em Betting Engine
- **Dealer Button Rotation**: Automatic clockwise progression of the Dealer (`D`), Small Blind (`SB`), and Big Blind (`BB`) positions each hand.
- **Betting Actions**:
  - **Check**: Validated only when no bet increase has occurred in the active street.
  - **Call**: Matches the current table bet, displaying the exact chip deduction.
  - **Raise**: Two-column landscape dialog featuring a responsive slider, steppers, and quick presets (Min Raise, 2x, 3x, Half Pot, Full Pot, All-in).
  - **Fold**: Forfeits the current hand (automatically awards the pot if only one player remains).
  - **All-In**: Commits all remaining player chips to the pot.
- **Street Progression**: Automatic phase transitions from Pre-Flop to Flop (3 community cards), Turn (4th card), River (5th card), and Showdown.
- **Dynamic Pot & Side Pot Engine**: Calculates main pots and side pots accurately when players commit all-in bets at varying stack depths.

### 3. Showdown & Pot Distribution
- Intuitive winner selection interface for main pots and all generated side pots.
- Supports split-pot distribution for tied hand evaluations.
- Single-tap "Next Hand" action to automatically rotate the dealer button, post blinds, and initiate the next round.

### 4. Landscape Interface & User Experience
- **Fullscreen Immersive Mode**: Uses `SystemUiMode.immersiveSticky` to hide status and system navigation bars, maximizing active display area.
- **Floating HUD Layout**:
  - Unbroken 100% table felt coverage across the landscape screen.
  - Floating status capsules in upper corners for blinds and table management.
  - Slim floating action dock positioned at the bottom edge.
- **Optimized Heads-Up Alignment**: For two-player games, seats are positioned on the far left and far right to prevent vertical crowding.
- **Mid-Session Rebuy**: Allows eliminated or low-stack players to top up chips without restarting the table.
- **Action History Audit**: Comprehensive log of all bets, raises, folds, and blind posts throughout the session.

---

## Project Structure

```
lib/
├── app.dart                                # Root MaterialApp configuration & theme setup
├── main.dart                               # Entry point, orientation lock, & immersive mode
├── controllers/
│   └── poker_game_controller.dart          # Core Texas Hold'em rules engine & state management
├── core/
│   ├── constants/
│   │   └── app_colors.dart                 # Poker theme palette (table felt, chips, actions)
│   └── theme/
│       └── app_theme.dart                  # Material 3 dark theme definitions
├── models/
│   ├── poker_player.dart                   # Player entity, stack values, and status tracking
│   └── poker_game_state.dart               # Betting streets, pot entities, and action log models
└── screens/
    └── poker/
        ├── setup_screen.dart               # Table setup and player configuration view
        ├── table_screen.dart               # Main landscape table and seating interface
        └── widgets/
            ├── player_seat_widget.dart     # Player seat badge and stack card
            ├── table_center_widget.dart    # Center pot display, street indicator, and hand controls
            ├── poker_action_bar.dart       # Floating player action dock
            ├── raise_dialog.dart           # Two-column landscape raise slider modal
            ├── showdown_dialog.dart        # Winner selection and pot distribution dialog
            ├── rebuy_dialog.dart           # Stack top-up modal
            └── action_history_sheet.dart   # Hand history audit sheet
```

---

## Getting Started

### Prerequisites
- Flutter SDK (v3.13.0 or higher)
- Android / iOS Device or Emulator, or modern Web Browser

### Running in Development
```bash
flutter pub get
flutter run
```

### Running in Standalone Release Mode (Android)
To run fully optimized without an active USB debugging connection:
```bash
flutter run --release
```

### Building the Android APK
```bash
flutter build apk --split-per-abi
```
Generated binaries will be located at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Automated Deployment to GitHub Pages
This repository includes an automated GitHub Actions deployment workflow in `.github/workflows/deploy.yml`.

To deploy:
1. In your GitHub repository, navigate to **Settings** > **Pages**.
2. Under **Build and deployment** > **Source**, select **GitHub Actions**.
3. Pushing commits to the `main` branch will automatically compile Flutter Web and publish the application to:
   `https://adyasena.github.io/belajar_flutter/`

---

## Verification and Testing

Execute the unit and widget test suite:
```bash
flutter test
```

Perform static analysis:
```bash
flutter analyze
```

---

## License
This project is open-source and intended solely for recreational home use and educational purposes. No real-money gambling or wagering services are provided.
