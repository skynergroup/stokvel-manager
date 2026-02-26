# StokvelManager — Project Plan v2

> Digitize contributions, payouts, and meeting scheduling for South Africa's R50B+ stokvel economy.

---

## 1. Market Intelligence

### The Opportunity
- **11.6 million** South Africans participate in stokvels
- **~800,000** active stokvel groups (NASASA estimate)
- **R50 billion+** circulates annually — mostly tracked on paper and WhatsApp
- Stokvel types by share: 60% investment, 18% savings, 22% grocery/burial
- Younger demographics (25-40) increasingly joining for property, holidays, weddings
- FNB services 120,000 stokvels but only offers bank accounts, not the governance/social layer

### Competitive Landscape

| Player | What They Do | Weakness |
|--------|-------------|----------|
| **StokFella** | Most established digital stokvel app. FSP-licensed. | iOS app last updated 2021. Only 3 App Store reviews. Over-financialized. |
| **FNB Stokvel Accounts** | Digital account opening (Feb 2026). 120K groups. | Just a bank account — no contribution tracking, no governance. |
| **WhatsApp Groups** | The actual incumbent. Every stokvel has one. | Zero financial tracking. No automation. Trust issues. |

### The Gap
Nobody owns the **management layer**. Banks provide accounts. StokFella over-engineered. WhatsApp is where stokvels live but has zero tooling. The winner builds a WhatsApp-native management tool that's dead simple.

---

## 2. Product Channels

### Two entry points, one system:

1. **Mobile App** (Flutter — iOS + Android)
   - Full-featured management interface
   - For chairpersons, treasurers, and engaged members
   - Rich dashboards, forms, reports

2. **WhatsApp Bot** (added to existing stokvel groups)
   - The bot joins the group's existing WhatsApp chat
   - Members interact via natural commands: "pay", "balance", "next meeting"
   - Bot posts automatic updates: contribution reminders, payout notifications, meeting summaries
   - Zero app download required for basic participation
   - Syncs bidirectionally with the mobile app via Firebase

### NOT supported:
- ~~USSD / feature phones~~ — out of scope
- ~~Web dashboard~~ — mobile app + WhatsApp covers all use cases

---

## 3. Stokvel Types Supported

| Type | How It Works | Payout Logic |
|------|-------------|--------------|
| **Rotational** | Fixed monthly contribution; one member gets the full pot each cycle | Round-robin order, configurable |
| **Savings** | Fixed monthly contribution; pool accumulates, paid out at year-end | Lump sum split at defined date |
| **Burial Society** | Monthly contribution; pays out on death/bereavement | Claim-based with proof |
| **Grocery** | Monthly contribution; bulk grocery purchase Nov-Dec | Year-end pooled purchase |
| **Investment** | Pooled funds invested (property, franchise, money market) | Returns distributed proportionally |
| **Hybrid** | Any combination of the above | Configurable per fund |

---

## 4. Technical Architecture

### Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Mobile** | Flutter | Cross-platform. Offline-capable. Skills installed. |
| **Backend** | Firebase (Firestore + Auth + Cloud Functions + Storage + FCM) | Free Spark tier covers MVP easily. Google Cloud CLI already configured. |
| **WhatsApp Bot** | Cloud Functions + WhatsApp Business Cloud API (Meta) | Serverless. Triggers on incoming messages. Posts updates to groups. |
| **Payments** | Track-only (MVP). Ozow/PayFast integration Phase 2. | No money movement = no FSP license needed. |
| **CI/CD** | GitHub Actions + Codemagic (iOS) | Standard Flutter pipeline. |

### Why Firebase over Supabase
- **Free tier** — Firestore (1GB storage, 50K reads/day, 20K writes/day), Auth (phone OTP free), Cloud Functions (125K invocations/month), Storage (5GB), FCM (unlimited)
- **Phone OTP built-in** — critical for SA market, no third-party SMS provider needed
- **Cloud Functions** — perfect for WhatsApp bot webhook handlers
- **Offline-first** — Firestore has built-in offline persistence (crucial for data-conscious SA users)
- **Already configured** — Google Cloud CLI installed for Nexus

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENTS                             │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────────┐│
│  │ Flutter   │  │ Flutter   │  │ WhatsApp Bot           ││
│  │ Android   │  │ iOS       │  │ (in stokvel groups)    ││
│  └─────┬─────┘  └─────┬─────┘  └───────────┬────────────┘│
└────────┼──────────────┼─────────────────────┼─────────────┘
         │              │                     │
         ▼              ▼                     ▼
