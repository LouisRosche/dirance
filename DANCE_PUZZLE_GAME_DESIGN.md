# Dance Puzzle: Computer Vision Rhythm-Puzzle Game
## Market-Validated Design Document

### Executive Summary
**Working Title:** "Move Match" (placeholder - optimize through ASO testing)

**High-Concept:** DDR meets Vampire Survivors through your iPhone camera - dance to your music, solve movement puzzles, unlock permanent upgrades in an addictive meta-progression loop that creates viral TikTok moments.

**Market Position:** Hybrid-casual rhythm-puzzle targeting the intersection of:
- Physics-based puzzle innovation (Traffic Jam Fever model: 10M downloads, $212K in 5 months)
- Fitness gaming (Ring Fit, Beat Saber audience migrating to mobile)
- TikTok-native content (75% of platform users discover games there)

**Why This Wins:**
- **Emerging subgenre**: No dominant computer-vision dance-puzzle hybrid on mobile
- **Viral by design**: Every play session = shareable 15-30 sec TikTok content
- **Low competition**: Bypasses saturated match-3 ($100M budgets) and established rhythm games
- **Hybrid monetization**: Targets 146% ROAS advantage over single-method games
- **Fitness angle**: 32% lower UA costs with wellness positioning vs generic puzzle

---

## Core Gameplay Loop (The 30-Second Experience)

### 1. Song Selection (5 seconds)
- Choose from personal Apple Music library OR curated free tracks
- Visual preview shows BPM, difficulty, estimated calories
- "Quick Play" uses AI to select energizing track matching time of day

### 2. Puzzle Generation (Auto, 2 seconds)
- Computer vision activates iPhone camera (front-facing)
- AI analyzes song structure (beat, drops, tempo changes)
- Generates 3-5 "Move Combos" (puzzle challenges) for this session
- Example: "Hit 3 Jump moves before the drop" or "Alternate arms 8 times without breaking combo"

### 3. Active Gameplay (60-180 seconds)
**The Innovation:** Computer vision detects body movements and "sorts" them into puzzle slots

**Mechanics:**
- **Move Detection**: Vision framework tracks 7 core moves:
  - Jump (vertical displacement)
  - Squat (hip joint angle)
  - Arm Raise L/R (shoulder elevation)
  - Side Step L/R (horizontal displacement)
  - Spin (full body rotation)

- **Puzzle Prompts**: On-screen UI shows combo requirements
  - "Complete: 🦵 Squat → 🙌 Arms → 🦵 Squat"
  - "Sort 5 Jumps before bridge (0:45)"
  - "Chain 10 moves without stopping"

- **Combo System**:
  - Correct move in sequence = +1 combo multiplier
  - Wrong move = reset to 1x (no failure, just efficiency loss)
  - Perfect timing (on-beat) = 2x points
  - Freestyle between prompts maintains combo

### 4. Rewards & Meta-Progression (15 seconds)
**Rogue-like Permanent Upgrades:**
- **Move Mastery**: Unlock advanced moves (Kick, Clap, Dab variations)
- **Combo Extensions**: Increase max multiplier ceiling
- **Power-ups**: Slow-mo, Beat Assist, Calorie Boost
- **Cosmetics**: AR filters, background effects for recordings
- **Song Unlocks**: Premium curated tracks + genre packs

**Session Rewards:**
- Star rating (1-3 stars based on puzzles solved)
- XP toward Season Pass tiers
- Coins (soft currency for cosmetics)
- Gems (hard currency for power-ups)
- Fitness stats (calories, active minutes)

---

## Puzzle Design Framework (Market-Validated)

### Why "Puzzle" Positioning Matters
The guide shows **sort puzzles grew 5.6x YoY** - our game literally "sorts" dance moves into combo sequences, making it a legitimate puzzle subgenre entry.

### Puzzle Types (Progression Curve)

**Beginner (Levels 1-10):**
- Single-move repetition: "Do 5 Jumps"
- Two-move alternation: "Squat → Jump × 3"
- Timing windows: "Hit Arms during chorus"

**Intermediate (Levels 11-30):**
- Three-move combos: "Jump → Squat → Spin"
- Counting challenges: "20 total moves this song"
- Positional: "Stay in camera frame while spinning"

**Advanced (Levels 31+):**
- Complex sequences: "Mirror mode" (left/right reversed)
- Endurance: "Don't drop combo for 90 seconds"
- Precision: "Hit 15 perfect on-beat moves"
- Hybrid: "Solve 3 different puzzles in one song"

