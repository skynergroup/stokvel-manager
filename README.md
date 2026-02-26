# StokvelManager

Digitize contributions, payouts, and meeting scheduling for South Africa's R50B+ stokvel economy.

## Features

- **Phone OTP Auth** — Firebase phone authentication with +27 (SA) prefix
- **Google SSO** — One-tap sign-in via Google
- **Group Management** — Create and manage stokvels (rotational, savings, burial, grocery, investment, hybrid)
- **Contribution Tracking** — Record payments with proof-of-payment uploads
- **Payout Rotation** — Visual rotation schedule with automatic ordering
- **Meeting Scheduler** — Schedule meetings with RSVP tracking and WhatsApp notifications
- **Dashboard** — Cross-group overview of savings, contributions, payouts, and meetings
- **Notifications** — Push notifications via FCM with in-app notification center
- **WhatsApp Bot** — Cloud Functions-powered bot for balance checks, reminders, and group notifications
- **Dark Mode** — Full light and dark theme support
- **Multilingual** — English, isiZulu (i18n with ARB files)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (iOS + Android) |
| Auth | Firebase Auth (Phone OTP + Google SSO) |
| Database | Cloud Firestore |
| Storage | Firebase Cloud Storage |
| Push | Firebase Cloud Messaging |
| WhatsApp Bot | Firebase Cloud Functions + WhatsApp Cloud API |
| Navigation | go_router |
| State | flutter_riverpod |
| i18n | flutter_localizations + ARB |
| CI/CD | GitHub Actions |

## Architecture

```
lib/
├── core/
│   ├── theme/          # Colors, typography, ThemeData
│   ├── routing/        # go_router config, route names
│   └── services/       # Firebase singleton
├── shared/
│   ├── models/         # Data models (Stokvel, Member, Contribution, Payout, Meeting)
│   └── widgets/        # Reusable UI components
├── features/
│   ├── onboarding/     # Splash screen, 3-page onboarding flow
│   ├── auth/           # Phone auth, OTP, Google SSO, profile setup
│   ├── dashboard/      # Home tab with summary cards
│   ├── groups/         # Group list, detail (tabbed), create flow
│   ├── contributions/  # Contribution tracking, record payment
│   ├── payouts/        # Payout rotation schedule
│   ├── meetings/       # Meeting list, schedule meeting
│   ├── profile/        # User profile, settings
│   └── notifications/  # Notification center
├── l10n/               # Localization (ARB files, locale config)
└── main.dart

functions/              # Firebase Cloud Functions (TypeScript)
├── src/
│   ├── whatsapp/       # Webhook handler, commands, message sender
│   └── triggers/       # Firestore triggers, scheduled reminders
└── package.json
```

## Setup

### Prerequisites

- Flutter SDK 3.11+
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 18+ (for Cloud Functions)
- A Firebase project with Auth, Firestore, Storage, and FCM enabled

### Getting Started

```bash
# Clone the repository
git clone https://github.com/SkynerGroup/stokvel-manager.git
cd stokvel-manager

# Install Flutter dependencies
flutter pub get

# Configure Firebase (generates firebase_options.dart)
flutterfire configure

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Phone Authentication and Google Sign-In in Firebase Auth
3. Create a Firestore database (start in test mode, deploy rules later)
4. Enable Cloud Storage
5. Run `flutterfire configure` to generate `firebase_options.dart`
6. Deploy security rules: `firebase deploy --only firestore:rules`
7. Deploy indexes: `firebase deploy --only firestore:indexes`

### Cloud Functions Setup

```bash
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy functions
firebase deploy --only functions
```

### WhatsApp Bot Setup

1. Create a Meta Business App at [developers.facebook.com](https://developers.facebook.com)
2. Add the WhatsApp product to your app
3. In WhatsApp > API Setup, get your:
   - **Phone Number ID** — the ID of your WhatsApp Business phone number
   - **Permanent Token** — generate a system user token with `whatsapp_business_messaging` permission
4. Copy `functions/.env.example` to `functions/.env` and fill in:
   ```
   WHATSAPP_TOKEN=your_permanent_token
   WHATSAPP_PHONE_ID=your_phone_number_id
   VERIFY_TOKEN=any_random_string_you_choose
   ```
5. Set Firebase environment config:
   ```bash
   firebase functions:secrets:set WHATSAPP_TOKEN
   firebase functions:secrets:set WHATSAPP_PHONE_ID
   firebase functions:secrets:set VERIFY_TOKEN
   ```
6. Deploy functions: `firebase deploy --only functions`
7. In Meta Developer Console > WhatsApp > Configuration:
   - Set Webhook URL to: `https://<region>-<project-id>.cloudfunctions.net/whatsappWebhook`
   - Set Verify Token to the same value as `VERIFY_TOKEN`
   - Subscribe to `messages` webhook field

### Bot Commands

| Command | Description |
|---------|-------------|
| `balance` | Group balance & who's paid |
| `my balance` | Your contribution history |
| `next payout` | Who's next in rotation |
| `next meeting` | Next scheduled meeting |
| `remind` | Send payment reminder (admin only) |
| `help` | List all commands |

## Screenshots

> Screenshots will be added after UI implementation is complete.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/SKY-XX-feature-name`)
3. Commit your changes (`git commit -m 'SKY-XX: Description'`)
4. Push to the branch (`git push origin feat/SKY-XX-feature-name`)
5. Open a Pull Request

## License

Proprietary — SkynerGroup (Pty) Ltd. All rights reserved.