┌─────────────────────────────────────────────────────────┐
│                     FIREBASE                             │
│                                                         │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐ │
│  │ Auth          │  │ Firestore     │  │ Cloud        │ │
│  │ (Phone OTP)   │  │ (All data,   │  │ Functions    │ │
│  │               │  │  offline sync)│  │ (Bot logic,  │ │
│  │               │  │              │  │  reminders,   │ │
│  │               │  │              │  │  webhooks)    │ │
│  └──────────────┘  └───────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐ │
│  │ Cloud Storage │  │ FCM           │  │ Firestore    │ │
│  │ (Proof of    │  │ (Push notifs) │  │ Security     │ │
│  │  payment,    │  │               │  │ Rules        │ │
│  │  docs)       │  │               │  │ (Multi-      │ │
│  │              │  │               │  │  tenancy)    │ │
│  └──────────────┘  └───────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
         │                                    │
         ▼                                    ▼
┌──────────────────┐              ┌───────────────────────┐
│ WhatsApp Cloud   │              │ Ozow / PayFast        │
│ API (Meta)       │              │ (Phase 2 — payments)  │
└──────────────────┘              └───────────────────────┘
```

### Firestore Data Model

```
/stokvels/{stokvelId}
  name: string
  type: "rotational" | "savings" | "burial" | "grocery" | "investment" | "hybrid"
  constitutionUrl: string?
  contributionAmount: number
  contributionFrequency: "weekly" | "biweekly" | "monthly"
  currency: "ZAR"
  createdBy: string (uid)
  createdAt: timestamp
  memberCount: number
  totalCollected: number
  whatsappGroupId: string?       // linked WhatsApp group
  nasasaRegistered: boolean

  /members/{memberId}
    userId: string
    displayName: string
    phone: string
    role: "chairperson" | "treasurer" | "secretary" | "member"
    rotationOrder: number?
    joinedAt: timestamp
    status: "active" | "suspended" | "left"

  /contributions/{contributionId}
    memberId: string
    memberName: string
    amount: number
    dueDate: timestamp
    paidDate: timestamp?
    proofUrl: string?
    status: "pending" | "paid" | "late" | "excused"
    recordedBy: string
    createdAt: timestamp

  /payouts/{payoutId}
    recipientId: string
    recipientName: string
    amount: number
    payoutDate: timestamp
    type: "rotation" | "burial_claim" | "grocery" | "savings" | "investment_return"
    status: "scheduled" | "approved" | "paid" | "disputed"
    approvedBy: string[]
    notes: string?
    createdAt: timestamp

  /meetings/{meetingId}
    title: string
    date: timestamp
    locationName: string?
    locationLat: number?
    locationLng: number?
    virtualLink: string?
    agenda: string?
    minutes: string?
    rsvps: map<userId, "yes" | "no" | "maybe">
    createdBy: string
    createdAt: timestamp

/users/{userId}
  displayName: string
  phone: string
  avatarUrl: string?
  fcmTokens: string[]
  stokvels: string[]             // stokvelIds for quick lookup
  createdAt: timestamp
  settings: {
    darkMode: boolean
    language: "en" | "zu" | "xh" | "st"
    notificationsEnabled: boolean
  }

/notifications/{notificationId}
  userId: string
  stokvelId: string
  type: "contribution_due" | "contribution_received" | "payout" | "meeting" | "announcement"
  title: string
  body: string
  read: boolean
  createdAt: timestamp
```

### Firestore Security Rules (key excerpts)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Stokvel — only members can read
    match /stokvels/{stokvelId} {
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/stokvels/$(stokvelId)/members/$(request.auth.uid));
      allow create: if request.auth != null;

      // Members subcollection
      match /members/{memberId} {
        allow read: if request.auth != null &&
          exists(/databases/$(database)/documents/stokvels/$(stokvelId)/members/$(request.auth.uid));
        allow write: if isChairperson(stokvelId);
      }

      // Contributions — members read, treasurer/chair write
      match /contributions/{contribId} {
        allow read: if isMember(stokvelId);
        allow create, update: if isTreasurerOrChair(stokvelId);
      }

      // Payouts — members read, chair manages
      match /payouts/{payoutId} {
        allow read: if isMember(stokvelId);
        allow write: if isChairperson(stokvelId);
      }

      // Meetings — members read, any officer writes
      match /meetings/{meetingId} {
        allow read: if isMember(stokvelId);
        allow write: if isOfficer(stokvelId);
      }
    }
  }
}
```

---

## 5. WhatsApp Bot Architecture

### How It Works

