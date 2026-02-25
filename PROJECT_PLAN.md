# StokvelManager — Project Plan

> Digitize contributions, payouts, and meeting scheduling for South Africa's R50B+ stokvel economy.

---

## 1. Market Intelligence

### The Opportunity
- **11.6 million** South Africans participate in stokvels
- **~800,000** active stokvel groups (NASASA estimate)
- **R50 billion+** circulates annually — mostly tracked on paper and WhatsApp
- Stokvel types by share: 60% investment, 18% savings, 22% grocery/burial (StokFella founder data)
- Younger demographics (25-40) increasingly joining for property, holidays, weddings — not just groceries
- FNB services 120,000 stokvels but only offers bank accounts, not the governance/social layer

### Competitive Landscape

| Player | What They Do | Weakness |
|--------|-------------|----------|
| **StokFella** | Most established digital stokvel app. FSP-licensed. Retail voucher payouts. MTN Business App of the Year winner. | iOS app last updated 2021. Only 3 App Store reviews. Feels enterprise/corporate — not community-native. Tries to be a financial institution, not a tool. |
| **FNB Stokvel Accounts** | Digital account opening (Feb 2026). 120K groups. | Just a bank account — no contribution tracking, no governance, no social features. Three signatories required. |
| **Nedbank Stokvel** | Stokvel-specific savings. Grocery discount partnerships. | Same as FNB — banking layer only, no management tooling. |
| **Imbewu Stokvest** | Investment-focused stokvel app. | Niche — targets investors, ignores 40% of market (burial/grocery/savings). |
| **WhatsApp Groups** | The actual incumbent. Every stokvel has one. | Zero financial tracking. No payout automation. Trust issues (admins disappear with money). No audit trail. |

### The Gap
Nobody owns the **management layer**. Banks provide accounts. StokFella tried but over-financialized it. WhatsApp is where the activity happens but has zero tooling. The winner builds a WhatsApp-native management tool that's dead simple.

---

## 2. Stokvel Types We Must Support (MVP)

| Type | How It Works | % of Market |
|------|-------------|-------------|
| **Rotational/Savings** | Fixed monthly contribution; one member gets the full pot each cycle | ~60% |
| **Burial Society** | Monthly contribution; pays out on death/bereavement of member or family | ~12% |
| **Grocery** | Monthly contribution; bulk grocery purchase at year-end (Nov-Dec) | ~10% |
| **Investment** | Pooled funds invested (property, franchise, money market) | Growing |
| **Hybrid** | Combination (e.g., rotational + burial fund) | Common |

---

## 3. Product Vision

### Core Thesis
**StokvelManager is the operating system for stokvels.** Not a bank. Not an investment platform. A management tool that makes the treasurer's job easy and gives every member transparency.

### Design Principles
1. **WhatsApp-first** — stokvels live on WhatsApp. Meet them there.
2. **Offline-tolerant** — not everyone has data all the time
3. **Multilingual** — isiZulu, isiXhosa, Sesotho, English minimum at launch
4. **Trust through transparency** — every rand tracked, every member can verify
5. **Simple enough for gogos, powerful enough for investment clubs**

---

## 4. Feature Specification

### Phase 1 — MVP (8-10 weeks)

#### 4.1 Group Management
- Create stokvel group (name, type, constitution upload)
- Invite members via WhatsApp share link or QR code
- Role assignment: Chairperson, Treasurer, Secretary, Member
- Group constitution template generator (pre-filled by type)
- Member directory with contact info

#### 4.2 Contribution Tracking
- Define contribution schedule (weekly/monthly/custom)
- Record contributions (manual entry + proof of payment upload)
- Automated reminders via push notification + WhatsApp
- Dashboard: who's paid, who owes, running total
- Late payment flagging with configurable grace period
- Receipt generation (PDF) for each contribution

#### 4.3 Payout Management
- **Rotational:** Auto-calculate rotation order, next recipient display
- **Burial:** Claim submission flow (death certificate upload, beneficiary selection)
- **Grocery:** Year-end pool calculation, shopping list builder
- Payout history with full audit trail
- Member vote on payout disputes (in-app polling)

