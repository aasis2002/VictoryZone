# Victory Zone - Professional Esports Platform 🎮

Victory Zone is a high-performance, feature-rich Flutter application designed for managing and participating in competitive mobile gaming tournaments (PUBG Mobile, Free Fire, etc.). It features a secure financial system, real-time match management, and an automated esports workflow.

## 🚀 Key Features

### 🏆 Tournament Lifecycle
- **Dynamic Discovery**: Browse upcoming, live, and completed matches with real-time slot tracking.
- **Secure Room Intel**: Automated delivery of Room ID and Passwords exclusively to paid participants.
- **Auto-Tie Sheet Generator**: Professional matchmaking system that balances lobbies and automatically handles round-by-round advancements.
- **Real-time Leaderboards**: Automated point calculation based on kills and placement ranks.

### 💰 Financial & Wallet System
- **Valor Bank**: A robust in-app wallet for managing credits and debits.
- **Manual eSewa Integration**: Support for manual top-ups via screenshot verification and professional withdrawal processing.
- **Atomic Transactions**: Every rupee is tracked via Firestore transactions to ensure 100% data integrity.
- **Bulk Refunds**: One-tap refund system for match cancellations.

### 🛡️ Fair Play & Security
- **Anti-Cheat Dispute Center**: Integrated reporting system with image evidence upload.
- **Role-Based Access Control (RBAC)**: Secure Firestore rules that distinguish between "Elite Players" and "Command Center Admins."
- **Account Enforcement**: Capability for admins to warn, disqualify, or permanently ban users.

### 👑 Admin Command Center
- **Business Intelligence**: Real-time dashboard showing total users, revenue, and tournament metrics.
- **Global Broadcast**: Send push notifications to all players or specific match participants.

## 🛠️ Technical Stack
- **Frontend**: Flutter (Material 3)
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **State Management**: Provider
- **Font**: Rajdhani (Gaming Aesthetic)

## 📦 Installation
1. Clone the repo: `git clone https://github.com/your-username/victoryzone.git`
2. Add your `google-services.json` to `android/app/`.
3. Run `flutter pub get`.
4. Configure Firestore Rules using the included `firestore.rules` file.
