# Smart Doorbell App

A Flutter mobile application with Node.js backend for smart doorbell functionality.

## Features
- User authentication with OTP verification
- Real-time video streaming from ESP32-CAM
- Motion detection and visitor alerts
- Bluetooth WiFi configuration for ESP32
- Subscription management
- Visitor profile management

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Node.js, Express.js
- **Database**: Azure Cosmos DB (MongoDB API)
- **Hardware**: ESP32-CAM
- **Authentication**: JWT tokens
- **Email**: Gmail SMTP

## Deployment
- Backend deployed on Railway
- Frontend: Flutter mobile app

## Environment Variables
```
COSMOS_DB_URI=your_cosmos_db_connection_string
JWT_SECRET=your_jwt_secret
GMAIL_USER=your_gmail_address
GMAIL_APP_PASSWORD=your_gmail_app_password
PORT=8080
```

## Installation
1. Clone repository
2. Install Flutter dependencies: `flutter pub get`
3. Install backend dependencies: `cd backend && npm install`
4. Configure environment variables
5. Run backend: `npm start`
6. Run Flutter app: `flutter run`