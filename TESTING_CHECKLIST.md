# FoodBridge AI - Testing Checklist

## 1. Authentication & Security
- [ ] Register as a Donor (Verify successful redirect & welcome notification)
- [ ] Register as an NGO (Verify pending status & file upload simulation)
- [ ] Admin Login (admin@foodrescue.com / adminpassword123)
- [ ] Forgot Password flow (OTP delivery via Console/Email)
- [ ] JWT Token Expiry (Wait for token to expire or mock 401 and verify silent refresh)
- [ ] Biometric Login toggle and functionality

## 2. Donor Flow
- [ ] Add new food donation (Multiple items)
- [ ] Quality checklist validation
- [ ] GPS Location capture (Manual and Auto)
- [ ] View donation status on dashboard
- [ ] View/Show QR Code for pickup

## 3. NGO Flow
- [ ] View available donations list
- [ ] Accept a donation
- [ ] Real-time updates (Socket.IO events)
- [ ] Delivery tracking (Start journey -> Arrived)
- [ ] QR Code Scanner (Verify pickup with Donor's QR)
- [ ] Delivery Confirmation (Upload proof photo & members served)

## 4. Admin Flow
- [ ] Dashboard Statistics (Check if charts update)
- [ ] NGO Verification (Approve/Reject pending NGOs)
- [ ] System-wide Donation audit
- [ ] Export PDF Report (Check generated file in device storage)

## 5. Communications
- [ ] Real-time Chat (Sender/Receiver typing indicator & messages)
- [ ] In-App Notifications (Badge count & list)
- [ ] Local Notifications (Foreground alerts)
- [ ] SMS Alerts (Verify console logs or real SMS if API key set)

## 6. Logistics
- [ ] Route Optimization (Check if stops are sorted by distance/urgency)
- [ ] OpenStreetMap markers and live tracking

## 7. Edge Cases
- [ ] No internet connection (Check error states)
- [ ] Denied camera/location permissions
- [ ] Multiple concurrent NGO acceptances (Verify race condition handling)
- [ ] Empty search results or lists
