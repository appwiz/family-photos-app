# Family Photos

A native SwiftUI slideshow app for iPhone and iPad that displays photos and videos from your iCloud shared albums.

---

## Table of Contents

- [Features](#features)
- [For Users – Installing on Your Device](#for-users--installing-on-your-device)
- [For Developers – Building & Testing](#for-developers--building--testing)
- [Configuration (Settings App)](#configuration-settings-app)
- [Requirements](#requirements)

---

## Features

- 📸 **Slideshow** – Displays photos from an iCloud shared album in random order
- 🎬 **Video support** – Auto-plays videos inline; can be disabled in Settings
- ⏱ **Configurable delay** – Set slide duration (1–30 seconds) via the iOS Settings app
- 🔄 **Portrait & landscape** – Full rotation support on iPhone and iPad
- 👆 **Gesture controls** – Swipe left/right to navigate; tap to show/hide playback controls
- 🎨 **Native iOS look** – Apple materials, system fonts, and SF Symbols

---

## For Users – Installing on Your Device

### Option A: TestFlight (Easiest)

1. Ask the developer to add you to the TestFlight build.
2. Install **TestFlight** from the App Store on your iPhone or iPad.
3. Open the invitation link sent to your email.
4. Tap **Install** inside TestFlight.

### Option B: Install via Xcode (Sideloading)

> Requires a Mac with Xcode installed and a free or paid Apple Developer account.

1. Clone or download this repository to your Mac.
2. Open `FamilyPhotos.xcodeproj` in Xcode.
3. Connect your iPhone or iPad to your Mac with a cable (or use Wireless pairing).
4. Select your device as the build target in the Xcode toolbar.
5. In Xcode, go to **Signing & Capabilities** → set your Team to your Apple ID.
6. Press **▶ Run** (⌘R) to build and install.
7. On your device, go to **Settings → General → VPN & Device Management** and trust your developer certificate.

### Setting Up a Shared Album

Before using the app, make sure you have subscribed to an iCloud shared album:

1. On your iPhone or iPad, open the **Photos** app.
2. Tap **Albums** → scroll down to **Shared Albums**.
3. If you haven't joined a shared album yet, open the invitation link (e.g., `https://www.icloud.com/photos/#...`) in Safari — it will prompt you to subscribe.
4. Once subscribed, the album appears in the Family Photos app automatically.

---

## For Developers – Building & Testing

### Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 15.0 or later |
| iOS SDK | 16.0+ |
| macOS | Ventura (13.0) or later |
| Apple Developer Account | Free (for device builds) or Paid (for App Store/Xcode Cloud) |

### Opening the Project

```bash
git clone https://github.com/appwiz/family-photos-app.git
cd family-photos-app
open FamilyPhotos.xcodeproj
```

### First-Time Setup

1. Open `FamilyPhotos.xcodeproj` in Xcode.
2. Select the **FamilyPhotos** target → **Signing & Capabilities**.
3. Set **Team** to your Apple Developer team.
4. Change **Bundle Identifier** if needed (default: `com.familyphotos.app`).
5. Add your 1024×1024 app icon PNG to `FamilyPhotos/Assets.xcassets/AppIcon.appiconset/` (see [TASKS.md](TASKS.md)).

### Building

Select a simulator or physical device in the toolbar and press **⌘R** or click **▶ Run**.

### Running UI Tests

```
⌘U  →  runs all tests in FamilyPhotosUITests
```

Or in the terminal (requires `xcodebuild`):

```bash
xcodebuild test \
  -project FamilyPhotos.xcodeproj \
  -scheme FamilyPhotos \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

### Project Structure

```
FamilyPhotos.xcodeproj/        Xcode project
FamilyPhotos/
  FamilyPhotosApp.swift        App entry point
  ContentView.swift            Root view & permission routing
  Views/
    SlideshowView.swift        Fullscreen slideshow
    AlbumPickerView.swift      Album selection
    PhotoItemView.swift        Single photo display
    VideoPlayerView.swift      Video playback
  Models/
    PhotoLibraryManager.swift  PhotoKit wrapper
    SettingsManager.swift      UserDefaults / Settings bridge
  Assets.xcassets/             App icon & accent color
  Settings.bundle/             Settings.app integration
  Info.plist                   App metadata & permissions
  FamilyPhotos.entitlements    iCloud entitlement
FamilyPhotosUITests/           UI test targets
ARCHITECTURE.md                Architecture documentation
TASKS.md                       Outstanding tasks
TRANSCRIPT.md                  Prompt transcript
```

### Xcode Cloud

1. Open your project in Xcode → **Product → Xcode Cloud → Create Workflow**.
2. Select the **FamilyPhotos** scheme.
3. Configure start conditions (e.g., push to `main`).
4. Add a **Test** action using the **FamilyPhotos** scheme.
5. Add an **Archive** action for distribution.

The shared scheme is pre-configured for Xcode Cloud builds.

---

## Configuration (Settings App)

Open **Settings → Family Photos** on your device:

| Setting | Default | Description |
|---------|---------|-------------|
| **Photo Delay (seconds)** | 5 | How long each photo is displayed (1–30 sec) |
| **Autoplay Videos** | On | Whether videos play automatically in the slideshow |

Changes take effect immediately — no app restart required.

---

## Requirements

- iOS 16.0 or later
- iPhone or iPad
- An iCloud account with at least one shared album subscribed in the Photos app
- Photo Library access permission granted to Family Photos