1. **Stokvel chairperson** creates group in the app
2. App generates a **WhatsApp invite link** for the bot
3. Bot is added to the **existing WhatsApp group**
4. Bot introduces itself: "Hi! I'm StokvelManager Bot. I'll help track contributions and remind everyone when payments are due."
5. Members interact via simple commands — no app download needed for basic use

### Bot Commands (in-group)

| Command | What It Does | Example |
|---------|-------------|---------|
| `pay [amount]` | Log a contribution (member self-reports) | "pay 500" |
| `balance` | Show group balance + who owes | "balance" |
| `my balance` | Show individual contribution history | "my balance" |
| `next payout` | Show who's next in rotation | "next payout" |
| `next meeting` | Show next scheduled meeting | "next meeting" |
| `remind` | Trigger contribution reminder to all | "remind" (chair/treasurer only) |
| `help` | List all commands | "help" |

### Automated Bot Messages

| Trigger | Message |
|---------|---------|
| **3 days before contribution due** | "@everyone Reminder: R500 contribution due by Friday 28 Feb. 8/12 members have paid." |
| **Contribution recorded** | "✅ Thabo paid R500. 9/12 members have now paid for February." |
| **Payout completed** | "💰 R6,000 payout sent to Nomsa (February rotation). Next: Sipho in March." |
| **Meeting scheduled** | "📅 Meeting scheduled: Sat 1 March, 10:00 at Mam' Nkosi's house. RSVP by replying YES or NO." |
| **Weekly summary (Sunday)** | "📊 Weekly update: R4,500 collected this month. 3 members outstanding. Next payout: 28 Feb to Nomsa." |

### Tech Stack for Bot
- **Webhook receiver:** Firebase Cloud Function (HTTPS trigger)
- **WhatsApp API:** Meta WhatsApp Business Cloud API (free for first 1000 conversations/month)
- **State management:** Firestore (same DB as app — single source of truth)
- **Message templates:** Pre-approved Meta templates for proactive messages

---

## 6. Screen-by-Screen Specification

### 6.1 Splash Screen
```
┌─────────────────────────┐
│                         │
│                         │
│       [App Logo]        │
│     StokvelManager      │
│                         │
│     [Loading spinner]   │
│                         │
│                         │
└─────────────────────────┘
```
- Auto-routes: → Onboarding (first launch) or → Home (returning user)
- Duration: 2 seconds or until auth check completes

---

### 6.2 Onboarding (3 pages — PageView with dots)

**Page 1: "Track Every Rand"**
```
┌─────────────────────────┐
│                         │
│    [Illustration:       │
│     coins flowing       │
│     into a jar]         │
│                         │
│  Track Every Rand       │
│  See exactly who paid,  │
│  who owes, and where    │
│  every cent goes.       │
│                         │
│        ● ○ ○            │
│                         │
│  [Skip]     [Next →]    │
└─────────────────────────┘
```

**Page 2: "Never Miss a Payout"**
```
┌─────────────────────────┐
│                         │
│    [Illustration:       │
│     calendar with       │
│     money icons]        │
│                         │
│  Never Miss a Payout    │
│  Automatic rotation     │
│  scheduling and         │
│  reminders for every    │
│  member.                │
│                         │
│        ○ ● ○            │
│                         │
│  [Skip]     [Next →]    │
└─────────────────────────┘
```

**Page 3: "Your Group, Connected"**
```
┌─────────────────────────┐
│                         │
│    [Illustration:       │
│     people in circle    │
│     with phone]         │
│                         │
│  Your Group, Connected  │
│  WhatsApp reminders,    │
│  meeting scheduling,    │
│  and transparent        │
│  records for everyone.  │
│                         │
│        ○ ○ ●            │
│                         │
│     [Get Started →]     │
└─────────────────────────┘
```

- **Flow:** Swipe or tap Next → final page shows "Get Started" → navigates to Auth
- **Skip** button on pages 1-2 jumps to Auth
- Only shown on first launch (persisted in SharedPreferences)

---

### 6.3 Auth — Phone Number Screen
```
┌─────────────────────────┐
│  ←                      │
│                         │
│  Welcome to             │
│  StokvelManager         │
│                         │
│  Enter your phone       │
│  number to get started  │
│                         │
│  ┌───┬─────────────────┐│
│  │+27│ 82 123 4567     ││
│  └───┴─────────────────┘│
│                         │
│  We'll send you a       │
│  one-time code via SMS  │
│                         │
│  [    Continue    ]     │
│                         │
│  By continuing you      │
│  agree to our Terms     │
│  and Privacy Policy     │
└─────────────────────────┘
```

