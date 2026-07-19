# SharePlate

<p align="center">
  <strong>"Share More. Waste Less."</strong><br>
  <em>A modern Flutter platform connecting surplus food donors with charities to eliminate food waste and fight hunger.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/State%20Management-Riverpod-blueviolet" alt="Riverpod">
  <img src="https://img.shields.io/badge/Backend-Firebase%20%7C%20Demo%20Mode-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Maintainer-Mrityunjay%20Tiwari-1B5E3C" alt="Maintainer">
</p>

---

## Maintainer & Authorship

- **Project Maintainer & Lead Developer**: **Mrityunjay Tiwari** ([@mrityunjay5004](https://github.com/mrityunjay5004))
- **Repository**: [https://github.com/mrityunjay5004/SharePlate](https://github.com/mrityunjay5004/SharePlate)

SharePlate is an independently maintained, customized application engineered by Mrityunjay Tiwari to provide a production-ready, beautiful food rescue ecosystem with advanced impact tracking and a modern green/cream design system.

---

## Table of Contents

- [Overview](#overview)
- [Key Features & Custom Implementations](#key-features--custom-implementations)
- [Visual Showcase & Screenshots](#visual-showcase--screenshots)
- [Architecture & Directory Structure](#architecture--directory-structure)
- [Deterministic Matching Algorithm](#deterministic-matching-algorithm)
- [Getting Started & Local Setup](#getting-started--local-setup)
- [Pre-Configured Demo Accounts](#pre-configured-demo-accounts)
- [Firebase & Maps Configuration](#firebase--maps-configuration)
- [Data Model & Firestore Schema](#data-model--firestore-schema)
- [Attribution & Licensing Notice](#attribution--licensing-notice)

---

## Overview

Food waste is one of the leading drivers of avoidable greenhouse gas emissions, yet food banks and community pantries continually face supply shortages. **SharePlate** bridges this gap:

1. **For Donors** (Restaurants, Bakeries, Supermarkets, Caterers): Easily publish surplus food listings within seconds, specifying quantities, categories, pickup locations, and expiry windows.
2. **For Charities & Food Banks**: Browse incoming donations in real time, view rule-based priority matches, claim food, and coordinate seamless physical pickups.
3. **For Community Administrators**: Monitor city-wide redistribution, track carbon avoidance metrics, and ensure platform safety.

---

## Key Features & Custom Implementations

SharePlate introduces significant enhancements and proprietary features developed by Mrityunjay Tiwari:

### 1. Brand Identity & Curated Design System
- **Palette**: Forest Green (`#1B5E3C`), Fresh Mint (`#4E9B6E`), Cream Canvas (`#FBF9F5`), Crisp White (`#FFFFFF`), and Charcoal (`#1F2937`).
- Reusable UI component library designed for high readability and micro-interactions:
  - `UrgencyBadge`: Dynamic color-coded pill with real-time countdown calculation.
  - `DonationTimeline`: Intuitive vertical progression showing handoff lifecycle.
  - `CategoryChip` & `StatusChip`: Semantic chips with status-driven styling.
  - `ImpactSummaryCard`: Environmental metrics dashboard with benchmark comparisons.

### 2. Environmental Impact Accounting Engine
- Calculates verifiable sustainability metrics using methodologies adapted from the **UN Environment Programme (UNEP) Food Waste Index** and **US EPA WARM benchmarks**:
  - **Meals Shared**: Standardized portion metric ($\approx 400\text{g}$ per portion).
  - **Food Diverted**: Weight in kilograms rescued from landfill disposal.
  - **Emissions Diverted**: Landfill methane emissions avoided ($\approx 2.5\text{ kg CO}_2\text{e}$ per kg food rescued).
  - **Handoffs Completed**: Physical rescue transfers completed.

### 3. 5-Stage Physical Donation Lifecycle
- Replaced ambiguous statuses with an end-to-end physical handoff workflow:
  $$\text{Available} \longrightarrow \text{Requested} \longrightarrow \text{Accepted} \longrightarrow \text{Picked Up} \longrightarrow \text{Completed}$$
- Both donor and charity confirm milestone handoffs directly in the app.

### 4. Multi-Dimensional Food Discovery
- **Instant Search**: Search by food title, donor organization, description, or city.
- **Category Filtering**: Cooked Meals, Bakery & Bread, Fresh Produce, Dairy & Eggs, Pantry & Canned Goods, and Beverages.
- **Urgency Filtering**: Urgent ($< 6\text{h}$), Expiring Today ($< 24\text{h}$), and Fresh ($> 24\text{h}$).
- **Status Filter**: Toggle between Active listings, In Progress, and Completed history.

### 5. Instant Zero-Config Demo Mode
- Runs out of the box with zero third-party account requirements.
- Pre-seeded local memory database with realistic donations and test scenarios.
- One-tap quick-fill buttons for instant role switching on the login screen.

---

## Visual Showcase & Screenshots

| Home Dashboard & Impact | Donation Details & Timeline | Food Discovery & Search |
| :---: | :---: | :---: |
| ![Dashboard](screenshots/Screenshot%202026-05-07%20095600.png) | ![Timeline](screenshots/Screenshot%202026-05-07%20100751.png) | ![Discovery](screenshots/Screenshot%202026-05-08%20113034.png) |

| Add Donation Flow | Role Management | User Profile |
| :---: | :---: | :---: |
| ![Add Donation](screenshots/Screenshot%202026-05-08%20115334.png) | ![Admin Panel](screenshots/Screenshot%202026-05-08%20120844.png) | ![Profile](screenshots/Screenshot%202026-05-11%20123316.png) |

---

## Architecture & Directory Structure

```text
lib/
├── core/
│   ├── config/          # App constants, routes, categories, and Firebase options
│   ├── errors/          # App exceptions and error handlers
│   ├── providers/       # Riverpod state providers and service injections
│   ├── routing/         # MaterialPageRoute generation
│   ├── services/        # Firebase bootstrap and fallback manager
│   ├── theme/           # SharePlate design system (colors, typography, cards)
│   ├── utils/           # Date formatters, validators, and Firebase converters
│   └── widgets/         # Reusable widgets (UrgencyBadge, Timeline, ImpactCard)
├── features/
│   ├── admin/           # Platform oversight, charity metrics, donor statistics
│   ├── auth/            # Login, registration, and quick demo account selector
│   ├── chatbot/         # Rule-based food rescue assistant & FAQ bot
│   ├── donations/       # Add donation, 5-stage lifecycle detail, filterable list
│   ├── home/            # Main dashboard, impact metrics, urgency alert banner
│   ├── maps/            # Location coordinate viewer and city mapping
│   ├── notifications/   # Real-time event notifications
│   └── profile/         # User profile, personal impact history, settings
├── models/              # Immutable data models (Donation, AppUser, Notification)
└── services/            # In-memory demo services and Firebase service bridges
test/
├── services_test.dart   # Unit tests for matching engine, impact metrics, lifecycle
└── widget_test.dart     # Widget smoke tests and SharePlate branding verification
```

---

## Deterministic Matching Algorithm

The matching engine in `lib/services/matching_service.dart` prioritizes food rescue through transparent, deterministic weighting:

$$\text{Match Score} = (0.60 \times \text{Urgency Score}) + (0.40 \times \text{Quantity Score})$$

- **Urgency Score (60% weight)**: Prioritizes batches nearest to expiration ($< 6\text{h} \to 100\text{ pts}$, $< 24\text{h} \to 75\text{ pts}$, $< 48\text{h} \to 50\text{ pts}$, etc.).
- **Quantity Score (40% weight)**: Prioritizes larger distributions to optimize logistics and vehicle transport.
- **Safety Exclusion**: Expired food is strictly excluded ($\text{Score} = 0$).

---

## Getting Started & Local Setup

### Prerequisites

- **Flutter SDK**: 3.35.0 or later
- **Dart SDK**: 3.9.0 or later
- **Android Studio** / VS Code with Flutter extension
- **JDK**: Version 17+

### Run Locally in Demo Mode (No Configuration Required)

SharePlate detects missing Firebase keys and automatically initializes in **In-Memory Demo Mode**:

```bash
# Clone the repository
git clone https://github.com/mrityunjay5004/SharePlate.git
cd SharePlate

# Install dependencies
flutter pub get

# Run code analysis
flutter analyze

# Execute test suite
flutter test

# Run application on connected Android device/emulator
flutter run
```

---

## Pre-Configured Demo Accounts

Use these one-tap credentials on the login screen to explore different user roles:

| Role | Email | Password | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Food Donor** | `donor@shareplate.test` | `password123` | Create listings, track pickups, view environmental metrics |
| **Charity Partner** | `charity@shareplate.test` | `password123` | Browse donations, claim food, confirm physical handoffs |
| **Administrator** | `admin@shareplate.test` | `password123` | Platform oversight, user directory, system metrics |

---

## Firebase & Maps Configuration

### Optional: Google Maps API Key
To enable interactive Google Maps rendering on Android:
1. Generate an API Key in the [Google Cloud Console](https://console.cloud.google.com/google/maps-apis).
2. Open `android/app/src/main/AndroidManifest.xml`.
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your valid key.

### Optional: Cloud Firebase Integration
To connect to your own Firebase project:
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Register an Android application with package name `com.zerowastefood.zero_waste_food`.
3. Enable **Authentication** (Email/Password) and **Cloud Firestore**.
4. Copy `android/app/google-services.json.example` to `android/app/google-services.json` and insert your credentials.
5. Provide your configuration keys in `lib/core/config/firebase_options.dart`.

---

## Data Model & Firestore Schema

```text
users/{userId}
  ├── id: String
  ├── name: String
  ├── email: String
  ├── role: "donor" | "charity" | "admin"
  ├── city: String
  ├── phone: String
  └── createdAt: Timestamp

donations/{donationId}
  ├── id: String
  ├── donorId: String
  ├── donorName: String
  ├── title: String
  ├── description: String
  ├── category: "Cooked Meals" | "Bakery" | "Produce" | "Dairy" | "Pantry" | "Beverages"
  ├── quantity: double
  ├── unit: "kg" | "meals" | "boxes" | "items"
  ├── expiryDate: Timestamp
  ├── status: "pending" | "requested" | "accepted" | "pickedUp" | "completed" | "rejected"
  ├── pickupAddress: String
  ├── city: String
  ├── acceptedByCharityId: String?
  ├── acceptedByCharityName: String?
  └── createdAt: Timestamp
```

---

## Attribution & Licensing Notice

### Maintainer & Modifications
- **Project Maintainer**: [Mrityunjay Tiwari](https://github.com/mrityunjay5004) (`mrityunjay5004`)
- **Customizations**: All SharePlate branding, green/cream design system, environmental impact calculation models, 5-stage donation lifecycle, and UI redesigns were developed by Mrityunjay Tiwari.

### Upstream Architecture Attribution
- SharePlate is an enhanced evolution built upon open-source architectural patterns from the `zero-waste-food` graduation project created by [Saied Alsify](https://github.com/saiedalsify-dev).
- **Licensing Status**: The original upstream repository was shared publicly without an explicit license file. In accordance with copyright standards and open-source ethics, original authorship is credited here and in the project commit records.
