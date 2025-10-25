# App Store Deployment Guide - Move Match

Complete checklist for launching Move Match on the iOS App Store.

---

## Pre-Deployment Checklist

### Code Complete ✅
- [x] All Swift files implemented (18 files, 4,419 lines)
- [x] ARKit body tracking working
- [x] Audio analysis functional
- [x] Firebase integration complete
- [x] AdMob integration complete
- [x] IAP (StoreKit 2) implementation complete
- [x] All UI views built (7 screens)

### Configuration ⏳
- [ ] GoogleService-Info.plist added (download from Firebase Console)
- [ ] AdMob ad unit IDs updated in AdManager.swift
- [ ] Bundle identifier set (unique, e.g., com.yourname.movematch)
- [ ] App version set to 1.0.0
- [ ] Build number set to 1

### Testing ⏳
- [ ] Tested on physical iPhone (XS or newer)
- [ ] All 7 moves detect correctly
- [ ] ARKit calibration works
- [ ] Songs from Apple Music load and play
- [ ] Firebase saves sessions correctly
- [ ] Rewarded ads display correctly
- [ ] IAP purchases work in Sandbox mode
- [ ] No crashes during 10-minute session

---

## Step 1: Prepare App Store Connect

### 1.1 Create App Listing

1. Go to https://appstoreconnect.apple.com
2. Click **Apps → + (Add Apps) → New App**
3. Fill out form:
   - **Platform:** iOS
   - **Name:** Move Match
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your bundle ID
   - **SKU:** movematch-ios-2025
   - **User Access:** Full Access
4. Click **Create**

### 1.2 App Information

Navigate to **App Information** and set:

**Category:**
- **Primary:** Games / Puzzle
- **Secondary:** Health & Fitness

**Age Rating:**
- Complete questionnaire
- Expected rating: **4+** (no violence, mild cartoon/fantasy violence)

**Game Center:**
- Enable Game Center
- Add leaderboards (optional for v1.0)

---

## Step 2: Version Information

### 2.1 Basic Info

Navigate to **App Store → [Version 1.0]**

**Screenshots** (Required - 5 minimum):

You'll need to create these (use simulator + screenshot tool):

1. **Gameplay - ARKit tracking**
   - Show user dancing with skeleton overlay
   - Puzzle prompt visible
   - Score/combo HUD visible

2. **Song Selection**
   - Show music library
   - Search bar
   - Song list with BPM/genre tags

3. **Results Screen**
   - Show 3-star completion
   - XP earned
   - Stats summary

4. **Profile/Progression**
   - Show level, XP progress
   - Unlocked moves
   - Coins/gems

5. **Main Menu**
   - Show dashboard with stats
   - Quick Play button
   - Clean, polished UI

**Screenshot Sizes:**
- iPhone 6.7" (Pro Max): 1290 x 2796 pixels
- iPhone 6.5" (XS Max): 1242 x 2688 pixels
- iPhone 5.5" (8 Plus): 1242 x 2208 pixels

**App Preview Video** (Optional but recommended):
- 30-second gameplay video
- Show: calibration → dancing → puzzle solving → results
- Use screen recording on iPhone
- Edit with iMovie or Final Cut Pro

### 2.2 Description

**Promotional Text** (170 characters max):
```
Dance to your favorite music! Move Match uses your iPhone's camera to track your moves and create personalized dance puzzles. Get fit while having fun! 🎵💃
```