- **Country code** fixed to +27 (SA) with flag icon, expandable for other countries later
- **Phone input** auto-formats as user types (XX XXX XXXX)
- **Validation:** must be 9 digits after country code
- **Continue** → triggers Firebase phone OTP → navigates to OTP screen
- **Terms/Privacy** links open in-app webview

---

### 6.4 Auth — OTP Verification Screen
```
┌─────────────────────────┐
│  ←                      │
│                         │
│  Verify your number     │
│                         │
│  Enter the 6-digit      │
│  code sent to           │
│  +27 82 123 4567        │
│                         │
│  ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐
│  │ 4││ 8││ 2││ 1││  ││  │
│  └──┘└──┘└──┘└──┘└──┘└──┘
│                         │
│  Didn't receive code?   │
│  [Resend in 0:42]       │
│                         │
│  [    Verify     ]      │
│                         │
└─────────────────────────┘
```

- **6 individual boxes** — auto-advance on digit entry, auto-submit when 6th digit entered
- **Resend timer:** 60 second countdown, then "Resend Code" becomes tappable
- **Auto-verify:** Firebase can auto-detect SMS on Android
- **On success:** → Profile Setup (new user) or → Home (returning user)

---

### 6.5 Profile Setup (new users only)
```
┌─────────────────────────┐
│                         │
│  Set up your profile    │
│                         │
│      [Avatar circle]    │
│      [Tap to add photo] │
│                         │
│  Full Name              │
│  ┌─────────────────────┐│
│  │ Thabo Molefe        ││
│  └─────────────────────┘│
│                         │
│  Preferred Language     │
│  ┌─────────────────────┐│
│  │ English          ▼  ││
│  └─────────────────────┘│
│  (English, isiZulu,     │
│   isiXhosa, Sesotho)   │
│                         │
│  [   Save & Continue  ] │
└─────────────────────────┘
```

- **Avatar:** Optional. Camera or gallery picker.
- **Name:** Required. Used across the app and in WhatsApp bot messages.
- **Language:** Sets app language + WhatsApp bot message language for this user.

---

### 6.6 Home — Bottom Navigation (4 tabs)
```
┌─────────────────────────┐
│  StokvelManager    [🔔] │
│─────────────────────────│
│                         │
│  [Active tab content]   │
│                         │
│                         │
│                         │
│                         │
│                         │
│─────────────────────────│
│  🏠      👥     💰    👤│
│ Home   Groups  Money Profile│
└─────────────────────────┘
```

- **Bell icon** top-right → Notifications screen
- **4 tabs:** Home (dashboard), Groups (my stokvels), Money (contributions/payouts), Profile

---

### 6.7 Home Tab — Dashboard
```
┌─────────────────────────┐
│  StokvelManager    [🔔] │
│─────────────────────────│
│                         │
│  Good morning, Thabo 👋 │
│                         │
│  ┌─────────────────────┐│
│  │ 💰 Total Savings    ││
│  │    R12,400           ││
│  │    Across 2 groups   ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ 📅 Next Contribution ││
│  │    R500 due in 3 days││
│  │    → Umoja Savings   ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ 🎯 Next Payout      ││
│  │    Your turn! R6,000 ││
│  │    → Umoja Savings   ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ 📍 Next Meeting     ││
│  │    Sat 1 Mar, 10:00 ││
│  │    Mam' Nkosi's     ││
│  └─────────────────────┘│
│                         │
│  Recent Activity        │
│  ├ Nomsa paid R500  2h  │
│  ├ Meeting set     12h  │
│  └ Sipho paid R500  1d  │
│                         │
│─────────────────────────│
│  🏠      👥     💰    👤│
└─────────────────────────┘
```

- **Greeting** changes by time of day (Good morning/afternoon/evening)
- **Summary cards** show data across ALL user's stokvels
- **Next Contribution** card — tappable, navigates to that group's contributions
- **Next Payout** card — highlighted if it's the user's turn
- **Next Meeting** card — tappable, shows meeting detail
- **Recent Activity** — last 5 events across all groups, each tappable
- **Pull to refresh**

---

