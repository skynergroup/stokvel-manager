# StokvelManager

Digitize contributions, payouts, and meeting scheduling for South Africa's R50B+ stokvel economy.

## Features

- **Phone OTP Auth** — Firebase phone authentication with +27 (SA) prefix
- **Group Management** — Create and manage stokvels (rotational, savings, burial, grocery, investment, hybrid)
- **Contribution Tracking** — Record payments with proof-of-payment uploads
- **Payout Rotation** — Visual rotation schedule with automatic ordering
- **Meeting Scheduler** — Schedule meetings with RSVP tracking and WhatsApp notifications
- **Dashboard** — Cross-group overview of savings, contributions, payouts, and meetings
- **Notifications** — Push notifications via FCM with in-app notification center
- **Dark Mode** — Full light and dark theme support
- **Multilingual** — English, isiZulu, isiXhosa, Sesotho

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (iOS + Android) |
| Auth | Firebase Auth (Phone OTP) |
| Database | Cloud Firestore |
| Storage | Firebase Cloud Storage |
| Push | Firebase Cloud Messaging |
| Navigation | go_router |
| State | flutter_riverpod |
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
│   ├── onboarding/     # 3-page onboarding flow
│   ├── auth/           # Phone auth, OTP, profile setup
│   ├── dashboard/      # Home tab with summary cards
│   ├── groups/         # Group list, detail (tabbed), create flow
│   ├── contributions/  # Contribution tracking, record payment
│   ├── payouts/        # Payout rotation schedule
│   ├── meetings/       # Meeting list, schedule meeting
│   ├── profile/        # User profile, settings
│   └── notifications/  # Notification center
└── main.dart
```

## Setup

### Prerequisites

- Flutter SDK 3.11+
- Firebase CLI
- A Firebase project with Auth, Firestore, Storage, and FCM enabled

### Getting Started

```bash
# Clone the repository
git clone https://github.com/SkynerGroup/stokvel-manager.git
cd stokvel-manager

# Install dependencies
flutter pub get

# Configure Firebase (add your own firebase_options.dart)
flutterfire configure

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Phone Authentication in Firebase Auth
3. Create a Firestore database
4. Enable Cloud Storage
5. Run `flutterfire configure` to generate `firebase_options.dart`
6. Deploy security rules: `firebase deploy --only firestore:rules`

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
