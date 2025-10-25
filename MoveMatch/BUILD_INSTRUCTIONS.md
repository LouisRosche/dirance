# Build Instructions - Move Match iOS App

This guide walks you through building and running the Move Match app on your iPhone.

---

## Prerequisites

### Required:
- **macOS** (Ventura 13.0 or later)
- **Xcode 15.0+** (download from Mac App Store)
- **iPhone XS or newer** with iOS 16.0+
- **Apple Developer Account** (free tier is fine for testing)
- **Firebase account** (free)
- **AdMob account** (free)

### Optional:
- **TestFlight** access for beta testing
- **Paid Apple Developer Account** ($99/year) for App Store distribution

---

## Step 1: Clone/Download Project

If you haven't already, ensure you have the Move Match source code:

```bash
cd /path/to/MoveMatch
```

Verify all source files are present:
```bash
ls -R MoveMatch/
# Should see: Models/, Core/, Features/, Services/, App/, Info.plist
```

---

## Step 2: Open in Xcode

### Option A: Open Package (Recommended)

1. Open **Xcode**
2. Go to **File → Open**
3. Navigate to the `MoveMatch` folder
4. Select `Package.swift`
5. Click **Open**

Xcode will automatically:
- Resolve Swift package dependencies
- Download Firebase SDK (~200 MB)
- Download Google Mobile Ads SDK (~50 MB)
- Generate build system files

**Wait 2-5 minutes** for dependency resolution to complete.

### Option B: Create New Xcode Project (If Option A fails)

1. In Xcode: **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name:** MoveMatch
   - **Organization Identifier:** com.yourname.movematch
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Click **Create**
5. **Manually copy all .swift files** from this repo into the new project

---

## Step 3: Configure Signing

1. Select the **MoveMatch** project in the navigator
2. Select the **MoveMatch** target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** (Apple Developer account)
6. Change **Bundle Identifier** to something unique:
   - Example: `com.yourname.movematch`

---

## Step 4: Set Up Firebase

### 4.1 Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add project**
3. Name it **"MoveMatch"**
4. **Disable** Google Analytics (optional for now)
5. Click **Create project**

### 4.2 Add iOS App to Firebase

1. In Firebase Console, click **Add app → iOS**
2. Enter your **Bundle ID** (from Step 3)
   - Example: `com.yourname.movematch`
3. Enter **App nickname:** "MoveMatch iOS"
4. Click **Register app**
5. **Download GoogleService-Info.plist**
6. Drag the downloaded file into your Xcode project:
   - Drop it in the root folder (next to Info.plist)
   - ✅ Check "Copy items if needed"
   - ✅ Check "MoveMatch" target

### 4.3 Enable Firebase Services

In Firebase Console, enable these services:

**Authentication:**
1. Go to **Build → Authentication**
2. Click **Get started**
3. Enable **Anonymous** sign-in (for testing)
4. Enable **Apple** sign-in (for production)

**Firestore Database:**
1. Go to **Build → Firestore Database**
2. Click **Create database**
3. Choose **Test mode** (for development)
4. Select region: **us-central** (or closest to you)

**Remote Config:**
1. Go to **Build → Remote Config**
2. Click **Create configuration**
3. Add parameter:
   - Key: `minimum_app_version`
   - Value: `1.0.0`

---

## Step 5: Set Up AdMob

### 5.1 Create AdMob Account

1. Go to https://apps.admob.com
2. Sign in with Google account
3. Click **Apps → Add app**
4. Select **iOS**
5. Enter app name: **"Move Match"**
6. Click **Add**

### 5.2 Create Rewarded Ad Unit

