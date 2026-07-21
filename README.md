# live_auction

# 🏆 Live Auction App

A real-time auction application built with **Flutter**, **Riverpod**, and **Firebase**. The application allows users to participate in live auctions, place bids in real time, view bid history, and receive auction updates through Firebase Cloud Messaging.

This project was developed as part of a Flutter Machine Test while following **Clean Architecture**, **Repository Pattern**, and **Riverpod State Management**.

---

# ✨ Features

## Authentication
- Sign Up with Email & Password
- Secure Login
- Logout
- Session Persistence

## Auction
- View Active Auctions
- Auction Details
- Multiple Product Images
- Live Highest Bid
- Real-Time Countdown Timer
- Place Bid
- Bid Validation
- Bid History
- Automatic Winner Selection

## Notifications
- Firebase Cloud Messaging (FCM)
- Auction Started
- Outbid Notification
- Winner Notification
- Auction End Notification

## Performance
- Firestore Real-Time Listeners
- Firestore Transactions
- Offline Support
- Optimized Firestore Reads
- Cached Images

---

# 🛠 Tech Stack

- Flutter (Latest Stable)
- Dart
- Riverpod
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage
- Clean Architecture
- Repository Pattern
- Cached Network Image

---

# 📁 Project Structure

```
lib
│
├── core
│   ├── constants
│   ├── theme
│   └── utils
│
├── features
│   ├── auth
│   │   ├── data
│   │   │   ├── datasources
│   │   │   ├── models
│   │   │   └── repositories
│   │   ├── domain
│   │   │   └── repositories
│   │   └── presentation
│   │       ├── providers
│   │       └── screens
│   │
│   ├── auction
│   │   ├── data
│   │   └── presentation
│   │
│   └── notification
│       ├── data
│       └── presentation
│
├── shared
│   └── widgets
│
└── main.dart
```

---

# 🔥 Firebase Services

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage

---

# 📂 Firestore Database Structure

```
users/

products/

products/{productId}/bids/

notifications/

winners/
```

---

# 📦 State Management

This application uses **Riverpod** for state management.

### Providers

- Auth Provider
- Auction Provider
- Bid Provider
- Notification Provider
- Countdown Timer Provider

---

# 🔄 Auction Flow

```
User Login
      │
      ▼
Auction List
      │
      ▼
Auction Details
      │
      ▼
Real-Time Firestore Listener
      │
      ▼
Place Bid
      │
      ▼
Firestore Transaction
      │
      ▼
Highest Bid Updated
      │
      ▼
Bid History Updated
      │
      ▼
Winner Selected
      │
      ▼
Push Notification Sent
```

---

# 🔒 Firestore Transaction

Each bid is placed using a Firestore Transaction to prevent race conditions.

### Transaction Steps

1. Read current highest bid.
2. Validate bid amount.
3. Update highest bid.
4. Update highest bidder.
5. Increase total bid count.
6. Store bid history.
7. Commit transaction.

Only the highest valid bid is accepted.

---

# 🚀 Getting Started

## Clone Repository

```bash
git clone [https://github.com/prateeksanodiya0209/live_auction]
```

## Install Dependencies

```bash
flutter pub get
```

## Run Project

```bash
flutter run
```

---

# 📦 Main Packages

```yaml
flutter_riverpod:
firebase_core:
firebase_auth:
cloud_firestore:
firebase_storage:
firebase_messaging:
cached_network_image:
intl:
flutter_svg:
```

---

# 📱 Application Screens

- Splash Screen
- Login
- Register
- Home
- Auction Details
- Bid History
- Notifications
- Profile

---

# ✅ Implemented Features

- Firebase Authentication
- Riverpod State Management
- Clean Architecture
- Repository Pattern
- Real-Time Firestore Updates
- Firestore Transactions
- Countdown Timer
- Bid History
- Winner Selection
- Push Notifications (FCM)
- Offline Firestore Support
- Responsive UI

---

# 📈 Future Improvements

- Payment Gateway Integration
- Auto Bidding
- Search & Filter
- Auction Categories
- Wishlist
- Admin Dashboard
- Dark Theme
- Multi-language Support

---

# 👨‍💻 Developer

**Prateek Sanodiya**

Flutter Developer

- Flutter
- Firebase
- Riverpod
- Clean Architecture

---

# 📄 License

This project is developed for educational and Flutter Machine Test purposes.