### 6.8 Groups Tab — My Groups List
```
┌─────────────────────────┐
│  My Groups         [🔔] │
│─────────────────────────│
│                         │
│  ┌─────────────────────┐│
│  │ Umoja Savings       ││
│  │ [Rotational] 12 members│
│  │ R6,000/month        ││
│  │ Balance: R48,000    ││
│  │ Your turn: March    ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ Kasi Burial Society ││
│  │ [Burial] 25 members ││
│  │ R200/month          ││
│  │ Balance: R15,000    ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ Year-End Grocery    ││
│  │ [Grocery] 8 members ││
│  │ R300/month          ││
│  │ Balance: R7,200     ││
│  │ Payout: December    ││
│  └─────────────────────┘│
│                         │
│              [+ Create] │
│─────────────────────────│
│  🏠      👥     💰    👤│
└─────────────────────────┘
```

- **Group cards** show: name, type chip (color-coded), member count, contribution amount, current balance
- **Type chips:** Rotational=gold, Burial=purple, Grocery=green, Savings=blue, Investment=teal
- **Tap card** → Group Detail
- **FAB** (+) → Create Group flow
- **Empty state:** "You're not in any stokvels yet. Create one or ask your chairperson for an invite link."

---

### 6.9 Group Detail — Tabbed View
```
┌─────────────────────────┐
│  ← Umoja Savings   [⚙] │
│─────────────────────────│
│  ┌─────────────────────┐│
│  │ Balance: R48,000    ││
│  │ 12 members · R6,000/m│
│  │ [Rotational]        ││
│  │ Next payout: Thabo  ││
│  └─────────────────────┘│
│                         │
│  [Overview][Members][💰][📅]│
│─────────────────────────│
│                         │
│  (Tab content below)    │
│                         │
└─────────────────────────┘
```

**Overview tab:**
- Group stats (total collected, total paid out, months active)
- Contribution compliance chart (fl_chart — bar chart showing % paid per month)
- Constitution document link (if uploaded)
- WhatsApp bot status (connected/not connected)

**Members tab:**
```
│  Chairperson            │
│  ┌─────────────────────┐│
│  │ 👤 Nomsa M.  [Chair]││
│  └─────────────────────┘│
│                         │
│  Treasurer              │
│  ┌─────────────────────┐│
│  │ 👤 Sipho S.  [Treas]││
│  └─────────────────────┘│
│                         │
│  Members                │
│  ┌─────────────────────┐│
│  │ 👤 Thabo M. #3      ││
│  │ 👤 Lerato K. #4     ││
│  │ 👤 Bongani D. #5    ││
│  │ ...                  ││
│  └─────────────────────┘│
│                         │
│  [+ Invite Member]      │
```
- Role badges (Chair, Treasurer, Secretary)
- Rotation order number for rotational stokvels
- Invite button generates WhatsApp share link + QR code
- Chairperson can tap member → assign role, change order, suspend

**Contributions tab:**
```
│  February 2026          │
│  ┌─────────────────────┐│
│  │ ✅ Nomsa    R500    ││
│  │ ✅ Sipho    R500    ││
│  │ ✅ Thabo    R500    ││
│  │ ⏳ Lerato   R500 DUE││
│  │ ❌ Bongani  R500 LATE│
│  │ ...                  ││
│  └─────────────────────┘│
│  8/12 paid · R4,000     │
│                         │
│  January 2026           │
│  ┌─────────────────────┐│
│  │ ✅ All 12 paid      ││
│  │ Total: R6,000       ││
│  └─────────────────────┘│
│                         │
│  [+ Record Payment]     │
```
- Grouped by month, most recent first
- Status icons: ✅ paid, ⏳ pending, ❌ late
- **Record Payment** (treasurer/chair only) → Record Contribution Screen
- Tap on a contribution → detail with proof of payment image

**Payouts tab:**
```
│  Rotation Schedule      │
│  ┌─────────────────────┐│
│  │ Jan  ✅ Nomsa R6,000││
│  │ Feb  ✅ Sipho R6,000││
│  │ Mar  ▶ THABO R6,000 ││
│  │ Apr  ○ Lerato       ││
│  │ May  ○ Bongani      ││
│  │ ...                  ││
│  └─────────────────────┘│
│                         │
│  [Request Payout]       │
```
- Visual timeline of rotation order
- Current month highlighted with arrow
- Past payouts show ✅ with amount
- For burial stokvels: shows claims list instead of rotation

---

### 6.10 Create Group Flow (multi-step)

**Step 1: Group Info**
```
┌─────────────────────────┐
│  ← Create Stokvel  1/4 │
│─────────────────────────│
│                         │
│  Group Name             │
│  ┌─────────────────────┐│
│  │ Umoja Savings       ││
│  └─────────────────────┘│
│                         │
│  Stokvel Type           │
│  ┌─────────────────────┐│
│  │ Rotational       ▼  ││
│  └─────────────────────┘│
│                         │
│  Description (optional) │
│  ┌─────────────────────┐│
│  │ Monthly savings club ││
│  │ for our community   ││
│  └─────────────────────┘│
│                         │
│  [        Next →      ] │
└─────────────────────────┘
```

