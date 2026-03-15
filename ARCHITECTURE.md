# Architecture

## Overview

**Family Photos** is a native SwiftUI app for iPhone and iPad that displays photos and videos from iCloud shared albums as a fullscreen slideshow.

```
┌──────────────────────────────────────────────────────────┐
│                        App Entry                         │
│                   FamilyPhotosApp.swift                  │
│                     (@main WindowGroup)                  │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                      ContentView                         │
│   Manages top-level navigation state:                    │
│   • Permission not determined → PermissionRequestView    │
│   • Permission denied → PermissionDeniedView             │
│   • No album selected → AlbumPickerView                  │
│   • Album selected → SlideshowView                       │
└──────────────┬───────────────────────────┬───────────────┘
               │                           │
               ▼                           ▼
┌──────────────────────┐     ┌──────────────────────────────┐
│   AlbumPickerView    │     │       SlideshowView          │
│                      │     │                              │
│  Lists all available │     │  Fullscreen slideshow:       │
│  iCloud shared       │     │  • Random-ordered PHAssets   │
│  albums and regular  │     │  • Auto-advance timer        │
│  albums from         │     │  • Swipe left/right          │
│  PhotoKit.           │     │  • Tap to show/hide controls │
│                      │     │  • Play/pause/next/prev      │
└──────────────────────┘     └──────────┬──────────────────┘
                                        │
                           ┌────────────┴────────────┐
                           ▼                         ▼
               ┌─────────────────────┐   ┌─────────────────────┐
               │   PhotoItemView     │   │   VideoPlayerView   │
               │                     │   │                     │
               │  Async loads full-  │   │  Loads PHAsset as   │
               │  resolution image   │   │  AVPlayerItem via   │
               │  via PHImageManager │   │  PHImageManager.    │
               │                     │   │  Autoplay option.   │
               └─────────────────────┘   └─────────────────────┘
```

## Layers

### UI Layer (SwiftUI Views)

| File | Responsibility |
|------|---------------|
| `FamilyPhotosApp.swift` | App entry point, single `WindowGroup` |
| `ContentView.swift` | Root view; routes to permission, picker, or slideshow |
| `Views/AlbumPickerView.swift` | Album selection list with thumbnail previews |
| `Views/SlideshowView.swift` | Fullscreen slideshow engine with timer, gestures, controls |
| `Views/PhotoItemView.swift` | Async image loader and display for a single photo |
| `Views/VideoPlayerView.swift` | AVKit video player for PHAsset videos |

### Data / Model Layer

| File | Responsibility |
|------|---------------|
| `Models/PhotoLibraryManager.swift` | PhotoKit wrapper; authorization, album fetching, asset fetching, library change observation |
| `Models/SettingsManager.swift` | UserDefaults wrapper; observes changes from Settings app in real time |

### Resources

| Resource | Responsibility |
|----------|---------------|
| `Assets.xcassets` | App icon (1024×1024 universal) and accent color |
| `Settings.bundle/Root.plist` | Settings.app integration — slideshow delay slider and autoplay toggle |
| `Info.plist` | NSPhotoLibraryUsageDescription, supported orientations, scene manifest |
| `FamilyPhotos.entitlements` | iCloud/CloudKit entitlement for shared album access |

## Key Design Patterns

### State Management
- `PhotoLibraryManager` is a `@StateObject` in `ContentView`, passed down as `@ObservedObject`.
- `SettingsManager.shared` is a singleton observed with `@ObservedObject` in `SlideshowView`.
- `@AppStorage("selectedAlbumIdentifier")` persists the chosen album across launches.

### Async Image Loading
`PhotoItemView` uses `.task(id: asset.localIdentifier)` so the load task is automatically cancelled and restarted when the displayed asset changes. `PHImageManager.requestImage` is bridged to Swift concurrency via `withCheckedContinuation`, skipping degraded/thumbnail responses.

### Slideshow Timer
The `Timer` in `SlideshowView` is invalidated and recreated on each advance to ensure the configured delay is always respected. It also restarts when the user manually navigates via swipe or buttons.

### Settings Integration
`SettingsManager` registers `UserDefaults` defaults (so values are correct before the user ever visits Settings), then subscribes to `UserDefaults.didChangeNotification` to pick up changes made in the Settings app without requiring an app restart.

### Video Playback
`VideoPlayerView` requests an `AVPlayerItem` from PhotoKit (network-enabled for iCloud content) and uses `AVKit.VideoPlayer` for the UI. An `NSNotification` observer on `.AVPlayerItemDidPlayToEndTime` fires the `onPlaybackEnded` callback, which the parent `SlideshowView` uses to advance to the next asset.

## Data Flow

```
Settings.app
    │  UserDefaults.didChangeNotification
    ▼
SettingsManager.shared
    │  @Published slideshowDelay / autoPlayVideos
    ▼
SlideshowView  ──── timer interval ────►  advanceToNext()
    │                                          │
    │  PHAsset                                 │  index++
    ▼                                          ▼
PhotoItemView / VideoPlayerView          assets[currentIndex]
    │
    │  PHImageManager (PhotoKit)
    ▼
iCloud Photos network fetch
```

## iCloud Shared Album Access

The app uses `PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options:)` to retrieve shared albums that have been subscribed to on the device. Users subscribe via the Photos app by tapping the shared album link (e.g., `https://www.icloud.com/photos/#...`).

PhotoKit handles all CloudKit/iCloud networking transparently, including caching and background fetching.

## Supported Platforms

- **iOS / iPadOS 16.0+**
- iPhone (all orientations)
- iPad (all orientations)
- Xcode 15+, Swift 5.9

## Xcode Cloud

The shared scheme `FamilyPhotos.xcscheme` is configured with:
- **Build**: FamilyPhotos target
- **Test**: FamilyPhotosUITests
- **Archive**: Release configuration

Xcode Cloud will use automatic signing; you must configure the workflow in App Store Connect to set the correct team ID and provisioning profile.
