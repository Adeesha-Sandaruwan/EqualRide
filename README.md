<div align="center">

# 🚌 EqualRide

### Inclusive Public Transport Companion

*Safer, more accessible public-transport journeys for elderly and disabled passengers.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Material Design](https://img.shields.io/badge/Material%20Design-757575?style=for-the-badge&logo=materialdesign&logoColor=white)

</div>

---

## 📖 Overview

**EqualRide** is a Flutter application designed to help elderly and disabled passengers plan safer, more accessible public-transport journeys.

The system supports personalised accessibility preferences, route recommendations, route comparison, saved locations, community accessibility reports, and inclusive display settings.

---

## 📑 Table of Contents

- [Key Features](#-key-features)
- [Technologies Used](#-technologies-used)
- [Project Structure](#-project-structure)
- [Firebase Usage](#-firebase-usage)
- [Getting Started](#-getting-started)
- [Important Note About Route Data](#%EF%B8%8F-important-note-about-route-data)
- [Accessibility Focus](#-accessibility-focus)
- [Future Improvements](#-future-improvements)
- [Academic Project](#-academic-project)

---

## ✨ Key Features

### 👤 User Management

- Register with email and password
- Log in and log out securely
- Persistent Firebase authentication session
- Firebase error messages for common login and registration issues

### ♿ Accessibility Preferences

- Step-free route preference
- Low-crowding preference
- Priority-seat information preference
- Accessibility-alert preference
- Preferences stored in **Cloud Firestore**

### 🎨 Display Accessibility

- High-contrast mode
- Standard, Large, and Extra Large text sizes
- English and Sinhala language preference
- Settings restored after the user logs in

### 🗺️ Route Planning

- Search routes using origin and destination
- Demo route catalogue
- Sort routes by:
  - **Fastest**
  - **Most accessible**
  - **Fewest transfers**
- Personalised route recommendations based on saved preferences
- Route match score and explanation
- Compare two routes by accessibility score, time, transfers, crowding, seating, and step-free access
- View route accessibility details and journey steps

### 📍 Saved Locations

- Save frequent destinations such as Home, Work, Hospital, or University
- View, edit, and delete saved locations
- Use a saved location as a route-search destination
- Saved locations stored in **Cloud Firestore**

### 💬 Community Accessibility Reports

- Submit accessibility issues
- View and filter community reports
- View report status
- Community reports stored in **Cloud Firestore**

---

## 🛠️ Technologies Used

| Technology              | Purpose                                   |
| ----------------------- | ----------------------------------------- |
| **Flutter**             | Cross-platform application framework      |
| **Dart**                | Programming language                      |
| **Firebase Auth**       | User registration, login, and sessions    |
| **Cloud Firestore**     | Preferences, locations, and reports       |
| **Material Design**     | User-interface design system              |

---

## 🗂️ Project Structure

```text
lib/
├── data/            Demo transport-route and route-detail data
├── localization/    English and Sinhala application strings
├── models/          Application data models
├── screens/         Application user-interface screens
├── services/        Firebase and application services
├── theme/           Colours, typography, and application theme
├── utils/           Validation and helper utilities
├── widgets/         Reusable user-interface components
└── main.dart        Application entry point
```

---

## 🔥 Firebase Usage

Firebase is used for:

- User authentication
- User accessibility preferences
- Display and language settings
- Saved locations
- Accessibility issue reports
- Community report information

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- VS Code or Android Studio
- Firebase project configuration

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

### Check Code Quality

```bash
flutter analyze
```

---

## ⚠️ Important Note About Route Data

> The route-search feature currently uses **clearly labelled demo data**.

The demo data is used to demonstrate:

- Route searching
- Accessibility-based route sorting
- Personalised recommendations
- Route comparison
- Route details

The current version does **not** use:

- A real-time public-transport API
- Live bus tracking
- Verified arrival times
- Device GPS location

---

## 🌍 Accessibility Focus

EqualRide supports inclusive travel planning through:

- Step-free route preferences
- Wheelchair-accessibility information
- Ramp and lift information
- Crowd-level information
- Priority-seat information
- High-contrast display mode
- Large-text support
- English and Sinhala language options
- Community-reported accessibility issues

---

## 🔮 Future Improvements

- [ ] Connect to verified public-transport and route APIs
- [ ] Add live bus and train tracking
- [ ] Add real GPS location support
- [ ] Add live accessibility alerts and notifications
- [ ] Expand complete route-detail coverage
- [ ] Complete Sinhala translations across every screen
- [ ] Conduct further usability testing with elderly and disabled users

---

## 🎓 Academic Project

EqualRide was developed as an **academic group project** focused on reducing accessibility barriers in public transportation for elderly and disabled passengers.