**Step 2: Contribution Setup**
```
┌─────────────────────────┐
│  ← Create Stokvel  2/4 │
│─────────────────────────│
│                         │
│  Contribution Amount    │
│  ┌──┬──────────────────┐│
│  │R │ 500              ││
│  └──┴──────────────────┘│
│                         │
│  Frequency              │
│  [Weekly] [Biweekly]    │
│  [●Monthly] [Custom]    │
│                         │
│  Due Date               │
│  ┌─────────────────────┐│
│  │ Last day of month ▼ ││
│  └─────────────────────┘│
│                         │
│  Grace Period           │
│  ┌─────────────────────┐│
│  │ 3 days           ▼  ││
│  └─────────────────────┘│
│                         │
│  [        Next →      ] │
└─────────────────────────┘
```

**Step 3: Constitution**
```
┌─────────────────────────┐
│  ← Create Stokvel  3/4 │
│─────────────────────────│
│                         │
│  Group Constitution     │
│                         │
│  Every stokvel needs    │
│  rules. Choose how:     │
│                         │
│  ┌─────────────────────┐│
│  │ 📝 Use our template ││
│  │ Pre-filled based on  ││
│  │ your stokvel type   ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ 📄 Upload your own  ││
│  │ PDF or photo of your ││
│  │ existing constitution││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ ⏭ Skip for now      ││
│  │ You can add this     ││
│  │ later in settings   ││
│  └─────────────────────┘│
│                         │
│  [        Next →      ] │
└─────────────────────────┘
```

**Step 4: Invite Members**
```
┌─────────────────────────┐
│  ← Create Stokvel  4/4 │
│─────────────────────────│
│                         │
│  Invite Members         │
│                         │
│  Share this link with   │
│  your stokvel members:  │
│                         │
│  ┌─────────────────────┐│
│  │ stokvelmanager.app/  ││
│  │ join/abc123    [📋]  ││
│  └─────────────────────┘│
│                         │
│  ┌──────────┐           │
│  │ [QR Code]│           │
│  │          │           │
│  └──────────┘           │
│                         │
│  [Share via WhatsApp]   │
│                         │
│  ── or add manually ──  │
│                         │
│  Phone number           │
│  ┌───┬────────────┬───┐ │
│  │+27│ 82 123 4567│[+]│ │
│  └───┴────────────┴───┘ │
│                         │
│  [   Create Stokvel   ] │
└─────────────────────────┘
```

---

### 6.11 Money Tab — Contributions & Payouts Overview
```
┌─────────────────────────┐
│  Money             [🔔] │
│─────────────────────────│
│                         │
│  [Contributions][Payouts]│
│─────────────────────────│
│                         │
│  Contributions tab:     │
│  ┌─────────────────────┐│
│  │ Umoja Savings       ││
│  │ R500 due 28 Feb     ││
│  │ Status: ⏳ Pending   ││
│  │ [Mark as Paid]      ││
│  └─────────────────────┘│
│                         │
│  ┌─────────────────────┐│
│  │ Kasi Burial Society ││
│  │ R200 due 28 Feb     ││
│  │ Status: ✅ Paid     ││
│  └─────────────────────┘│
│                         │
│  History                │
│  ├ Jan — R700 (2 groups)│
│  ├ Dec — R700 (2 groups)│
│  └ Nov — R700 (2 groups)│
│                         │
│─────────────────────────│
│  🏠      👥     💰    👤│
└─────────────────────────┘
```

- **Contributions sub-tab:** All upcoming contributions across all groups
- **Payouts sub-tab:** Upcoming payouts the user will receive + past payouts
- Tapping any item navigates to that group's detail

---

### 6.12 Record Contribution Screen (Treasurer only)
```
┌─────────────────────────┐
│  ← Record Payment       │
│─────────────────────────│
│                         │
│  Member                 │
│  ┌─────────────────────┐│
│  │ Thabo Molefe     ▼  ││
│  └─────────────────────┘│
│                         │
│  Amount                 │
│  ┌──┬──────────────────┐│
│  │R │ 500              ││
│  └──┴──────────────────┘│
│  [Pre-filled from group]│
│                         │
│  Payment Date           │
│  ┌─────────────────────┐│
│  │ 25 Feb 2026      📅 ││
│  └─────────────────────┘│
│                         │
│  Proof of Payment       │
│  ┌─────────────────────┐│
│  │                     ││
│  │   [📷 Take Photo]   ││
│  │   [📁 Upload File]  ││
│  │                     ││
│  └─────────────────────┘│
│                         │
│  Notes (optional)       │
│  ┌─────────────────────┐│
│  │ Cash at meeting     ││
│  └─────────────────────┘│
│                         │
│  [  Record Payment    ] │
└─────────────────────────┘
```

