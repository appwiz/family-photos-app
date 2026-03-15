# TASKS

These are the items that require your input or action before the app is fully production-ready.

---

## 🔴 Required Before Building

### 1. Configure Code Signing

**What**: Set your Apple Developer Team ID in the Xcode project.

**How**:
1. Open `FamilyPhotos.xcodeproj` in Xcode.
2. Select the **FamilyPhotos** target in the project navigator.
3. Go to the **Signing & Capabilities** tab.
4. Set **Team** to your Apple Developer account.
5. Optionally update the **Bundle Identifier** from `com.familyphotos.app` to one that matches your developer account (e.g., `com.yourname.familyphotos`).
6. Repeat for the **FamilyPhotosUITests** target.

---

### 2. Add App Icon

**What**: Provide a 1024×1024 PNG app icon.

**How**:
1. Create or commission a 1024×1024 pixel PNG image for your app icon (no alpha/transparency, no rounded corners — Apple adds those).
2. In Xcode, open `FamilyPhotos/Assets.xcassets`.
3. Click on **AppIcon**.
4. Drag your 1024×1024 PNG into the **1x** (iOS App Icon) slot.
5. Xcode will generate all required sizes automatically.

Alternatively, copy the file as `AppIcon.png` and add it to `FamilyPhotos/Assets.xcassets/AppIcon.appiconset/`, then update the `Contents.json` to reference it:
```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

---

## 🟡 Required for App Store / TestFlight

### 3. Enable iCloud Entitlements

**What**: The `FamilyPhotos.entitlements` file includes the iCloud/CloudKit entitlement. To use this, you must:

1. Enable **iCloud** capability in your Apple Developer portal for your App ID.
2. Enable the **CloudKit** service for your App ID.
3. In Xcode → **Signing & Capabilities** → **+ Capability** → **iCloud** → check **CloudKit**.

If you only use PhotoKit (not direct CloudKit API calls), you can safely remove the `FamilyPhotos.entitlements` file and the `CODE_SIGN_ENTITLEMENTS` build setting — PhotoKit shared album access does not require a CloudKit entitlement.

---

### 4. Set Up Xcode Cloud Workflow

**What**: Configure Xcode Cloud to build, test, and distribute the app automatically.

**How**:
1. In Xcode, go to **Product → Xcode Cloud → Create Workflow**.
2. Select the **FamilyPhotos** scheme.
3. Configure a **Start Condition** (e.g., push to `main` branch).
4. Add a **Build** action (Debug or Release).
5. Add a **Test** action with the **FamilyPhotosUITests** bundle.
6. Add an **Archive & Distribute** action for TestFlight or App Store.
7. Set up post-actions for TestFlight distribution if desired.

---

### 5. Privacy Manifest (Optional but Recommended)

Apple requires a Privacy Manifest (`PrivacyInfo.xcprivacy`) for apps that access the photo library and for apps submitted to the App Store. Add this file to the `FamilyPhotos` target:

1. In Xcode, **File → New File → Privacy Manifest** (requires Xcode 15+).
2. Declare:
   - **NSPrivacyAccessedAPICategoryPhotoLibrary**: The app accesses the photo library to display shared album photos.
   - **NSPrivacyTracking**: `NO` (the app does not track users).

---

## 🟢 Iterative Improvements (Nice to Have)

### 6. Discuss: iCloud Photos URL Input

**Question**: Should the app support entering a shared album **link** (e.g., `https://www.icloud.com/photos/#xxxxxx`) directly, rather than requiring the user to subscribe via the Photos app first?

**Current behavior**: The app lists albums already subscribed to in the iOS Photos app.

**Alternative**: Parse the iCloud Photos shared album token from the URL and use the `CloudKit` framework (`CKContainer`, `CKShare`) to fetch photos directly from the shared album — even without a Photos subscription. This is more complex but more user-friendly.

---

### 7. Discuss: Slideshow Transition Style

**Current**: Cross-fade with subtle scale animation.

**Options to consider**: Slide, flip, cube, Ken Burns effect. Let me know which you prefer.

---

### 8. Discuss: Sleep / Auto-Lock Prevention

When used as a digital photo frame, the screen should stay on. Currently, the app does not prevent auto-lock. Add `UIApplication.shared.isIdleTimerDisabled = true` when the slideshow is active and `false` when it stops?

---

### 9. Discuss: Kiosk / Full-Screen Mode (iPad)

For a dedicated photo frame iPad, consider Guided Access or a "kiosk mode" that hides the home button and prevents switching apps. This can be enabled at the OS level (Settings → Accessibility → Guided Access) — no code changes required.

---

### 10. App Display Name Localization

The display name "Family Photos" is set in `Info.plist`. If you want it localized (e.g., "Familienfotos" in German), add a `InfoPlist.strings` file per locale.