### Difficulty Scaling
- **Adaptive AI**: If player fails 3 times, reduce combo length by 1
- **Song-driven**: Faster BPM = higher point multipliers, simpler combos
- **Meta-unlock**: "Hard Mode" puzzles for experienced players (2x rewards)

---

## TikTok Virality by Design

### Built-In Viral Mechanics

**1. Auto-Recording (Opt-In)**
- Game records front camera during play
- AI highlights best 15-second moment (highest combo streak)
- One-tap share to TikTok with:
  - AR effects overlay (sparkles on perfect moves)
  - Song credit + "Play this in Move Match" CTA
  - Challenge hashtag (#MoveMatchChallenge)

**2. Challenge Templates**
- Daily Featured Challenge: "Beat my score on [Song]"
- Community Puzzles: User-created combo sequences
- Duet Mode: Split-screen compete with friend's ghost data

**3. Trending Sound Integration**
- Monitor TikTok trending audio API
- Surface trending songs in Quick Play
- "This song is trending - 10K players this hour"

**4. Creator Tools**
- Export clips with transparent watermark
- Custom AR filters unlock at level milestones
- "React to my Move Match run" template

### Marketing Hooks (From Guide: TikTok = Highest ROI)
- Micro-influencers (fitness, dance): $100-1000/video
- Organic hashtag: #MoveMatchChallenge (demo satisfying perfect combos)
- Paid TikTok ads: $500-1000 test budget
  - Creative: 10-second clip of player hitting insane combo
  - Hook: "I burned 200 calories playing iPhone games"
  - CTA: "Your music. Your moves. Your game."

---

## Computer Vision Technical Approach

### Core Technology Stack
- **ARKit + Vision Framework** (iOS 15+)
  - VNDetectHumanBodyPoseRequest for skeletal tracking
  - 17-point body landmark detection
  - Runs at 30 FPS on iPhone 12+

### Move Detection Logic

**Jump:**
```swift
// Detect when hip joint Y-coordinate increases by 20%+ of frame height
if currentHipY < (baselineHipY - frameHeight * 0.2) {
    registerMove(.jump)
}
```

**Squat:**
```swift
// Hip-to-knee angle < 90 degrees
let hipKneeAngle = calculateAngle(hip, knee, ankle)
if hipKneeAngle < 90 && hipKneeAngle > 45 {
    registerMove(.squat)
}
```

**Arm Raise:**
```swift
// Shoulder-to-wrist Y-distance > shoulder height
if wristY < shoulderY - (frameHeight * 0.15) {
    registerMove(.armRaise)
}
```

### Reliability Features
- **Calibration**: 5-second pre-game "Stand here" positioning
- **Confidence Thresholds**: Only register moves with >80% Vision confidence
- **Debouncing**: 300ms cooldown between same-move detections
- **Lighting Check**: Warn if environment too dark for tracking
- **Fallback**: Manual tap controls if vision fails (accessibility + older devices)

### Performance Optimization
- Run Vision on background thread
- Downsample camera feed to 720p for processing
- Cache baseline pose for faster comparisons
- Thermal throttling detection (reduce FPS if device overheating)

---

## Meta-Progression (Rogue-like/lite Design)

### Permanent Unlocks (Vampire Survivors Model)

**Character System:**
- Start: "Starter Dancer" (base stats)
- Unlock: "Fitness Fanatic" (+20% calorie tracking)
- Unlock: "Rhythm Master" (+15% perfect timing window)
- Unlock: "Viral Star" (Auto-record highlights)

**Move Evolution Tree:**
```
Jump
├─> Double Jump (counts as 2x multiplier)
├─> Power Jump (perfect timing = 3x)
└─> Dance Jump (works in any direction)

Squat
├─> Deep Squat (harder detection, 2x points)
└─> Squat Hold (sustain = continuous combo)
```

**Power-Up Slots (Pre-Game Selection):**
- Choose 2 from unlocked pool:
  - **Beat Sync**: Visual metronome for perfect timing
  - **Slow-Mo**: 5 seconds of 0.5x speed (recharges on combo 10x)
  - **Free Pass**: 1 wrong move doesn't break combo
  - **Calorie Burst**: 2x fitness tracking this session
  - **Star Boost**: Easier 3-star requirements

### Session-to-Session Progression
- **Season Pass** (Battle Pass): 30 tiers, $4.99 premium track
  - Free: Basic moves, common cosmetics, 1 song/week
  - Paid: Rare moves, AR effects, 5 songs/week, 2x XP

- **Daily Quests** (Low-Effort from Guide):
  - "Complete 3 songs" - 50 XP
  - "Hit 50 perfect moves" - 100 XP
  - "Burn 100 calories" - 150 XP

- **Leaderboards** (Redis-powered):
  - Daily: Top combo streak
  - Weekly: Total puzzles solved
  - All-Time: Calories burned
  - Friend: Direct score comparison

---

## Monetization Strategy (Hybrid-Casual Model)

### The Guide's Core Insight:
> "Hybrid monetization outperforms by 146% ROAS by day 90 vs IAP-only (93%) or ads-only (58%)"

### Implementation:

**1. Rewarded Video Ads (Primary Revenue - Android Focus)**
- **Placement**: After song completion, offer:
  - "Watch to double your XP" (80% acceptance rate expected)
  - "Watch to retry with power-up" (60% acceptance)
  - "Watch to unlock this song permanently" (40% acceptance)

- **Frequency**: Max 1 ad per 2 songs (guide: 1 per 3-5 levels)
- **eCPM Target**: $16.49 Android, $19.63 iOS (US market)
- **Integration**: AdMob with bidding (AppLovin, Unity Ads, Meta backup)

**2. In-App Purchases (Primary Revenue - iOS Focus)**

**Entry Tier ($0.99-1.99):**
- 100 Gems (hard currency)
- Remove ads for 24 hours
- 1 Premium Song unlock

**Sweet Spot ($2.99-4.99):** Guide shows 1.5-2% conversion
- 500 Gems + 1 Rare Move
- Season Pass ($4.99 - industry standard)
- "Fitness Pack" (calorie tracking, Apple Health sync, workout history)

**Whale Tier ($9.99+):**
- VIP Subscription: $9.99/month
  - No ads permanently
  - 2x XP and coins
  - Exclusive weekly songs
  - Premium AR filters
  - Guide shows 5-10% of payers convert to VIP

**Soft Currency (Coins - Earned Free):**
- Used for: Cosmetics, common moves, retries
- Earned: 50-100 per song completion
- IAP shortcut: $0.99 = 1000 coins

### Revenue Projections (Conservative)

**Assumptions from Guide:**
- Target: $0.15 ARPDAU (mid-tier indie)
- 2% IAP conversion rate
- 30% of users watch rewarded ads
- $86.61 cost per paying user

**Month 1 (10K DAU):**
- Ad revenue: 3K users × 2 ads/day × $0.015 CPM = $90/day = $2,700/mo
- IAP revenue: 200 payers × $4 avg = $800/mo
- **Total: $3,500 gross** → $2,450 after 30% platform cut

**Month 6 (100K DAU at scale):**
- Ad: $27,000/mo
- IAP: $12,000/mo
- **Total: $39,000 gross** → $27,300 net

---

## User Acquisition & ASO Strategy

### App Store Optimization (30-50% of Installs - $0 CPI)

**Title Structure:**
- Primary: "Move Match - Dance Puzzle Game"
- Subtitle: "Fitness Rhythm Game Camera Workout Music Beat"
  (Packs keywords: fitness, rhythm, camera, workout, music, beat)

**Icon A/B Tests:**
- Version A: Silhouette mid-jump with motion lines (gameplay clarity)
- Version B: Phone camera + dancing emoji + lightning (unique mechanic)
- Test: Contrasting colors (neon green vs purple - visibility)

**Screenshots (First 3 Positions):**
1. **Gameplay Close-Up**: "Dance to YOUR Music" - camera view of player hitting combo
2. **Satisfying Moment**: Perfect 20x combo with particle effects
3. **Progression**: "Unlock 50+ Dance Moves" - upgrade tree visual

**Video Preview (30 sec):**
- 0-5s: Hook - "Your iPhone camera is now a dance game"
- 5-15s: Gameplay - player hitting combos, puzzle solving
- 15-25s: Rewards - unlocking moves, leveling up
- 25-30s: Social proof - "Join 100K dancers" + Download CTA

**Keywords (Long-Tail Focus):**
- Primary: "dance camera game," "fitness puzzle," "rhythm workout"
- Secondary: "DDR mobile," "dance challenge app," "music fitness"
- Avoid: "puzzle" (too saturated), "game" alone

### Paid UA Budget Allocation (Guide: $2K-5K Monthly Start)

**$3,000 Test Month:**
- 50% TikTok Spark Ads ($1,500):
  - 15-sec creative: "I burned 200 calories gaming"
  - Target: Fitness enthusiasts, mobile gamers 18-34
  - Goal: 750 installs @ $2 CPI

- 30% Apple Search Ads ($900):
  - Exact match: "dance game," "fitness game"
  - Target: iOS 15+ (ARKit requirement)
  - Goal: 180 installs @ $5 CPI

- 20% Meta ($600):
  - Retarget website visitors + lookalikes
  - Goal: 200 installs @ $3 CPI

**Target: 1,130 installs - Track Day 7 ROAS (guide: 6.9-8.5% for puzzles)**

### Micro-Influencer Strategy ($100-1K per Creator)

**Target Creators:**
- Fitness TikTok: 10K-100K followers
- Dance tutorials: YouTube 50K-200K subs
- Mobile gaming: Instagram 25K-75K

**Partnership Model:**
- Send early access codes + $200-500/video
- Request: 60-sec gameplay + genuine reaction
- Provide: Custom referral codes (track conversions)

**Expected ROI from Guide:** $6.50-20 return per $1 spent

---

## Development Plan & Timeline

### MVP Scope (4-5 Months Full-Time)

**Month 1: Prototype & Validation**
- Week 1-2: ARKit integration, basic move detection (jump, squat, arms)
- Week 3-4: Puzzle generation for 1 test song, scoring system
- **Validation Gate:** 10 testers play, 70%+ say "I'd play this daily"

**Month 2: Core Loop**
- Week 5-6: Apple Music API integration, song selection UI
- Week 7-8: 7 move types finalized, combo system, particle effects
- **Deliverable:** 10 curated songs with generated puzzles

**Month 3: Meta-Progression**
- Week 9-10: Unlock system, 15 upgrades, character selection
- Week 11-12: Season Pass framework, daily quests, leaderboards (Firebase)

**Month 4: Polish & Monetization**
- Week 13-14: AdMob + IAP integration, tutorial flow, onboarding
- Week 15-16: TikTok recording/sharing, ASO assets, bug fixing

**Month 5: Testing & Launch Prep**
- Week 17-18: 12-tester closed beta (Google Play requirement)
- Week 19-20: Privacy policy, COPPA compliance, final optimizations
- **Launch:** Week 20

### Technology Stack (Free-Tier Start)

**Frontend:**
- Swift + SwiftUI (native iOS, best ARKit integration)
- Alternative: Unity + AR Foundation (cross-platform future)

**Backend (Guide: $0-30/mo for 10K users):**
- Firebase:
  - Authentication (Apple Sign-In)
  - Firestore (user progress, unlocks)
  - Remote Config (A/B tests, live events)
  - Analytics (funnels, retention)

- Redis Cloud (Leaderboards): $0-10/mo < 100K users
- Apple Music API: Free (requires Apple Developer $99/year)

**Assets:**
- UI Kit: $30-50 (GameDev Market)
- Particle Effects: $20-40 (Unity Asset Store)
- SFX Pack: $75 (Epidemic Sound subscription)
- Music (Curated): $200 licensing for 10 tracks OR user library (free)

**Total Infrastructure Cost:**
- Month 1-3: $0
- Month 4-6 (10K users): ~$30/mo
- Month 12 (100K users): ~$300/mo

### Budget Summary

**Development (Solo, 5 Months):**
- Assets: $500
- Apple Developer: $99
- Testing Devices: $0 (use personal iPhone)
- **Total: $600**

**Marketing (Month 1 Post-Launch):**
- ASO (DIY + AppTweak tool): $50
- TikTok Ads: $1,500
- Apple Search Ads: $900
- Micro-Influencers: $500
- **Total: $2,950**

**Legal/Business:**
- LLC Formation: $550 (guide estimate)
- Privacy Policy Generator: $0 (TermsFeed)
- **Total: $550**

**GRAND TOTAL YEAR 1: $4,100**

---

## Risk Mitigation & Reality Checks

### The Guide's Brutal Truth:
> "Median lifetime revenue: $5K-13K. First games earn <$5K. Only top 15% hit $108K+."

### Our Advantages:
1. **Emerging niche**: No dominant computer-vision dance-puzzle
2. **Viral mechanics**: Built-in TikTok content creation
3. **Dual value prop**: Gaming + fitness (32% lower UA costs)
4. **Hybrid monetization**: 146% ROAS advantage
5. **Low competition**: Bypasses saturated match-3 and rhythm markets

### Our Risks:
1. **Technical complexity**: ARKit may fail in poor lighting/small spaces
2. **Niche appeal**: Not everyone wants camera-based gaming
3. **Device requirements**: iPhone 12+ limits addressable market
4. **First release**: 90% chance of <$5K lifetime (guide statistic)

### Mitigation Strategies:

**Technical:**
- Include manual tap controls fallback
- Thorough lighting/space detection with helpful error messages
- Support iPhone X+ (ARKit 2.0), not just 12+

**Market:**
- Validate with 50+ beta testers before launch
- A/B test "fitness game" vs "dance game" positioning in ads
- Build email list during beta for launch spike

**Financial:**
- Keep day job during development (guide recommendation)
- Treat as learning investment for Game #2 (40% better performance expected)
- Allocate 6-month runway for live ops post-launch

### Success Metrics (6-Month Milestones)

**Month 1:**
- 5,000 downloads (ASO + small paid UA)
- 35% Day-1 retention
- 15% Day-7 retention
- $0.10 ARPDAU

**Month 3:**
- 25,000 total downloads
- 40% D1, 18% D7 retention (guide: 40%+ = competitive)
- 1.5% IAP conversion
- $0.12 ARPDAU
- First TikTok video >100K views

**Month 6:**
- 75,000 total downloads
- 50K MAU
- $0.15 ARPDAU
- $7,500 monthly revenue ($5K after platform cuts)
- 5+ micro-influencer partnerships
- Planning Game #2 features based on feedback

---

## Conclusion: Why This Concept Aligns With Market Data

The guide's core thesis: **Hybrid-casual games with simple mechanics + meta-progression + mixed monetization in emerging subgenres win.**

**Move Match hits every criteria:**

✅ **Simple core mechanic**: Dance moves detected by camera
✅ **Puzzle element**: Sort moves into combos (like sort puzzles growing 5.6x)
✅ **Meta-progression**: Rogue-like unlocks and Season Pass
✅ **Hybrid monetization**: Rewarded video + IAP from day one
✅ **Emerging subgenre**: Computer-vision rhythm-puzzle (no dominant player)
✅ **Viral mechanics**: TikTok integration = free organic growth
✅ **Secondary value prop**: Fitness angle reduces UA costs 32%

**What competitors lack:**
- Just Dance Mobile: No puzzles, no meta-progression, requires controller
- Beat Saber: VR-only, not mobile
- Ring Fit: Console-only, expensive hardware
- Fitness apps: Boring, not gamified enough

**Our unique position:** The only mobile game where your music library + phone camera + puzzle solving = fitness gaming with TikTok virality.

The guide's wisdom: "Success requires 3-5 releases." This is Game #1 - a learning investment with genuine market opportunity. Keep day job, ship in 5 months, allocate 30-50% budget to marketing, and validate whether players want camera-based dance puzzles before committing to Game #2.

**Next Steps:**
1. Validate core concept with 10-person prototype test (Week 4)
2. If validated, commit to 5-month MVP timeline
3. Launch with $3K marketing budget
4. Analyze 90-day metrics vs. guide benchmarks
5. Decide: iterate or pivot to Game #2

---

## Appendix: Comparable Case Studies

**Traffic Jam Fever (Guide Reference):**
- Physics-based puzzle with fresh theme
- 10M downloads, $212K in 5 months
- Solo/small team
- **Lesson**: Innovation within established mechanics works

**Color Block Jam (Guide Reference):**
- $42M quarterly, 21.8M installs
- Hybrid-casual, simple core + meta
- <$500K development cost
- **Lesson**: Hybrid-casual scales fast with right execution

**Balatro (Guide Reference):**
- Solo dev, $10M+ lifetime
- Unique mechanics in underserved niche (poker roguelike)
- Viral word-of-mouth
- **Lesson**: Distinctive gameplay in white space finds audiences

**Move Match Positioning:**
We're attempting the Balatro model (unique mechanics in white space) with Traffic Jam Fever execution (fast development, fresh theme) targeting Color Block Jam market size (hybrid-casual with viral potential).

Risk-adjusted expected outcome: $5K-30K lifetime revenue for Game #1, with learnings enabling $50K-150K for Game #2 if we nail the core loop.