- **Member dropdown** shows all group members
- **Amount** pre-filled from group settings, editable
- **Proof** — camera capture or gallery upload, stored in Firebase Storage
- **On save:** updates Firestore → triggers WhatsApp bot notification to group → updates dashboard
- **Receipt:** auto-generates a PDF receipt (downloadable/shareable)

---

### 6.13 Schedule Meeting Screen
```
┌─────────────────────────┐
│  ← Schedule Meeting     │
│─────────────────────────│
│                         │
│  Meeting Title          │
│  ┌─────────────────────┐│
│  │ March Monthly Meeting│
│  └─────────────────────┘│
│                         │
│  Date & Time            │
│  ┌────────────┬────────┐│
│  │ 1 Mar 2026 │ 10:00  ││
│  └────────────┴────────┘│
│                         │
│  Location               │
│  ● In Person            │
│  ┌─────────────────────┐│
│  │ Mam' Nkosi's house  ││
│  │ 📍 Tap to set pin   ││
│  └─────────────────────┘│
│  ○ Virtual              │
│                         │
│  Agenda                 │
│  ┌─────────────────────┐│
│  │ 1. February finances ││
│  │ 2. New member vote  ││
│  │ 3. Year-end plans   ││
│  └─────────────────────┘│
│                         │
│  [Send via WhatsApp ✓]  │
│                         │
│  [ Schedule Meeting   ] │
└─────────────────────────┘
```

- **Location toggle** between in-person (with map pin) and virtual (with meeting link)
- **"Send via WhatsApp"** checkbox — posts meeting details to the linked WhatsApp group
- **On save:** creates meeting in Firestore, sends FCM push, optionally sends WhatsApp message

---

### 6.14 Notifications Screen
```
┌─────────────────────────┐
│  ← Notifications        │
│─────────────────────────│
│                         │
│  Today                  │
│  ┌─────────────────────┐│
│  │● Nomsa paid R500    ││
│  │  Umoja Savings · 2h ││
│  └─────────────────────┘│
│  ┌─────────────────────┐│
│  │● Meeting scheduled  ││
│  │  Kasi Burial · 5h   ││
│  └─────────────────────┘│
│                         │
│  Yesterday              │
│  ┌─────────────────────┐│
│  │○ Contribution due   ││
│  │  R500 · Umoja · 1d  ││
│  └─────────────────────┘│
│  ┌─────────────────────┐│
│  │○ Sipho paid R500    ││
│  │  Umoja Savings · 1d ││
│  └─────────────────────┘│
│                         │
└─────────────────────────┘
```

- **● unread** / **○ read** indicators
- Grouped by day
- Tap → navigates to relevant screen (contribution, meeting, etc.)
- Swipe to dismiss

---

### 6.15 Profile Screen
```
┌─────────────────────────┐
│  ← Profile              │
│─────────────────────────│
│                         │
│      [Avatar circle]    │
│      Thabo Molefe       │
│      +27 82 123 4567    │
│      [Edit Profile]     │
│                         │
│  ── Settings ──         │
│                         │
│  Language          [EN▼]│
│  Dark Mode         [  ]│
│  Notifications     [✓] │
│  WhatsApp Alerts   [✓] │
│                         │
│  ── About ──            │
│                         │
│  Terms of Service    → │
│  Privacy Policy      → │
│  Help & Support      → │
│  Rate the App        → │
│                         │
│  ── Account ──          │
│                         │
│  [   Log Out          ] │
│  [   Delete Account   ] │
│                         │
│  v1.0.0                 │
│                         │
└─────────────────────────┘
```

---

## 7. User Flows

### Flow 1: New User Joins Existing Stokvel
```
WhatsApp invite link → App Store/Play Store → Install → Splash → Onboarding (3 pages)
→ Phone Auth (+27) → OTP → Profile Setup → Home (empty dashboard)
→ Tap invite link again → Join confirmation → Group appears in My Groups
→ Dashboard populates with group data
```