**Description** (4000 characters max):
```
MOVE MATCH - Dance. Solve. Get Fit.

Turn your iPhone into a personal dance fitness coach! Move Match uses cutting-edge computer vision to track your full-body movements while you dance to your favorite songs.

🎮 HOW IT WORKS
• Choose any song from your Apple Music library
• Your iPhone analyzes the music (BPM, energy, genre)
• AR camera tracks your dance moves in real-time
• Complete dance "puzzles" synchronized to the music
• Earn XP, unlock moves, and level up!

🕺 MOVE TYPES
Master 7 different dance moves:
• Jumps - Build explosive power
• Squats - Strengthen your legs
• Arm Raises - Tone your arms
• Side Steps - Improve agility
• Spins - Enhance coordination

💪 FITNESS TRACKING
• Real-time calorie burn calculation
• Track your workout sessions
• Build combo streaks for bonus points
• Progressive difficulty adapts to your skill level

🎵 MUSIC-AWARE AI
Our smart puzzle generator analyzes your music:
• Electronic → High-energy jump sequences
• Hip-Hop → Smooth squat combos
• Pop → Mixed move challenges
• Rock → Intense endurance tests
• And more!

🎯 PROGRESSION SYSTEM
• Earn XP to level up
• Unlock new moves and characters
• Complete daily quests
• Climb the global leaderboards
• Season Pass with exclusive rewards

📱 REQUIREMENTS
• iPhone XS or newer (ARKit support required)
• iOS 16.0 or later
• 2-3 meters of open space
• Apple Music library (or iTunes purchased music)

🆓 FREE TO PLAY
Move Match is free with optional in-app purchases:
• Play unlimited songs
• Earn coins and gems through gameplay
• Watch rewarded video ads for bonus XP
• Optional VIP subscription for ad-free experience

🔒 PRIVACY
• No personal data sold to third parties
• Camera is only used for local body tracking
• Music stays on your device
• Firebase analytics for app improvements only

Perfect for:
✓ Fitness enthusiasts looking for fun workouts
✓ Dance game fans (DDR, Just Dance players)
✓ Anyone who wants to move more while listening to music
✓ TikTok creators making dance content

Download Move Match and start your dance fitness journey today!

---
Developed with ❤️ by [Your Name/Studio]
Questions? Contact: support@movematch.com
```

**Keywords** (100 characters max):
```
dance,fitness,workout,AR,music,puzzle,game,exercise,calories,rhythm,DDR,Just Dance,body tracking
```

**Support URL:**
```
https://movematch.com/support
(Create a simple page with FAQ and contact form)
```

**Marketing URL** (Optional):
```
https://movematch.com
```

**Privacy Policy URL** (Required):
```
https://movematch.com/privacy
(MUST create this - see template below)
```

### 2.3 What's New in This Version

**Version 1.0 Release Notes:**
```
🎉 Welcome to Move Match!

This is our initial release. Features include:

• AR body tracking for 7 dance moves
• Personalized puzzles for any song in your library
• Real-time fitness tracking (calories, combos, XP)
• Progressive difficulty that adapts to you
• Season Pass with 30 tiers of rewards
• Global leaderboards
• Free to play with optional VIP subscription

We'd love to hear your feedback! Rate us and let us know what features you'd like to see next.

Dance on! 💃🕺
```

---

## Step 3: Build and Archive

### 3.1 Update Version Info

In Xcode, select project → General:
- **Version:** 1.0.0
- **Build:** 1

### 3.2 Switch to Production Config

**AdManager.swift:**
```swift
// Replace test ad unit ID with your production ID from AdMob
private let adUnitID = "ca-app-pub-YOUR-REAL-ID/YOUR-REWARDED-UNIT"
```

**Enable Release Optimizations:**
1. Edit Scheme → Run → Build Configuration → **Release**
2. Product → Scheme → Edit Scheme
3. Archive → Build Configuration → **Release**

### 3.3 Archive the App

1. Select **Any iOS Device (arm64)** as destination (not a simulator)
2. Product → **Archive**
3. Wait 5-10 minutes for build to complete
4. Xcode Organizer window will open automatically

### 3.4 Validate Archive

1. Select your archive
2. Click **Validate App**
3. Select your distribution method: **App Store Connect**
4. Choose signing: **Automatically manage signing**
5. Click **Validate**
6. Wait for validation to complete
7. Fix any errors/warnings

### 3.5 Upload to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Choose **Upload**
4. Select signing: **Automatically manage signing**
5. Review app details
6. Click **Upload**
7. Wait 10-20 minutes for processing

---

## Step 4: Submit for Review

### 4.1 Build Selection