1. Click **Ad units → Add ad unit**
2. Select **Rewarded**
3. Name it: **"Double XP Reward"**
4. Click **Create ad unit**
5. **Copy the Ad unit ID** (looks like `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

### 5.3 Update Code with Ad Unit ID

1. Open `Services/Monetization/AdManager.swift`
2. Find line ~15:
   ```swift
   private let adUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ID
   ```
3. Replace with your **real ad unit ID** (for production)
4. Keep test ID for development/testing

---

## Step 6: Configure Info.plist Permissions

Verify these permissions are in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Move Match uses your camera to track your dance moves</string>

<key>NSMediaLibraryUsageDescription</key>
<string>Access your music library to play songs you love</string>

<key>NSMicrophoneUsageDescription</key>
<string>Record your epic dance moments to share</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Save your gameplay highlights to share on TikTok</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
    <string>arm64</string>
</array>
```

These should already be present in the provided `Info.plist`.

---

## Step 7: Build and Run

### 7.1 Connect Your iPhone

1. Connect iPhone to Mac via USB
2. **Trust this computer** on iPhone (if prompted)
3. In Xcode, select your **iPhone** from device dropdown (top toolbar)

### 7.2 Build the App

1. Press **⌘+B** (or Product → Build)
2. Wait for build to complete (~30 seconds)
3. Fix any errors if they appear (usually signing issues)

### 7.3 Run on Device

1. Press **⌘+R** (or Product → Run)
2. Xcode will:
   - Install app on your iPhone
   - Launch the app
   - Attach debugger

**On first run, you'll see:**
- **"Untrusted Developer"** popup on iPhone
- Go to **Settings → General → VPN & Device Management**
- Tap your Apple ID
- Tap **Trust "Apple Development: yourname@email.com"**
- Return to home screen and launch Move Match again

---

## Step 8: Test Core Features

### 8.1 Welcome Screen
- ✅ Apple Sign-In button appears
- ✅ Feature list displays correctly

### 8.2 Main Menu
- ✅ User stats display
- ✅ Quick Play button works
- ✅ Navigation to Profile, Shop

### 8.3 Song Selection
- ✅ Apple Music library loads (grant permission)
- ✅ Search bar filters songs
- ✅ Tapping song starts analysis

### 8.4 Gameplay
- ✅ Camera permission granted
- ✅ ARKit calibration starts (see progress circle)
- ✅ Body skeleton appears after calibration
- ✅ Puzzle prompts display
- ✅ Moves are detected (check console logs)

### 8.5 Results Screen
- ✅ Score, stars, XP display
- ✅ Rewarded ad offer appears
- ✅ Stats save to Firebase

---

## Troubleshooting

### Build Errors

**"No such module 'Firebase'"**
- Solution: Wait for package resolution to finish
- File → Packages → Resolve Package Versions

**"Failed to register bundle identifier"**
- Solution: Change bundle ID to something unique
- Go to Signing & Capabilities → Bundle Identifier

**"Provisioning profile doesn't include signing certificate"**
- Solution: Xcode → Preferences → Accounts → Download Manual Profiles

### Runtime Errors

**"ARKit body tracking not supported"**
- Cause: Device doesn't support ARKit 3.0
- Solution: Use iPhone XS or newer

**"Firebase app not initialized"**
- Cause: GoogleService-Info.plist not added correctly
- Solution: Re-add file to project, ensure target membership

**"No songs appear in library"**
- Cause: Apple Music permission denied
- Solution: Settings → Privacy → Media & Apple Music → Move Match → ON

**"Ads don't show"**
- Expected: AdMob test ads may take 15-30 seconds to load first time
- Solution: Check console for "Ad loaded successfully" log

---

## Debugging Tips

### Enable Verbose Logging

1. Edit scheme: Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add:
   - **FIRDebugEnabled**: `1`
   - **FIRAnalyticsDebugEnabled**: `1`

### View Console Logs

1. Open Debug Area: **⌘+Shift+Y**
2. Look for emoji logs:
   - 🎯 = Move detected
   - ✅ = Calibration complete
   - ❌ = Error occurred
   - 🔥 = Firebase event

### Profile Performance

1. Product → Profile
2. Choose **Time Profiler**
3. Run app and play a song
4. Look for:
   - ARKit FPS (should be 30+)
   - Memory usage (should be <200 MB)

---

## Next Steps

### For Development Testing:
1. Test all 7 move types work reliably
2. Test with different music genres
3. Test progression system (level up, unlocks)
4. Test IAP purchases (Sandbox mode)
5. Test ads (test ad units only)

### For TestFlight Beta:
1. Archive build: Product → Archive
2. Upload to App Store Connect
3. Add beta testers (up to 10,000)
4. Distribute via TestFlight

### For App Store Release:
1. Replace test ad units with production IDs
2. Create app listing in App Store Connect
3. Upload screenshots (5 required)
4. Upload app preview video
5. Submit for review
6. Wait 24-48 hours for approval

---

## Common Xcode Shortcuts

- **⌘+B** - Build
- **⌘+R** - Run
- **⌘+.** - Stop
- **⌘+Shift+K** - Clean Build Folder
- **⌘+Shift+Y** - Toggle Debug Area
- **⌘+1-9** - Navigate panels

---

## Support

**Build Issues:**
- Check Xcode console for errors
- File → Packages → Reset Package Caches
- Clean build folder: Product → Clean Build Folder

**Firebase Issues:**
- https://firebase.google.com/docs/ios/setup

**AdMob Issues:**
- https://developers.google.com/admob/ios/quick-start

**ARKit Issues:**
- https://developer.apple.com/documentation/arkit

---

**Last Updated:** Oct 25, 2025
**Xcode Version:** 15.0+
**iOS Target:** 16.0+