#### 4.4 Meeting Scheduler
- Schedule meetings (physical or virtual)
- Location pin (Google Maps integration)
- RSVP tracking
- Minutes recording (text or voice note)
- Action item assignment with due dates

#### 4.5 Communication
- In-app announcements (Chairperson → group)
- WhatsApp Business API integration for notifications
- Push notifications for contributions due, meetings, payouts

#### 4.6 Dashboard & Reporting
- Group financial overview (total collected, distributed, balance)
- Individual member statement
- Monthly/annual reports (downloadable PDF)
- Visual charts (contribution trends, member compliance)

### Phase 2 — Growth (post-MVP)

- **Bank integration** — Link to FNB/Nedbank/Capitec stokvel accounts for auto-reconciliation
- **USSD channel** — For feature phone users (`*120*STOKVEL#`)
- **Digital voting** — Constitutional amendments, new member approval, emergency payouts
- **Marketplace** — Bulk grocery deals, funeral service providers, investment products
- **NASASA registration** — In-app NASASA membership application
- **Loan/advance facility** — Member can request early payout (group votes)
- **Multi-currency** — Diaspora stokvels (UK, US-based SA communities)

### Phase 3 — Monetization & Scale

- **Premium tiers** — Free for ≤10 members; paid for larger groups or advanced features
- **Transaction fees** — Small % on in-app payments (if holding float)
- **Affiliate revenue** — Grocery partners, funeral services, investment products
- **Data insights** — Anonymized, aggregated stokvel economy data (for banks, researchers)
- **White-label** — Banks and corporates license the management layer

---

## 5. Technical Architecture

### 5.1 Stack Decision

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Mobile** | Flutter | Cross-platform (Android + iOS). Strong in SA dev community. Offline-first with Hive/Isar. Already have skills installed. |
| **Backend** | Supabase (PostgreSQL + Auth + Realtime + Storage) | Fast to ship. Row-level security for multi-tenant stokvel data. Realtime subscriptions for live dashboards. Auth with phone OTP (critical for SA market). |
| **Notifications** | Firebase Cloud Messaging + WhatsApp Business API | FCM for push; WhatsApp for the primary channel where stokvels live |
| **Payments** | Ozow / PayFast / Stitch (phase 2) | SA-native payment gateways. EFT, card, instant pay. No float-holding in MVP — just tracking. |
| **Hosting** | Supabase Cloud (MVP) → self-hosted or AWS Cape Town (scale) | Zero ops at start. AWS af-south-1 for data residency later. |
| **CI/CD** | GitHub Actions → Codemagic (iOS builds) | Standard Flutter pipeline. Codemagic handles Apple signing without a Mac. |

### 5.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    CLIENTS                           │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐ │
│  │ Flutter   │  │ Flutter   │  │ WhatsApp Business │ │
│  │ Android   │  │ iOS       │  │ API (Chatbot)     │ │
│  └─────┬─────┘  └─────┬─────┘  └────────┬──────────┘ │
│        │              │                  │           │
└────────┼──────────────┼──────────────────┼───────────┘
         │              │                  │
         ▼              ▼                  ▼
┌─────────────────────────────────────────────────────┐
│                  SUPABASE                            │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Auth      │  │ Realtime │  │ Edge Functions   │  │
│  │ (Phone    │  │ (Live    │  │ (Business logic, │  │
│  │  OTP)     │  │  updates)│  │  WhatsApp hooks) │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ PostgreSQL│  │ Storage  │  │ Cron (Reminders, │  │
│  │ (RLS)    │  │ (Docs,   │  │  Reports, Payout │  │
│  │          │  │  Photos)  │  │  Scheduling)     │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌──────────────┐          ┌──────────────────┐
│ Firebase FCM │          │ WhatsApp Cloud   │
│ (Push)       │          │ API (Meta)       │
└──────────────┘          └──────────────────┘
```

### 5.3 Data Model (Core)

```sql
-- Organizations
stokvels (
  id uuid PK,
  name text,
  type enum(rotational, burial, grocery, investment, hybrid),
  constitution_url text,        -- Supabase storage
  contribution_amount decimal,
  contribution_frequency enum(weekly, biweekly, monthly),
  currency text DEFAULT 'ZAR',
  created_at timestamptz,
  nasasa_registered boolean DEFAULT false
)

