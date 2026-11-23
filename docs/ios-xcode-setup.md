# Setting Up Your MacBook for iOS Development with Xcode (PACE)

This guide walks through setting up a MacBook from scratch to compile, debug, and install **PACE** onto an iPhone using **Xcode** and **Flutter**.

---

## Prerequisites

- **MacBook** (Apple Silicon M1/M2/M3/M4 or Intel) running a recent version of macOS
- **iPhone** running **iOS 15.5 or newer** (required by on-device ML Kit schedule OCR)
- **USB cable** to connect your iPhone to your MacBook (for first-time setup and pairing)
- **Apple ID** (a free Apple ID works for testing and personal use; see [Permanent Installation & Signing](#step-6-keeping-pace-installed-permanently) for expiration rules)
- At least **25–30 GB** of free disk space (Xcode and iOS runtimes are large)

---

## Step 1: Install Xcode & Command Line Tools

1. **Install Xcode**
   - Open the **Mac App Store**, search for **Xcode**, and install it (or download a specific version from [developer.apple.com/download](https://developer.apple.com/download/)).
2. **Launch Xcode once to install iOS components**
   - Open **Xcode** from Applications.
   - When prompted, install the **iOS Platform** support (SDK & Simulator runtime).
   - You can also manage runtimes later via **Xcode → Settings → Components** (or **Platforms**).
3. **Configure Xcode Command Line Tools**
   Open **Terminal** and run:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   sudo xcodebuild -license accept
   ```

---

## Step 2: Install Homebrew, CocoaPods & Flutter

### 1. Install Homebrew (macOS package manager)

If you don't already have Homebrew installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On **Apple Silicon** Macs, add Homebrew to your shell PATH (follow the instructions printed at the end of the install):
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Install CocoaPods

Flutter uses CocoaPods to link native iOS plugins (such as `google_mlkit_text_recognition`, `flutter_local_notifications`, and `image_picker`):
```bash
brew install cocoapods
```

Verify installation:
```bash
pod --version
```

### 3. Install Flutter SDK

1. Install Flutter via Homebrew (or download the macOS archive from [docs.flutter.dev/get-started/install/macos](https://docs.flutter.dev/get-started/install/macos/mobile-ios)):
   ```bash
   brew install --cask flutter
   ```
   *(Or if using the zip archive, extract it to `~/development/flutter` and add `export PATH="$HOME/development/flutter/bin:$PATH"` to `~/.zshrc`.)*
2. Restart Terminal (or run `source ~/.zshrc`) and verify your environment:
   ```bash
   flutter doctor
   ```
3. Confirm that **Flutter**, **Xcode - develop for iOS and macOS**, and **CocoaPods** all show green checkmarks (`✓`). Follow any fix commands printed by `flutter doctor` if an item shows a warning.

---

## Step 3: Get the PACE Project & Install Dependencies

1. Clone (or pull the latest changes from) the repository on your MacBook:
   ```bash
   git clone <your-repo-url> pace
   cd pace/pace_app
   ```
2. Fetch Dart/Flutter packages:
   ```bash
   flutter pub get
   ```
3. Generate the iOS build configuration and install CocoaPods dependencies:
   ```bash
   flutter build ios --release --no-codesign
   ```
   > **Note on `ios/Podfile`:** On the first macOS build, Flutter generates `pace_app/ios/Podfile`. If CocoaPods complains about a deployment target mismatch (e.g., for `google_mlkit_text_recognition`), open `pace_app/ios/Podfile`, uncomment/update the platform line at the top to:
   > ```ruby
   > platform :ios, '15.5'
   > ```
   > Then run:
   > ```bash
   > cd ios
   > pod install --repo-update
   > cd ..
   > ```

---

## Step 4: Configure Signing & Capabilities in Xcode

1. **Open the Xcode Workspace**
   > **Important:** Always open **`Runner.xcworkspace`** (white icon), **never** `Runner.xcodeproj` (blue icon). The workspace includes CocoaPods dependencies.
   ```bash
   open ios/Runner.xcworkspace
   ```
2. **Sign in with your Apple ID in Xcode**
   - In the macOS menu bar, click **Xcode → Settings → Accounts**.
   - Click the **`+`** button at the bottom left → choose **Apple ID** → sign in.
3. **Configure Signing for the `Runner` Target**
   - In Xcode's left sidebar (Project Navigator), click the top-level **Runner** project.
   - Under **TARGETS**, select **Runner**.
   - Open the **Signing & Capabilities** tab.
   - Check **Automatically manage signing**.
   - Set **Team** to your Apple ID / Personal Team (or paid Apple Developer Team).
   - **Bundle Identifier:** If Xcode says `com.el.pace` is already registered to another developer, change it to a unique reverse-domain identifier such as:
     ```text
     com.yourname.pace
     ```
4. **Switch the Run Scheme to Release (Recommended for Standalone Use)**
   > **Why this matters:** Flutter **Debug** builds rely on the Mac's JIT debugger and will crash if you launch the app from your iPhone home screen after unplugging the USB cable. A **Release** build compiles ahead-of-time (AOT) and runs completely standalone.
   - In Xcode's top menu bar, go to **Product → Scheme → Edit Scheme…**
   - Select **Run** in the left column → open the **Info** tab.
   - Change **Build Configuration** from `Debug` to **`Release`**.
   - Click **Close**.

---

## Step 5: Prepare Your iPhone & Install PACE

### 1. Connect & Enable Developer Mode on iPhone

1. Connect your iPhone to your MacBook with a USB cable.
2. Unlock your iPhone and tap **Trust** when prompted with *"Trust This Computer?"*, then enter your passcode.
3. Enable **Developer Mode** (required on iOS 16+):
   - Open **Settings → Privacy & Security → Developer Mode**.
   - Toggle **Developer Mode** ON and restart your iPhone when prompted.
   - After rebooting, confirm turning on Developer Mode.

### 2. Build & Install from Xcode

1. At the top center of the Xcode window, click the device selector next to **Runner** and choose **your iPhone**.
2. Click the **Play (▶)** button (or press `Cmd + R`) to compile, sign, and install PACE onto your iPhone.
3. *(Alternative CLI method)* You can also install a standalone Release build directly from Terminal after signing is configured in Xcode:
   ```bash
   cd pace_app
   flutter run --release
   ```

### 3. Trust Your Developer Certificate (First Time Only)

If iOS shows *"Untrusted Developer"* when you open PACE on your iPhone:
1. Open **Settings → General → VPN & Device Management** on your iPhone.
2. Under **Developer App**, tap your Apple ID / Team name.
3. Tap **Trust "[Your Apple ID]"** → **Trust**.
4. Return to the Home Screen and open **PACE**.

### 4. Allow Notifications in PACE

1. Open **PACE** → go to **More → Reminders**.
2. Tap **Allow** to grant iOS notification permission.
3. Tap **Send test reminder**, lock your iPhone, and verify the notification arrives 1 minute later.

---

## Step 6: Keeping PACE Installed Permanently

Apple enforces code-signing expiration on all iOS devices. Your options depend on the type of Apple account you use:

| Option | Cost | Expiration | Notes |
| --- | --- | --- | --- |
| **Free Apple ID (Personal Team)** via Xcode | Free | **7 days** | After 7 days, the app won't open until you reconnect to Xcode and press **Run (▶)** again (your local PACE data is preserved as long as you don't delete the app). Limited to 3 active sideloaded apps. |
| **Free Apple ID + SideStore / AltStore** | Free | Auto-refreshes every 7 days | Export an `.ipa` from Xcode and sideload via SideStore/AltStore so your iPhone refreshes the signature over Wi-Fi without needing Xcode each week. |
| **Apple Developer Program** (Xcode / Ad Hoc) | \$99/year | **1 year** | Apps installed from Xcode stay signed for 12 months with no 3-app limit. |
| **Apple Developer Program + TestFlight** | \$99/year | 90 days per build (easy 1-tap renew) | Archive in Xcode (**Product → Archive**), upload to App Store Connect, and install on your iPhone via Apple's official **TestFlight** app. |

> **Data safety tip:** When re-signing with the **same Bundle Identifier and Apple ID**, iOS installs the new signature *over* the existing app and keeps your local SQLite database (routines, deadlines, notes, habits, and finance logs) intact. Never uninstall the app first if you want to keep your data.

---

## What Works on iPhone in PACE

PACE's platform capabilities are managed in `pace_app/lib/core/platform/platform_features.dart`:

- **Enabled on iOS:**
  - Today screen, Leave-by planner, Wake anchor & Sleep log
  - Deadlines, Quick Capture Inbox, "Just start" Focus timer
  - Evening check-in, Weekly view & Analytics
  - Local scheduled reminders (`flutter_local_notifications`)
  - Class schedule & **Schedule photo OCR import** (Camera / Photo Library + ML Kit)
  - Daily Bible verse, Movement habits, Notes, Finance & Budget
  - Optional read-only Google Calendar sync *(requires building with `--dart-define=PACE_GOOGLE_CLIENT_ID=...` and adding the reversed client ID URL scheme to `ios/Runner/Info.plist`)*
- **Android-only (automatically hidden on iOS):**
  - App-blocking gate (relies on Android Usage Access & system overlay)
  - Home-screen widgets (requires a separate iOS WidgetKit extension)
  - Persistent notification-shade inline reply shortcut

---

## Troubleshooting

### 1. App crashes immediately when opened after unplugging from Mac
- You installed a **Debug** build instead of a **Release** build.
- In Xcode, go to **Product → Scheme → Edit Scheme → Run → Info**, change **Build Configuration** to **Release**, and click **Run (▶)** again.

### 2. `pod install` fails with deployment target errors
- Open `pace_app/ios/Podfile` and ensure the top specifies:
  ```ruby
  platform :ios, '15.5'
  ```
- Re-run:
  ```bash
  cd pace_app/ios
  rm -rf Pods Podfile.lock
  pod install --repo-update
  ```

### 3. CocoaPods errors on Apple Silicon (M1–M4)
- Make sure you installed CocoaPods via Homebrew (`brew install cocoapods`) rather than the system macOS Ruby (`sudo gem install cocoapods`), which often has permission and architecture mismatches.

### 4. "Failed to register bundle identifier" in Xcode
- `com.el.pace` must be globally unique across Apple's Developer Portal. Change the **Bundle Identifier** in **Signing & Capabilities** to something unique (e.g., `com.<your-username>.pace`).

### 5. Clean Reset (when Xcode gets stuck on stale caches)
```bash
cd pace_app
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
```
In Xcode, you can also press **`Shift + Cmd + K`** (*Clean Build Folder*) before building again.
