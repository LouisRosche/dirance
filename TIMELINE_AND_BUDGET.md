# Move Match - Development Timeline & Budget
## 12-Month Roadmap for Solo Developer

---

## Executive Budget Summary

### Total Year 1 Investment: $12,650

| Category | Amount | % of Total |
|----------|--------|------------|
| **Development** | $600 | 5% |
| **Marketing** | $8,500 | 67% |
| **Infrastructure** | $850 | 7% |
| **Legal/Business** | $2,700 | 21% |

### Expected Year 1 Revenue (Conservative): $40,000-80,000

**Best Case ROI:** $80,000 revenue - $12,650 costs = **$67,350 profit** (532% ROI)
**Conservative Case:** $40,000 revenue - $12,650 costs = **$27,350 profit** (216% ROI)
**Realistic Case (Guide Data):** $15,000-25,000 revenue = **$2,350-12,350 profit**

> **Reality Check from Guide:** "First games typically earn <$5K lifetime. Second games: 40% better. Only top 15% hit $108K+."
>
> This game has higher odds due to emerging category + TikTok virality, but keep day job until Month 6 metrics prove viability.

---

## Development Timeline (Week-by-Week)

### Phase 1: Pre-Production (Weeks 1-4)

#### Week 1: Validation & Setup
**Time: 30 hours**
**Deliverables:**
- [ ] Market research validation (confirm no competing camera-dance-puzzle games)
- [ ] Technical spike: ARKit body tracking proof-of-concept
  - Simple app that detects jump, squat, arm raise
  - Test on iPhone XS, 12, 14 (different hardware)
- [ ] Setup development environment:
  - Xcode 15+
  - Firebase project created
  - Git repository initialized
  - Apple Developer account ($99)

**Success Criteria:** ARKit successfully detects 3 basic moves with 80%+ accuracy

**Costs:**
- Apple Developer Account: $99

---

#### Week 2: Core Mechanic Prototype
**Time: 35 hours**
**Deliverables:**
- [ ] Move detection for all 7 core moves:
  - Jump, Squat, Arm Raise L/R, Side Step L/R, Spin
- [ ] Calibration flow (5-second "stand here" setup)
- [ ] Basic combo system (track consecutive correct moves)
- [ ] Simple test UI: Shows detected moves in real-time

**Success Criteria:** 10 internal testers can successfully complete "5 Jumps → 3 Squats" sequence

**Costs:** $0

---