-- Members
stokvel_members (
  id uuid PK,
  stokvel_id uuid FK → stokvels,
  user_id uuid FK → auth.users,
  role enum(chairperson, treasurer, secretary, member),
  rotation_order int,           -- For rotational stokvels
  joined_at timestamptz,
  status enum(active, suspended, left)
)

-- Contributions
contributions (
  id uuid PK,
  stokvel_id uuid FK,
  member_id uuid FK → stokvel_members,
  amount decimal,
  due_date date,
  paid_date date,
  proof_url text,               -- Proof of payment image
  status enum(pending, paid, late, excused),
  recorded_by uuid FK           -- Treasurer who verified
)

-- Payouts
payouts (
  id uuid PK,
  stokvel_id uuid FK,
  recipient_id uuid FK → stokvel_members,
  amount decimal,
  payout_date date,
  type enum(rotation, burial_claim, grocery, investment_return),
  status enum(scheduled, approved, paid, disputed),
  approved_by uuid[],           -- Members who voted yes
  notes text
)

-- Meetings
meetings (
  id uuid PK,
  stokvel_id uuid FK,
  title text,
  date timestamptz,
  location_name text,
  location_lat decimal,
  location_lng decimal,
  virtual_link text,
  minutes text,
  rsvps jsonb                   -- {user_id: 'yes'|'no'|'maybe'}
)

-- Notifications
notifications (
  id uuid PK,
  stokvel_id uuid FK,
  target_user_id uuid,
  type enum(contribution_due, payout, meeting, announcement),
  channel enum(push, whatsapp, in_app),
  sent_at timestamptz,
  read_at timestamptz
)
```

### 5.4 Row-Level Security (Multi-Tenancy)

```sql
-- Members can only see their own stokvels
CREATE POLICY "members_see_own_stokvel" ON stokvels
  FOR SELECT USING (
    id IN (SELECT stokvel_id FROM stokvel_members WHERE user_id = auth.uid())
  );

-- Only treasurers can record contributions
CREATE POLICY "treasurer_records_contributions" ON contributions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM stokvel_members
      WHERE stokvel_id = contributions.stokvel_id
      AND user_id = auth.uid()
      AND role IN ('treasurer', 'chairperson')
    )
  );