### Flow 2: Chairperson Creates New Stokvel
```
Home → Groups tab → (+) Create → Step 1 (name, type) → Step 2 (contribution, frequency)
→ Step 3 (constitution) → Step 4 (invite link/QR) → Share via WhatsApp
→ Group created → Add WhatsApp bot to group → Bot introduces itself
→ Members join via link → Group populates
```

### Flow 3: Treasurer Records Monthly Contributions
```
Groups → Select group → Contributions tab → [+ Record Payment]
→ Select member → Confirm amount → Upload proof (photo of cash/EFT) → Save
→ Firestore updated → WhatsApp bot posts "✅ Thabo paid R500"
→ Push notification to all members → Dashboard updated
```

### Flow 4: Monthly Rotation Payout
```
Cloud Function triggers on payout date → Identifies next recipient
→ Push notification: "It's Thabo's turn for the R6,000 payout"
→ WhatsApp bot posts in group
→ Chairperson confirms payout in app → Status: Paid
→ WhatsApp bot: "💰 R6,000 payout sent to Thabo"
```

### Flow 5: WhatsApp-Only Member Checks Balance
```
Member types "balance" in WhatsApp group
→ Meta webhook → Cloud Function receives message
→ Queries Firestore for group data
→ Bot replies: "Umoja Savings | Balance: R48,000 | 8/12 paid for Feb | Your status: ✅ Paid"
```

### Flow 6: Meeting Flow
```
Chair → Group Detail → Meetings → [Schedule Meeting]
→ Fill title, date, location, agenda → Save
→ Firestore created → WhatsApp bot: "📅 Meeting: Sat 1 Mar, 10:00 at Mam' Nkosi's"
→ Members reply YES/NO in WhatsApp → Bot updates RSVPs
→ App shows RSVP count → Meeting happens → Chair records minutes in app
```

---

## 8. Development Roadmap

### Sprint 0 — Foundation (Week 1-2) [SKY-47]
- [ ] Flutter project scaffold with clean architecture
- [ ] Firebase project setup (Auth, Firestore, Storage, Functions, FCM)
- [ ] Design system (colors, typography, component themes)
- [ ] Routing with go_router
- [ ] All placeholder screens with real UI
- [ ] Shared widgets + models
- [ ] CI/CD pipeline

### Sprint 1 — Auth & Groups (Week 3-4) [SKY-48]
- [ ] Phone OTP authentication (Firebase Auth)
- [ ] Profile setup flow
- [ ] Create stokvel group (4-step flow)
- [ ] Invite members (WhatsApp share + QR code)
- [ ] Group detail with tabs
- [ ] Member management (roles, order)

### Sprint 2 — Contributions & Money (Week 5-6) [SKY-49]
- [ ] Contribution schedule engine
- [ ] Record payment + proof upload (Firebase Storage)
- [ ] Contribution dashboard per group
- [ ] Money tab (cross-group view)
- [ ] Push notifications (FCM) for due dates
- [ ] Receipt PDF generation

### Sprint 3 — Payouts & Meetings (Week 7-8) [SKY-50]
- [ ] Rotation payout calculator
- [ ] Payout request & approval flow
- [ ] Meeting scheduler with RSVP
- [ ] Location map integration
- [ ] Minutes recording
- [ ] Cloud Functions for automated reminders

### Sprint 4 — WhatsApp Bot & Launch (Week 9-10) [SKY-51]
- [ ] WhatsApp Business Cloud API integration
- [ ] Cloud Functions webhook handlers
- [ ] Bot commands (pay, balance, next payout, next meeting)
- [ ] Automated notifications (reminders, confirmations, summaries)
- [ ] Multilingual support (EN, isiZulu)
- [ ] App Store + Play Store submission
- [ ] Landing page

---

## 9. Monetization Model

### Free Tier (Forever)
- Up to 15 members per group
- 3 groups max
- Contribution tracking + payouts
- WhatsApp bot (basic commands)
- Meeting scheduler

### Premium — R49/month per group
- Unlimited members
- Unlimited groups
- Advanced analytics + charts
- PDF reports + receipts
- Priority WhatsApp notifications
- Constitution templates
- Voting & polling

---

## 10. Regulatory Notes
- **Phase 1: Track only** — no money movement = no FSP license needed
- **POPIA compliance** — privacy policy, consent flows, data deletion
- **NASASA partnership** opportunity — they regulate 125K groups
- **Phase 2 payments:** partner with licensed providers (Ozow, PayFast)

---

*Created: 2026-02-26*
*Updated: 2026-02-26 (v2 — Firebase, WhatsApp bot, detailed screens)*
*Status: In Progress — SKY-47*
*Repo: skynergroup/stokvel-manager*