#### Week 3: Music Integration Prototype
**Time: 30 hours**
**Deliverables:**
- [ ] Apple Music API integration (request library access)
- [ ] Song selection UI (list user's songs)
- [ ] Basic BPM detection (analyze audio, estimate tempo)
- [ ] Audio playback with precise timing (AVAudioEngine)
- [ ] On-beat detection algorithm (±150ms tolerance)

**Success Criteria:** Play any song from user's library, detect BPM within ±5 accuracy

**Costs:** $0

---

#### Week 4: Puzzle Generation Prototype + External Validation
**Time: 25 hours development + 10 hours testing**
**Deliverables:**
- [ ] Puzzle generator creates 3 challenges per song:
  - Simple repetition (Level 1): "Do 5 Jumps"
  - Combo sequence (Level 2): "Jump → Squat → Arms"
  - Timing challenge (Level 3): "10 on-beat moves"
- [ ] Difficulty scaling (adjust based on user level)
- [ ] Recruit 10 beta testers (friends, family, r/iOSGaming)
- [ ] **CRITICAL VALIDATION GATE:** 70%+ testers say "I'd play daily"

**Success Criteria:**
- ✅ 7+ out of 10 testers enthusiastic ("This is fun, I'd play daily")
- ✅ Testers complete 3+ songs in 15-minute session
- ✅ No major usability complaints (calibration works, moves detect reliably)

**Decision Point:**
- **If validation passes:** Continue to full development
- **If validation fails (<70% positive):** PIVOT
  - Option A: Simplify to tap-rhythm game (no camera)
  - Option B: Change core mechanic (fewer moves, easier detection)
  - Option C: Abandon, start different project

**Costs:** $0

---

### Phase 2: Core Development (Weeks 5-16)

#### Weeks 5-6: Game Loop Foundation
**Time: 60 hours**
**Deliverables:**
- [ ] Main menu UI (Play, Settings, Shop, Leaderboard)
- [ ] Song selection screen (grid view, search, BPM display)
- [ ] Pre-game flow: Song selected → Calibration → Countdown → Start
- [ ] In-game HUD: Current puzzle, combo counter, score, song progress
- [ ] Post-game results screen: Stars (1-3), XP earned, coins earned
- [ ] Particle effects for combos (satisfying visuals)

**Costs:** $0

---

#### Weeks 7-8: Polish Core Experience
**Time: 55 hours**
**Deliverables:**
- [ ] All 7 move types fully implemented & tuned
- [ ] Combo multiplier system (2x, 5x, 10x, 20x milestones)
- [ ] Audio design:
  - SFX for move detection (satisfying "pop")
  - Combo milestone sounds (crescendo at 10x, 20x)
  - Background music (menu screens)
- [ ] Tutorial flow:
  - 3-step onboarding: (1) Calibration, (2) Try first move, (3) Complete simple puzzle
- [ ] 10 curated test songs with pre-generated puzzles

**Asset Purchases:**
- UI Kit (GameDev Market): $40
- SFX Pack (Unity Asset Store): $30
- Particle Effects Pack: $25

**Costs:** $95

---

#### Weeks 9-10: Meta-Progression System
**Time: 50 hours**
**Deliverables:**
- [ ] Player profile: Level, XP, total calories, stats
- [ ] Unlock system:
  - 15 move unlocks (Double Jump, Power Squat, etc.)
  - 5 characters (different stats, cosmetic)
  - 10 power-ups (Beat Assist, Slow-Mo, Free Pass)
- [ ] Skill tree UI (visual progression map)
- [ ] Upgrade shop (spend coins to unlock)
- [ ] Character selection screen

**Costs:** $0

---

#### Weeks 11-12: Season Pass & Dailies
**Time: 45 hours**
**Deliverables:**
- [ ] Season Pass framework:
  - 30 tiers (free + premium tracks)
  - XP progression bar
  - Tier rewards (coins, gems, moves, cosmetics)
  - Purchase flow for premium pass ($4.99)
- [ ] Daily quest system:
  - 3 quests per day (e.g., "Complete 3 songs," "Burn 100 calories")
  - Quest UI (progress tracking, claim rewards)
  - Reset at midnight UTC
- [ ] Daily login rewards (7-day streak calendar)

**Costs:** $0

---

#### Weeks 13-14: Monetization Integration
**Time: 50 hours**
**Deliverables:**
- [ ] AdMob SDK integration + mediation (AppLovin, Unity Ads)
- [ ] Rewarded video ads:
  - Placement 1: "Watch to double XP" (post-song)
  - Placement 2: "Retry with power-up" (after fail)
  - Placement 3: "Unlock song early" (optional)
- [ ] Frequency capping (max 1 ad per 2 songs)
- [ ] StoreKit 2 In-App Purchases:
  - 6 products (gems packs, Season Pass, VIP subscription, ad-free day pass)
  - Purchase validation & entitlement grants
  - Transaction history
- [ ] Soft currency (coins) & hard currency (gems) economy
- [ ] Shop UI (browse, preview, purchase)

**Costs:** $0

---

#### Weeks 15-16: Social Features & Leaderboards
**Time: 50 hours**
**Deliverables:**
- [ ] Firebase Firestore integration:
  - User profiles
  - Song high scores
  - Season Pass progress
  - Purchase history
- [ ] Redis Cloud leaderboard:
  - Daily, Weekly, All-Time rankings
  - Friend leaderboard (local device contacts)
  - Efficient O(log n) ranking queries
- [ ] Leaderboard UI (top 100, your rank, nearby players)
- [ ] Firebase Analytics events:
  - song_played, puzzle_completed, purchase, ad_watched
- [ ] Crashlytics error tracking

**Costs:**
- Redis Cloud: $0 (free tier for launch)

---

### Phase 3: TikTok Integration & Virality (Weeks 17-18)

#### Weeks 17-18: Recording & Sharing System
**Time: 50 hours**
**Deliverables:**
- [ ] ReplayKit screen recording:
  - Auto-record during gameplay (opt-in prompt)
  - Capture front camera + game UI overlay
  - Include song audio
- [ ] AI highlight detection:
  - Analyze combo history
  - Find best 15-second moment (highest combo streak)
- [ ] Video export:
  - Trim to 15-second TikTok format (vertical 9:16)
  - Add watermark overlay ("Move Match" logo in corner)
  - Add text overlay (e.g., "Beat my 25x combo!")
- [ ] Share sheet integration:
  - One-tap share to TikTok, Instagram, Twitter
  - Pre-filled caption with hashtags (#MoveMatchChallenge)
- [ ] In-game incentive: "Share to TikTok → 200 gems"

**Costs:** $0

---

### Phase 4: Polish & Testing (Weeks 19-20)

#### Week 19: Bug Fixing & Optimization
**Time: 40 hours**
**Deliverables:**
- [ ] Performance optimization:
  - ARKit runs at stable 30 FPS (no lag)
  - Thermal throttling detection
  - Battery usage optimization
  - Memory leak fixes
- [ ] Edge case handling:
  - Poor lighting warning
  - User moves out of frame → pause game
  - No songs in library → prompt to add
- [ ] Accessibility:
  - VoiceOver support (UI labels)
  - Manual tap controls fallback (for vision failures)
  - Adjustable difficulty settings
- [ ] Comprehensive bug testing (all devices: iPhone XS, 12, 14, SE)

**Costs:** $0

---

#### Week 20: Beta Testing & Launch Prep
**Time: 30 hours**
**Deliverables:**
- [ ] Recruit 12+ testers for Google Play closed testing requirement
  - (Even though this is iOS, good practice for future Android)
  - Friends, r/TestFlight, BetaFamily service
- [ ] 14-day TestFlight beta:
  - Collect feedback
  - Monitor crashes (Firebase Crashlytics)
  - Iterate on pain points
- [ ] App Store submission prep:
  - Privacy policy (TermsFeed generator - free)
  - Support email & website
  - App Store screenshots (5 images)
  - App preview video (30 seconds)
  - App description (optimized keywords)
  - Rating: 4+ (no COPPA concerns)
- [ ] Marketing assets:
  - Press kit (screenshots, logo, fact sheet)
  - Landing page (Carrd.co)

**Costs:**
- BetaFamily (optional): $50 (for 20 testers)
- Carrd landing page: $19/year
- Total: $69

---

### Phase 5: Launch & Live Ops (Weeks 21-52)

#### Week 21: Launch Week
**Time: 20 hours**
**Deliverables:**
- [ ] **Day 1 - App Store Release:**
  - Submit to App Store review (expect 24-48 hour approval)
  - Monitor for approval
- [ ] **Day 2 - Launch Day:**
  - 9 AM: Email beta list (500+ signups)
  - 10 AM: Reddit posts (r/iOSGaming, r/FitnessGaming)
  - 11 AM: TikTok launch video on @movematchgame
  - 12 PM: Instagram/Twitter announcements
  - 2 PM: Discord celebration (first 100 downloads)
  - 4 PM: Engage with all comments, shares
- [ ] **Day 3-7: Respond & Iterate:**
  - Reply to App Store reviews
  - Fix critical bugs (hotfix if needed)
  - Monitor Firebase Analytics (retention, monetization)
  - Start paid UA campaigns (TikTok, Apple Search Ads)

**Launch Week Budget:**
- TikTok Ads: $1,000
- Apple Search Ads: $500
- Meta Ads: $400
- Total: $1,900

**Target Metrics (Week 21):**
- 2,000 downloads
- 40% D1 retention
- 10+ App Store reviews
- $200-500 revenue

---

#### Weeks 22-26 (Month 2): Optimize & Scale
**Time: 15 hours/week (live ops)**
**Focus:**
- [ ] Weekly song drops (3-5 new curated tracks)
- [ ] Daily challenge updates (via Firebase Remote Config - no app update)
- [ ] A/B testing:
  - Season Pass pricing ($2.99 vs $4.99)
  - Ad frequency (1 per 2 songs vs 1 per 3 songs)
  - Share incentive (100 gems vs 200 gems)
- [ ] Community management:
  - Respond to reviews (30 min/day)
  - Discord engagement (20 min/day)
  - TikTok content (3 posts/week)
- [ ] Micro-influencer outreach:
  - Contact 10 creators/week
  - 2 partnerships ($500 total)
- [ ] Monitor KPIs:
  - DAU growing?
  - Retention stable?
  - ARPDAU increasing?
  - Viral coefficient >0.3?

**Monthly Budget (Weeks 22-26):**
- TikTok Ads: $1,000
- Influencers: $500
- Apple Search Ads: $500
- Meta Ads: $400
- Tools (AppTweak): $50
- Total: $2,450

**Target Metrics (Month 2 End):**
- 10,000 total downloads
- 38% D1, 18% D7 retention
- $1,500-3,000 monthly revenue
- 5+ organic TikTok videos from users

---

#### Weeks 27-39 (Months 3-5): Stabilize & Grow
**Time: 10-15 hours/week**
**Focus:**
- [ ] Monthly major updates:
  - Month 3: New game mode ("Endless Mode" - survive as long as possible)
  - Month 4: Social features (challenge friends, ghost data races)
  - Month 5: Apple Health integration (sync calories, workouts)
- [ ] Season Pass rollover (new 30 tiers each month)
- [ ] Event calendar:
  - 2x XP weekends (via Remote Config)
  - Holiday themes (Halloween, Thanksgiving, Winter)
- [ ] Continued marketing:
  - TikTok Ads: $1,000/mo
  - Influencers: $1,000/mo (2-3 partnerships)
  - Apple Search Ads: $500/mo
  - Meta Retargeting: $400/mo
- [ ] Optimize based on data:
  - Which puzzles have highest completion rates?
  - Which songs are most popular?
  - Where are users churning? (funnel analysis)

**Monthly Budget (Months 3-5, avg $2,900/mo):**
- Total: $8,700 over 3 months

**Target Metrics (Month 5 End):**
- 50,000 total downloads
- 40% D1, 20% D7 retention
- $8,000-15,000 monthly revenue
- 50+ organic UGC videos
- Top 10 UGC videos: 500K+ combined views

---

#### Weeks 40-52 (Months 6-12): Scale & Decide
**Time: 10 hours/week**
**Focus:**
- [ ] Evaluate Month 6 metrics against success criteria:
  - **Go Decision:** Revenue >$10K/mo, retention >40% D1, viral TikTok traction
    - Continue live ops
    - Plan Android version (Unity port)
    - Consider raising small funding round ($50K-100K for marketing scale)
  - **Pivot Decision:** Revenue <$5K/mo, retention <15% D7, no viral traction
    - Put game in maintenance mode (minimal updates)
    - Apply learnings to Game #2 (guide says 40% better performance)
    - Keep small marketing budget to sustain existing users
- [ ] If continuing:
  - Major feature releases (multiplayer, tournaments, clan system)
  - Cross-promotion with other indie games (Chartboost exchange)
  - Explore partnerships (fitness brands, music labels)
  - Plan v2.0 (Android, expanded song library, advanced moves)

**Monthly Budget (Months 6-12 if continuing):**
- Marketing: $2,000/mo avg
- Infrastructure (Firebase scaling): $200-500/mo
- Total: ~$2,500/mo × 7 months = $17,500

**Target Metrics (Month 12):**
- 150,000 total downloads
- 100K MAU (monthly active users)
- $40,000-80,000 monthly revenue
- 200+ organic UGC videos
- Profitable enough to quit day job? (need $60K+/year = $5K/mo personal salary)

---

## Detailed Budget Breakdown

### One-Time Costs (Year 1)

| Item | Cost | When | Notes |
|------|------|------|-------|
| Apple Developer Account | $99 | Week 1 | Annual renewal |
| UI Asset Pack | $40 | Week 7 | GameDev Market |
| SFX Pack | $30 | Week 8 | Unity Asset Store |
| Particle Effects | $25 | Week 8 | Unity Asset Store |
| Music Licensing | $0 | N/A | Users provide via Apple Music |
| BetaFamily Testers | $50 | Week 20 | Optional, 20 testers |
| Landing Page (Carrd) | $19 | Week 12 | Annual |
| **Total One-Time** | **$263** | | |

---

### Recurring Monthly Costs

#### Development Phase (Months 1-5):

| Item | Cost/Month | Notes |
|------|------------|-------|
| Apple Developer | $8 | $99/year amortized |
| Firebase | $0 | Free tier (<10K users) |
| Redis Cloud | $0 | Free tier |
| Domain | $1 | $12/year amortized |
| Epidemic Sound | $15 | Optional music for trailers |
| **Total** | **~$25/mo** | |

#### Growth Phase (Months 6-12, 50K-100K users):

| Item | Cost/Month | Notes |
|------|------------|-------|
| Firebase | $150-200 | Firestore, Analytics, Storage |
| Redis Cloud | $30-50 | Leaderboards at scale |
| AppTweak (ASO) | $50 | Keyword tracking |
| Domain + Hosting | $5 | |
| Epidemic Sound | $15 | |
| **Total** | **~$250-320/mo** | |

---

### Marketing Budget (6 Months)

| Channel | Month 1 | Month 2 | Month 3 | Month 4 | Month 5 | Month 6 | Total |
|---------|---------|---------|---------|---------|---------|---------|-------|
| TikTok Ads | $1,000 | $1,000 | $1,000 | $1,000 | $1,000 | $1,000 | $6,000 |
| Micro-Influencers | $500 | $500 | $1,000 | $1,000 | $1,000 | $1,000 | $5,000 |
| Apple Search Ads | $500 | $500 | $500 | $500 | $500 | $500 | $3,000 |
| Meta Ads | $400 | $400 | $400 | $400 | $400 | $400 | $2,400 |
| ASO Tools | $50 | $50 | $50 | $50 | $50 | $50 | $300 |
| **Monthly Total** | **$2,450** | **$2,450** | **$2,950** | **$2,950** | **$2,950** | **$2,950** | **$16,700** |

**6-Month Total: $16,700** (but we budgeted $8,500 for conservative solo dev)

**Revised Conservative Marketing (6 Months): $8,500**
- Cut months 4-6 budgets in half if Month 3 metrics don't hit targets
- Focus on highest ROI (TikTok + Influencers)

---

### Legal & Business

| Item | Cost | When | Notes |
|------|------|------|-------|
| LLC Formation | $550 | Before revenue | State filing, registered agent |
| Privacy Policy | $0 | Week 20 | TermsFeed free generator |
| Terms of Service | $0 | Week 20 | Free template |
| Business Insurance | $500 | Year 1 | Optional but recommended |
| Accounting (DIY) | $0 | Ongoing | Use Wave (free) or QuickBooks Self-Employed ($15/mo) |
| Tax Prep | $200 | Year-end | CPA for first year |
| **Total Legal/Business** | **$1,250** | | |

---

## Complete Year 1 Budget Summary

### Costs:

| Category | Amount |
|----------|--------|
| Development (assets, tools) | $263 |
| Infrastructure (hosting, SaaS) | $850 |
| Marketing (6 months) | $8,500 |
| Legal & Business | $1,250 |
| Contingency (10%) | $1,086 |
| **TOTAL YEAR 1 COSTS** | **$11,949** |

**Rounded: $12,000 total investment**

---

### Revenue Projections (Conservative):

| Timeframe | Downloads | DAU | Monthly Revenue | Cumulative |
|-----------|-----------|-----|-----------------|------------|
| Month 1 | 5,000 | 2,000 | $750 | $750 |
| Month 2 | 10,000 | 5,000 | $1,500 | $2,250 |
| Month 3 | 20,000 | 12,000 | $3,500 | $5,750 |
| Month 4 | 35,000 | 20,000 | $6,000 | $11,750 |
| Month 5 | 50,000 | 30,000 | $9,000 | $20,750 |
| Month 6 | 75,000 | 50,000 | $15,000 | $35,750 |
| Month 7-12 | 150,000 | 100,000 | $25,000/mo avg | $185,750 |

**Year 1 Total Revenue (Conservative): $185,750**
**After Platform Cuts (30%):** $130,000
**Minus Costs:** $130,000 - $12,000 = **$118,000 profit**

---

### Revenue Projections (Realistic, Guide-Adjusted):

> "First games earn <$5K lifetime typically. Top 15%: $108K. Median: $5K-13K."

**Realistic Scenario:**
- Month 1-3: $2,000 total (slow start)
- Month 4-6: $10,000 total (growth)
- Month 7-12: $30,000 total (if retention good)
- **Year 1 Total: $42,000 gross → $29,400 after platform cuts**
- **Profit: $29,400 - $12,000 = $17,400**

**This would put the game in top 20-30% of indie releases** — a success for Game #1!

---

## Cash Flow Planning

### Pre-Launch (Weeks 1-20): -$2,550 outflow
- Development: $263
- Infrastructure: $125 (5 months × $25)
- Legal: $550
- Pre-launch marketing: $19 (landing page)

**Fund from:** Personal savings (ideally $3K-5K cushion for peace of mind)

---

### Months 1-3: -$5,300 net (revenue starts slowly)
- Marketing: $7,350
- Infrastructure: $75
- Revenue: $2,250 (gross) → $1,575 (net)
- **Net: -$5,800**

**Cumulative Cash Need: $8,350**

---

### Months 4-6: +$2,400 net (break-even to profitable)
- Marketing: $8,850
- Infrastructure: $750
- Revenue: $30,000 (gross) → $21,000 (net)
- **Net: +$11,400**

**Cumulative: +$3,050** (paid back initial investment!)

---

### Months 7-12: +$100K+ net (if scaling)
- Marketing: $12,000 (continued growth)
- Infrastructure: $2,000
- Revenue: $150,000 (gross) → $105,000 (net)
- **Net: +$91,000**

**End of Year 1: +$94,000 profit** (best case)

---

### Realistic Cash Flow (Guide-Adjusted):

- Months 1-6: -$10,000 (investment phase)
- Months 7-12: +$20,000 (if retention/virality works)
- **End of Year 1: +$10,000 profit**

**This is a WIN for a first indie game.** Most lose money. Breaking even or small profit = validation for Game #2.

---

## Risk Management & Contingency Planning

### Financial Risks:

**Risk 1: Marketing doesn't deliver installs**
- Mitigation: Start with $500 test budgets, scale only what works
- Contingency: Cut marketing to $2K total, focus on organic (ASO, Reddit, TikTok organic)

**Risk 2: Monetization fails (low ARPDAU)**
- Mitigation: A/B test pricing, ad frequency early (Month 1-2)
- Contingency: Pivot to ads-only or IAP-only (whatever works)

**Risk 3: Development takes 2x longer (solo dev delays)**
- Mitigation: Cut scope (launch with 15 unlocks instead of 30, skip features)
- Contingency: Extend timeline to 6-8 months, but MUST ship before losing momentum

**Risk 4: ARKit tracking unreliable (technical failure)**
- Mitigation: Extensive Week 2-4 testing, fallback to manual controls
- Contingency: Pivot to tap-rhythm game (abandon computer vision)

---

### Time Risks (Solo Developer):

**Assumption:** 30 hours/week (part-time, keeping day job)

**If full-time (60 hours/week):**
- Development: 10 weeks instead of 20
- Launch: Week 10 instead of Week 21
- Pros: Faster to market
- Cons: Higher opportunity cost (lost salary), more risk

**If ultra-part-time (10 hours/week):**
- Development: 60 weeks (14 months)
- Launch: Month 14
- Pros: Keep income, less risk
- Cons: Market may shift, lose motivation, competitor may launch

**Recommendation: 20-30 hours/week = 5-6 month timeline**
- Balanced risk
- Sustainable pace
- Launch before burning out

---

## Key Decision Gates

### Week 4 Gate: Prototype Validation
**Question:** Do 7+ out of 10 testers love the core loop?
- ✅ Yes → Proceed to full development
- ❌ No → PIVOT (simplify mechanic, change concept, or abandon)

**Investment to Date:** ~$100 + 120 hours work
**Decision Impact:** Saves 400+ hours and $12K if core concept is broken

---

### Week 12 Gate: Pre-Launch Hype
**Question:** Did landing page get 500+ emails? Any social media traction?
- ✅ Yes → Proceed with planned marketing budget
- ⚠️ Lukewarm → Cut marketing budget in half, rely on organic
- ❌ No → Red flag, consider delaying launch to build audience

**Investment to Date:** $500 + 300 hours work

---

### Month 3 Gate: Early Metrics Review
**Question:** Are retention & monetization tracking to targets?
- ✅ D7 >15%, ARPDAU >$0.08 → Continue marketing, scale up
- ⚠️ D7 10-15%, ARPDAU $0.05-0.08 → Iterate on features, moderate marketing
- ❌ D7 <10%, ARPDAU <$0.05 → Maintenance mode, start Game #2

**Investment to Date:** $6,000 + 400 hours work

---

### Month 6 Gate: Go/No-Go on Full Commitment
**Question:** Is this worth quitting day job or going all-in?
- ✅ Revenue >$15K/mo, growing → Consider full-time (or raise funding)
- ⚠️ Revenue $5-15K/mo, stable → Continue part-time, plan Android version
- ❌ Revenue <$5K/mo → Maintenance mode, apply learnings to Game #2

**From Guide:**
> "Don't quit day job until 2nd or 3rd release proves sustainable revenue."

**Even if Month 6 revenue is $15K/mo, keep day job for stability.** Wait until Month 12 or Game #2 before going full-time.

---

## Time Allocation (Solo Developer)

### Development Phase (Weeks 1-20):

| Activity | Hours/Week | % of Time |
|----------|------------|-----------|
| Coding | 20-25 | 70% |
| Design (UI/UX, puzzles) | 3-5 | 12% |
| Testing | 2-3 | 8% |
| Marketing prep (landing page, socials) | 2-3 | 8% |
| Admin (finances, planning) | 1 | 3% |
| **Total** | **30-35 hr/wk** | **100%** |

---

### Live Ops Phase (Weeks 21+):

| Activity | Hours/Week | % of Time |
|----------|------------|-----------|
| Content updates (new songs, challenges) | 3-5 | 30% |
| Community management (reviews, Discord, socials) | 3-4 | 25% |
| Marketing (influencer outreach, TikTok posts, ads mgmt) | 3-4 | 25% |
| Analytics & optimization (A/B tests, data review) | 2 | 15% |
| Bug fixes & support | 1-2 | 10% |
| **Total** | **12-17 hr/wk** | **100%** |

**Note:** Live ops is MUCH lighter than development (12-17 hr/wk vs 30-35 hr/wk)

This allows solo dev to:
- Keep day job comfortably (nights & weekends)
- Start working on Game #2 in parallel (if Game #1 in maintenance mode)
- Have work/life balance (avoid burnout)

---

## Tools & Subscriptions Summary

### Essential (Required):

| Tool | Cost | Purpose |
|------|------|---------|
| Xcode | Free | Development |
| Swift/SwiftUI | Free | Programming |
| Firebase | Free (then $150-200/mo at scale) | Backend |
| Redis Cloud | Free (then $30-50/mo at scale) | Leaderboards |
| AdMob | Free (rev share) | Monetization |
| Apple Developer | $99/year | App Store |
| **Total** | **$99/year + $0-250/mo** | |

---

### Recommended (High ROI):

| Tool | Cost | Purpose |
|------|------|---------|
| AppTweak | $50/mo | ASO optimization |
| Carrd | $19/year | Landing page |
| CapCut | Free | TikTok video editing |
| Firebase Analytics | Free | Metrics |
| **Total** | **$50/mo + $19/year** | |

---

### Optional (Nice to Have):

| Tool | Cost | Purpose |
|------|------|---------|
| Sensor Tower | $99/mo (use 1 month only) | Competitive research |
| Epidemic Sound | $15/mo | Music for trailers |
| AppFollow | $50/mo | Review monitoring |
| BetaFamily | $50 one-time | Beta testers |
| QuickBooks Self-Employed | $15/mo | Accounting |
| **Total** | **~$100/mo** | |

**Recommendation:** Start with Essential + Recommended only ($150/mo). Add optional tools only if revenue >$5K/mo.

---

## Success Metrics Dashboard (Track Weekly)

### Acquisition:
- [ ] Total downloads
- [ ] Organic vs Paid %
- [ ] Cost per Install (CPI)
- [ ] Top traffic sources

### Engagement:
- [ ] Daily Active Users (DAU)
- [ ] Avg session length
- [ ] Songs completed per session
- [ ] Feature usage (which moves are most popular?)

### Retention:
- [ ] D1 retention %
- [ ] D7 retention %
- [ ] D30 retention %
- [ ] Cohort analysis (which cohorts stick around?)

### Monetization:
- [ ] Daily revenue
- [ ] ARPDAU (revenue per DAU)
- [ ] Paying user %
- [ ] ARPPU (revenue per paying user)
- [ ] Top grossing products
- [ ] Ad fill rate & eCPM

### Virality:
- [ ] TikTok shares per 100 sessions
- [ ] Organic UGC videos created
- [ ] Top 10 UGC video views
- [ ] Viral coefficient (new users per existing user)

### Support:
- [ ] App Store rating (target: >4.0)
- [ ] Crash-free rate (target: >99%)
- [ ] Support tickets (target: <5/day)

**Review dashboard every Monday. Make weekly adjustments based on data.**

---

## The Bottom Line: Is This Worth It?

### Investment Required:
- **Money:** $12,000
- **Time:** 600-800 hours (5-6 months part-time)
- **Opportunity Cost:** Could earn $12K-30K from day job in same time

### Expected Return (Realistic):
- **Best Case:** $100K+ Year 1 profit → Quit day job, go full-time indie
- **Good Case:** $20-40K Year 1 profit → Keep day job, fund Game #2
- **Realistic Case:** $5-15K Year 1 profit → Validation for Game #2 (40% better)
- **Worst Case:** Break even or small loss → Learning experience, apply to Game #2

### Intangible Returns:
- Shipped product (portfolio piece)
- Technical skills (ARKit, Firebase, monetization)
- Marketing skills (ASO, TikTok ads, influencer outreach)
- Community (players, other devs)
- Ownership (your game, your rules)

### The Guide's Wisdom:
> "Success rarely comes with first releases. Typically requires 3-5 games before sustainable revenue. Second games average 40% better performance."

**Move Match is a strategic bet:**
- Higher odds than average (emerging category, TikTok-native)
- Lower risk than quitting job (part-time, controlled budget)
- Valuable learning for Game #2 (even if modest financial success)

**Proceed if:**
- ✅ You have $15K liquid savings (can afford the risk)
- ✅ You can commit 20-30 hr/week for 6 months
- ✅ You're building for long-term (3-5 game portfolio), not get-rich-quick
- ✅ You're passionate about fitness gaming + AR

**Reconsider if:**
- ❌ You need Game #1 to replace your salary
- ❌ You can't afford to lose $12K
- ❌ You're chasing trends without genuine interest
- ❌ You expect overnight viral success

---

## Next Steps (Week 1 Starts Now)

1. **Day 1:** Read all docs (this file, game design, technical architecture, GTM strategy)
2. **Day 2:** Make go/no-go decision (are you in?)
3. **Day 3-5:** Setup (Apple Developer account, Xcode, Firebase, Git repo)
4. **Week 1:** ARKit prototype (prove move detection works)
5. **Week 4:** External validation (10 testers say "hell yes" or pivot)
6. **Week 21:** Launch!

**The journey starts with a single commit. Good luck! 🚀**