```

---

## 6. Regulatory & Compliance

### Key Facts
- Stokvels are **exempt from the Banks Act** (1990 Reserve Bank exemption) — provided they register with NASASA
- NASASA regulates 125,000+ groups and 2.5M+ individuals
- If StokvelManager **does not hold money** (just tracks it), minimal regulatory burden
- If we **hold float or process payments**: need FSP license (FSCA), FICA compliance, POPIA

### MVP Strategy
- **Phase 1: Track only** — no money movement through the platform. Zero regulatory overhead.
- **Phase 2: Payment integration** — partner with licensed payment providers (Ozow, PayFast). They hold the compliance.
- **Phase 3: If we hold float** — apply for FSP license, engage compliance counsel.

### POPIA (Data Protection)
- Phone numbers and financial data are personal information
- Need: privacy policy, consent flows, data retention policy, right to deletion
- Supabase in EU by default — consider AWS af-south-1 for data residency

---

## 7. Go-to-Market Strategy

### Launch Market
- **Gauteng first** — highest concentration of stokvels, most digitally active
- Target: 25-45 age bracket, employed, smartphone users with existing stokvel

### Acquisition Channels
1. **WhatsApp viral loop** — "Your stokvel is using StokvelManager" invite links
2. **Community activations** — Township events, church groups, taxi ranks
3. **NASASA partnership** — They register 125K groups. Co-promote.
4. **Social media** — TikTok/Instagram targeting stokvel culture content
5. **Referral programme** — Free premium month for every group referred

### Messaging
- "Stop losing money to dishonest treasurers"
- "Know exactly where every rand is"
- "Your stokvel, your rules, your proof"

### KPIs (First 6 Months)
| Metric | Target |
|--------|--------|
| Registered groups | 500 |
| Active members | 5,000 |
| Monthly contribution events tracked | 10,000 |
| Retention (group active after 3 months) | 60% |
| App Store rating | 4.5+ |

---

## 8. Monetization Model

### Free Tier (Forever)
- Up to 15 members per group
- Contribution tracking
- Meeting scheduler
- Basic reports
- WhatsApp reminders (limited)

### Premium (R49/month per group)
- Unlimited members
- Advanced reporting & analytics
- Bank reconciliation
- Priority WhatsApp notifications
- Constitution templates library
- Voting & polling

### Enterprise (Custom)
- White-label for banks/corporates
- API access
- Bulk group management
- Dedicated support

### Revenue Projections (Conservative)

| Month | Free Groups | Premium Groups | MRR (ZAR) |
|-------|------------|----------------|------------|
| 6 | 400 | 100 | R4,900 |
| 12 | 1,500 | 500 | R24,500 |
| 18 | 4,000 | 1,500 | R73,500 |
| 24 | 8,000 | 3,000 | R147,000 |

---

## 9. Development Roadmap

### Sprint 0 — Foundation (Week 1-2)
- [ ] Flutter project scaffold with clean architecture
- [ ] Supabase project setup (auth, database, storage, edge functions)
- [ ] CI/CD pipeline (GitHub Actions + Codemagic)
- [ ] Design system: colours, typography, components (SA-inspired, warm, trustworthy)
- [ ] Repo: `skynergroup/stokvel-manager`

### Sprint 1 — Auth & Groups (Week 3-4)
- [ ] Phone OTP authentication
- [ ] Create stokvel group flow
- [ ] Invite members (WhatsApp share + QR)
- [ ] Group settings & roles
- [ ] Member list with status

### Sprint 2 — Contributions (Week 5-6)
- [ ] Define contribution schedule
- [ ] Record payment + proof upload
- [ ] Contribution dashboard (who paid, who owes)
- [ ] Automated reminder notifications (push)
- [ ] Receipt generation

### Sprint 3 — Payouts & Meetings (Week 7-8)
- [ ] Rotational payout calculator
- [ ] Payout request & approval flow
- [ ] Meeting scheduler with RSVP
- [ ] Location sharing
- [ ] Minutes recording

### Sprint 4 — Polish & Launch (Week 9-10)
- [ ] Reporting & PDF exports
- [ ] WhatsApp Business API integration
- [ ] Multilingual support (EN, isiZulu)
- [ ] Onboarding flow
- [ ] App Store & Play Store submission
- [ ] Landing page

---

## 10. Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Low adoption — stokvels prefer WhatsApp | High | Medium | WhatsApp-first strategy; bot that works inside existing groups |
| Trust — users won't put financial data in unknown app | High | High | NASASA endorsement, transparent security, open audit trails |
| Regulatory — FSCA flags us as unlicensed FSP | Medium | Low (MVP tracks only) | No money movement in Phase 1; partner with licensed providers later |
| StokFella has first-mover advantage | Medium | Low | They're stagnant (2021 iOS update). We move faster. |
| Data costs — SA users are data-conscious | Medium | Medium | Offline-first architecture; USSD fallback in Phase 2 |
| Fraud — fake groups or contribution disputes | Medium | Medium | Proof of payment uploads, admin approval, dispute resolution flow |

---

## 11. Team & Resources

### Minimum Viable Team
- **1 Flutter dev** (us — Astra builds)
- **1 Designer** (can contract; or we use existing design skills + Figma)
- **1 Domain expert** (stokvel chairperson as advisor — find one)

### Infrastructure Costs (Monthly)
| Item | Cost |
|------|------|
| Supabase Pro | $25 |
| WhatsApp Business API | ~$50 (1000 conversations) |
| Firebase (FCM) | Free |
| Codemagic (iOS builds) | $0-49 |
| Domain + hosting (landing page) | $10 |
| **Total** | **~$85-135/month** |

---

## 12. Success Criteria

**StokvelManager succeeds if:**
1. A stokvel chairperson can set up their group and track first contributions within 5 minutes
2. Every member can see exactly how much has been collected and who owes what
3. Not a single rand goes unaccounted for
4. Groups that adopt it never go back to paper

---

*Created: 2026-02-26*
*Status: Planning*
*Repo: TBD → skynergroup/stokvel-manager*
