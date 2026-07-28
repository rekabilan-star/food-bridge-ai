# 🚀 Production Deployment Guide

This guide covers the end-to-end deployment of the **FoodRescue AI** platform.

---

## 1. Backend Deployment (Node.js)

### Recommended Platform: [Render](https://render.com/) or [Railway](https://railway.app/)
1.  **Connect GitHub:** Link your repository to the platform.
2.  **Root Directory:** `backend`
3.  **Build Command:** `npm install`
4.  **Start Command:** `node server.js`
5.  **Environment Variables:** Add the following in the platform dashboard:
    - `MONGODB_URI`: Your MongoDB Atlas connection string.
    - `JWT_SECRET`: A long, random string.
    - `JWT_EXPIRE`: `30d`
    - `NODE_ENV`: `production`
    - `PORT`: `10000` (or as provided by the host)

### Security Checklist:
- [ ] Ensure `0.0.0.0` binding is used in `server.js` (Already implemented).
- [ ] Verify CORS settings allow your mobile traffic (Wildcard enabled).

---

## 2. Database (MongoDB Atlas)

1.  **Network Access:** In Atlas dashboard, go to **Network Access** and click **Add IP Address**. Choose **Allow Access from Anywhere** (`0.0.0.0/0`) for cloud deployment.
2.  **Database User:** Create a user with `readWriteAnyDatabase` privileges.
3.  **Connection String:** Use the connection string in your backend `.env`.

---

## 3. Flutter Release Build (Android)

### Step 1: Update App Constants
In `lib/core/constants/app_constants.dart`:
- Change `baseUrl` to your deployed backend URL (e.g., `https://your-app.onrender.com/api/`).

### Step 2: Android Signing (Essential)
1.  Generate a keystore:
    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
2.  Create `android/key.properties` with the path and passwords.
3.  Update `android/app/build.gradle.kts` to use these keys (currently set to debug for convenience).

### Step 3: Build APK
Run the following command:
```bash
flutter build apk --release
```
The output will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 4. Third-Party Integrations

### Firebase (Notifications)
1.  Create a project in [Firebase Console](https://console.firebase.google.com/).
2.  Add an Android app with package name `com.example.mca_app`.
3.  Download `google-services.json` and place it in `android/app/`.
4.  Replace `fcmService.js` placeholder with `firebase-admin` SDK logic if push notifications are required on physical devices.

---

## ✅ Final Production Checklist

- [ ] Backend URL uses `https`.
- [ ] Localhost/10.0.2.2 removed from all code.
- [ ] ProGuard/R8 enabled (Already implemented in `build.gradle.kts`).
- [ ] Unused debug prints removed.
- [ ] Database backups scheduled in MongoDB Atlas.
- [ ] App version updated in `pubspec.yaml`.