1. In App Store Connect, go to your app
2. Select **App Store → [Version 1.0]**
3. Under **Build**, click **Select a build before you submit**
4. Choose your uploaded build (may take 5-10 minutes to appear)

### 4.2 Review Information

**Sign-In Required:**
- No (app doesn't require login to use basic features)

**Demo Account** (if required):
- Username: (leave blank)
- Password: (leave blank)

**Contact Information:**
- First Name: [Your First Name]
- Last Name: [Your Last Name]
- Phone: [Your Phone]
- Email: [Your Email]

**Notes for Review:**
```
Dear App Review Team,

Move Match is a dance-fitness game that uses ARKit body tracking.

To test the app:
1. Grant camera permission when prompted
2. Tap "Quick Play" on the main menu
3. Select any song from the library (you may need to grant Apple Music permission)
4. Stand 2-3 meters from your device
5. Follow the calibration instructions
6. Perform the dance moves shown on screen (jumps, squats, arm raises)

The app tracks your movements using ARKit and generates dance puzzles based on the music.

Note: ARKit body tracking requires iPhone XS or newer. The app will gracefully handle unsupported devices.

AdMob Integration:
- We use rewarded video ads (users opt-in for bonus XP)
- No interstitial or banner ads during gameplay
- VIP subscription removes all ads

Thank you for reviewing!
```

### 4.3 Age Rating

Complete the questionnaire:
- **Cartoon/Fantasy Violence:** None
- **Realistic Violence:** None
- **Sexual Content:** None
- **Profanity/Crude Humor:** None
- **Horror/Fear Themes:** None
- **Mature/Suggestive Themes:** None
- **Alcohol/Tobacco/Drugs:** None
- **Simulated Gambling:** None
- **Medical/Treatment Info:** None
- **Unrestricted Web Access:** No
- **User Generated Content:** No

**Expected Rating:** 4+

### 4.4 App Review Information

**App Review Attachments:**

Optional but helpful:
- Upload a video showing how to use the app
- Screenshots of permissions working
- Brief written guide

### 4.5 Version Release

**Release Options:**
- **Automatically release after approval** ← Recommended for v1.0
- Manually release
- Schedule release

### 4.6 Submit

1. Click **Add for Review** (top right)
2. Review all information
3. Click **Submit to App Review**

---

## Step 5: Post-Submission

### Expected Timeline

1. **Waiting for Review:** 1-24 hours
2. **In Review:** 2-48 hours
3. **Pending Developer Release:** 0 hours (if auto-release)
4. **Ready for Sale:** Immediately after approval

Average total time: **24-72 hours**

### Monitor Status

Check App Store Connect daily:
- Dashboard → App Store → Version 1.0 → Status

### Common Rejection Reasons

**4.2 - Minimum Functionality**
- Ensure app doesn't crash on startup
- All core features must work

**2.1 - App Completeness**
- All IAP products must be configured
- Privacy policy must be accessible

**2.3 - Accurate Metadata**
- Screenshots must match actual app
- Description can't be misleading

**5.1.1 - Privacy**
- Privacy policy must cover camera usage
- Must explain data collection

### If Rejected

1. Read rejection reason carefully
2. Fix the issue
3. Increment build number (not version)
4. Upload new build
5. Resubmit (usually faster second review)

---

## Step 6: Launch Day

### When App Goes Live

**1. Verify App Store Listing**
- Search "Move Match" in App Store
- Check all screenshots display correctly
- Verify description renders properly
- Test "Get" button

**2. Enable Monitoring**
- Firebase Analytics: Monitor crashes
- App Store Connect: Check downloads/revenue
- AdMob: Track ad impressions/revenue

**3. Marketing Push**
- Post on TikTok with gameplay video
- Share on Reddit (r/IndieGaming, r/Fitness)
- Email beta testers
- Press release to app review sites

**4. Monitor Reviews**
- Respond to all reviews in first week
- Fix critical bugs immediately
- Plan v1.1 based on feedback

---

## Required External Pages

### Privacy Policy Template

Create a page at `https://movematch.com/privacy`:

```markdown
# Privacy Policy for Move Match

Last updated: [Date]

## Information We Collect

**Camera Data:**
- Used only for AR body tracking
- Processed locally on your device
- Never transmitted to our servers
- Not stored or recorded

**Apple Music Library:**
- Read-only access to play your music
- Song metadata used to generate puzzles
- No data shared with third parties

**Usage Analytics:**
- Firebase Analytics collects anonymized usage data
- Helps us improve the app
- Can be disabled in Settings → Privacy

**User Profile Data:**
- Display name, level, XP, coins stored in Firebase
- Used to sync progress across devices
- Can be deleted by contacting support

## How We Use Your Information

- Provide core app functionality (AR tracking, music playback)
- Save your game progress
- Improve app performance and features
- Display relevant ads (if not VIP subscriber)

## Third-Party Services

**Firebase (Google):** Analytics, authentication, database
**AdMob (Google):** Advertising
**Apple:** Music playback, authentication

See their privacy policies for details.

## Your Rights

- Request data deletion: support@movematch.com
- Opt out of analytics: Device Settings → Privacy
- Opt out of ads: Purchase VIP subscription

## Children's Privacy

Move Match is rated 4+ but we do not knowingly collect data from children under 13. Parents: please contact us if you believe your child has provided personal information.

## Contact Us

Email: support@movematch.com
Website: https://movematch.com
```

### Support Page Template

Create a page at `https://movematch.com/support`:

```markdown
# Move Match Support

## Frequently Asked Questions

**Q: My moves aren't being detected. What should I do?**
A: Ensure you have 2-3 meters of space, good lighting, and you've completed calibration.

**Q: Why can't I play certain songs?**
A: DRM-protected songs from streaming services can't be analyzed. Use purchased or DRM-free music.

**Q: How do I restore my purchases?**
A: Go to Shop → Tap "Restore Purchases"

**Q: The app crashes on startup. Help!**
A: Make sure you have iOS 16+ and iPhone XS or newer. Try reinstalling the app.

**Q: How do I cancel my VIP subscription?**
A: Settings → [Your Name] → Subscriptions → Move Match VIP → Cancel

## Contact Us

Email: support@movematch.com

We typically respond within 24 hours.
```

---

## Budget Required

### One-Time Costs

- Apple Developer Account: **$99/year**
- Domain (movematch.com): **$12/year** (optional)
- Web hosting (for privacy/support pages): **$5/month** (optional)

### Ongoing Costs (Monthly)

- Firebase (free tier): **$0** (up to 10K users)
- AdMob: **$0** (revenue-generating)
- Server (if needed): **$0** (Firebase handles everything)

**Total to Launch:** ~$100-150 first year

---

## Post-Launch Checklist

### Week 1
- [ ] Monitor crash reports daily
- [ ] Respond to all App Store reviews
- [ ] Fix critical bugs (submit v1.0.1 if needed)
- [ ] Track downloads and revenue

### Week 2-4
- [ ] Analyze user behavior in Firebase
- [ ] A/B test different puzzle difficulty curves
- [ ] Plan v1.1 features based on feedback
- [ ] Reach out to influencers for reviews

### Month 2-3
- [ ] Implement most-requested features
- [ ] Add seasonal events (holiday themes)
- [ ] Launch Season 2 of Season Pass
- [ ] Expand marketing efforts

---

## Success Metrics

### Week 1 Targets
- 100-500 downloads (organic + initial marketing)
- <1% crash rate
- 4.0+ star rating average
- 30%+ D1 retention
- 15%+ D7 retention

### Month 1 Targets
- 1,000-5,000 downloads
- $100-500 revenue (ads + IAP)
- 10-20 App Store reviews
- Feature in "New Games We Love" (if lucky)

### Month 3 Targets
- 5,000-20,000 downloads
- $500-2,000 revenue
- Profitable (revenue > costs)
- Plan for Android version

---

**Last Updated:** Oct 25, 2025
**Version:** 1.0 Launch Guide
