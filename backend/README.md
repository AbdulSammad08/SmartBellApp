# Smart Doorbell Backend API

Complete backend system for Smart Doorbell FYP project with Azure Cosmos DB integration.

## Features

- User registration with email verification
- OTP-based email verification (5-minute expiry)
- Secure login with JWT tokens
- Password and OTP hashing with bcrypt
- Rate limiting for security
- Azure Cosmos DB (MongoDB API) integration
- SendGrid email service integration

## API Endpoints

### Authentication Routes

#### POST /api/register
Register a new user and send OTP verification email.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent to your email"
}
```

#### POST /api/verify-otp
Verify OTP and activate user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account verified successfully",
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### POST /api/login
Login with verified credentials.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### POST /api/resend-otp
Resend OTP verification email (rate limited).

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

## Setup Instructions

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Configuration
Copy `.env.example` to `.env` and configure:

```env
COSMOS_DB_URI=mongodb://your-cosmos-account:your-key@your-cosmos-account.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@your-cosmos-account@
JWT_SECRET=your-super-secret-jwt-key-here
SENDGRID_API_KEY=SG.your-sendgrid-api-key-here
FROM_EMAIL=noreply@smartdoorbell.com
PORT=3000
```

### 3. Run the Server
```bash
# Development
npm run dev

# Production
npm start
```

### 4. Run Tests
```bash
npm test
```

## Azure Configuration Guide

### Azure Cosmos DB Setup

1. **Create Cosmos DB Account**
   - Go to Azure Portal → Create Resource → Azure Cosmos DB
   - Choose "Azure Cosmos DB for MongoDB"
   - Select your subscription and resource group
   - Choose account name (e.g., `smartdoorbell-db`)
   - Select region closest to your users

2. **Get Connection String**
   - Go to your Cosmos DB account → Settings → Connection String
   - Copy the "Primary Connection String"
   - Replace `<password>` with your account key

3. **Create Database and Collection**
   - Database name: `smartdoorbell`
   - Collection name: `users`

### SendGrid Email Service Setup

1. **Create SendGrid Account**
   - Go to Azure Marketplace → Search "SendGrid"
   - Create SendGrid account (free tier available)
   - Complete email verification

2. **Get API Key**
   - Go to SendGrid Dashboard → Settings → API Keys
   - Create new API key with "Full Access"
   - Copy the API key for environment variables

3. **Verify Sender Email**
   - Go to Settings → Sender Authentication
   - Verify your sender email address

### Azure App Service Deployment

1. **Create App Service**
   - Go to Azure Portal → Create Resource → Web App
   - Choose Node.js runtime stack
   - Select your subscription and resource group

2. **Configure Environment Variables**
   - Go to App Service → Settings → Configuration
   - Add all environment variables from `.env` file

3. **Deploy Code**
   ```bash
   # Using Azure CLI
   az webapp up --name your-app-name --resource-group your-rg
   ```

## Flutter Integration Examples

### Registration API Call
```dart
Future<Map<String, dynamic>> registerUser({
  required String email,
  required String password,
  required String name,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'name': name,
    }),
  );
  
  return jsonDecode(response.body);
}
```

### OTP Verification API Call
```dart
Future<Map<String, dynamic>> verifyOTP({
  required String email,
  required String otp,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'otp': otp,
    }),
  );
  
  return jsonDecode(response.body);
}
```

### Login API Call
```dart
Future<Map<String, dynamic>> loginUser({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );
  
  return jsonDecode(response.body);
}
```

## Security Features

- **Password Hashing**: bcrypt with salt rounds
- **OTP Hashing**: bcrypt for secure OTP storage
- **Rate Limiting**: 3 OTP requests per hour per email
- **JWT Tokens**: Secure authentication tokens
- **Input Validation**: Joi schema validation
- **CORS Protection**: Configured for production domains
- **Helmet Security**: Security headers middleware

## Database Schema

```javascript
{
  "_id": "ObjectId",
  "email": "user@example.com",
  "passwordHash": "bcrypt_hash",
  "name": "John Doe",
  "isVerified": false,
  "otpHash": "bcrypt_hash",
  "otpExpires": "2025-01-15T10:45:00Z",
  "otpAttempts": 1,
  "lastOtpRequest": "2025-01-15T10:40:00Z",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:40:00Z"
}
```

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description"
}
```

Common HTTP status codes:
- `200`: Success
- `202`: Accepted (OTP sent)
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (invalid credentials)
- `404`: Not Found (user not found)
- `429`: Too Many Requests (rate limited)
- `500`: Internal Server Error