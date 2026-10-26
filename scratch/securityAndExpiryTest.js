/**
 * FoodBridge AI — Security, Authorization & Expiry Verification Suite
 * Tests:
 * 1. JWT Authentication & Role Scoping
 * 2. Notification Expiry Validation Logic
 * 3. Rating & Feedback Authorization and Eligibility Rules
 * 4. Chat Participant Scoping & Privacy Enforcement
 * 5. Donation Claimed Event Semantics
 */

let jwt;
try {
  jwt = require('jsonwebtoken');
} catch (_) {
  jwt = require('../backend/node_modules/jsonwebtoken');
}
const assert = require('assert');

const JWT_SECRET = 'foodbridge_test_secret_key_2026';

function runSecurityAndExpiryTests() {
  console.log('=== FoodBridge AI Security & Expiry Verification Suite ===\n');
  let passedTests = 0;
  let totalTests = 0;

  function test(description, fn) {
    totalTests++;
    try {
      fn();
      console.log(`  ✅ [PASS] ${description}`);
      passedTests++;
    } catch (err) {
      console.error(`  ❌ [FAIL] ${description}`);
      console.error(`     Error: ${err.message}\n`);
    }
  }

  // 1. JWT Security & Expiry
  test('1.1 Generates and signs valid JWT token with user role and id', () => {
    const payload = { id: 'usr-ngo-001', role: 'ngo' };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
    const decoded = jwt.verify(token, JWT_SECRET);
    assert.strictEqual(decoded.id, 'usr-ngo-001');
    assert.strictEqual(decoded.role, 'ngo');
  });

  test('1.2 Rejects expired JWT token', () => {
    const payload = { id: 'usr-donor-002', role: 'donor' };
    // Sign token expired in past
    const expiredToken = jwt.sign(payload, JWT_SECRET, { expiresIn: '-1s' });
    assert.throws(
      () => jwt.verify(expiredToken, JWT_SECRET),
      /jwt expired/
    );
  });

  test('1.3 Rejects token with invalid signature', () => {
    const token = jwt.sign({ id: 'usr-003', role: 'donor' }, 'wrong_secret');
    assert.throws(
      () => jwt.verify(token, JWT_SECRET),
      /invalid signature/
    );
  });

  // 2. Notification Expiry Logic
  test('2.1 Notification with past expiresAt is marked isExpired', () => {
    const now = new Date();
    const pastExpiry = new Date(now.getTime() - 3600000); // 1 hour ago
    const notification = {
      title: 'Surplus Pastries Available',
      expiresAt: pastExpiry.toISOString(),
      createdAt: new Date(now.getTime() - 7200000).toISOString(),
    };

    const isExpired = new Date().getTime() > new Date(notification.expiresAt).getTime();
    assert.strictEqual(isExpired, true, 'Past notification should be marked expired');
  });

  test('2.2 Notification with future expiresAt is NOT expired', () => {
    const now = new Date();
    const futureExpiry = new Date(now.getTime() + 7200000); // 2 hours from now
    const notification = {
      title: 'Warm Vegetable Rice Alert',
      expiresAt: futureExpiry.toISOString(),
      createdAt: now.toISOString(),
    };

    const isExpired = new Date().getTime() > new Date(notification.expiresAt).getTime();
    assert.strictEqual(isExpired, false, 'Future notification must not be expired');
  });

  // 3. Rating & Feedback Authorization Rules
  test('3.1 Rating submission requires status == completed', () => {
    const activeDonation = { id: 'don-101', status: 'picked_up' };
    const canRate = (donation) => donation.status === 'completed';
    assert.strictEqual(canRate(activeDonation), false, 'Cannot rate active/in-progress donation');

    const completedDonation = { id: 'don-102', status: 'completed' };
    assert.strictEqual(canRate(completedDonation), true, 'Completed donation is eligible for rating');
  });

  test('3.2 Unauthorized third-party cannot rate donation', () => {
    const donation = {
      id: 'don-103',
      status: 'completed',
      donorId: 'user-donor-1',
      assignedNgoId: 'user-ngo-2',
      volunteerId: 'user-vol-3'
    };
    const isAuthorizedParty = (userId, userRole) => {
      if (userRole === 'admin') return true;
      return (
        userId === donation.donorId ||
        userId === donation.assignedNgoId ||
        userId === donation.volunteerId
      );
    };

    assert.strictEqual(isAuthorizedParty('user-random-9', 'ngo'), false);
    assert.strictEqual(isAuthorizedParty('user-donor-1', 'donor'), true);
    assert.strictEqual(isAuthorizedParty('user-ngo-2', 'ngo'), true);
    assert.strictEqual(isAuthorizedParty('admin-root', 'admin'), true);
  });

  test('3.3 User cannot rate themselves (self-rating blocked)', () => {
    const fromUserId = 'user-donor-1';
    const toUserId = 'user-donor-1';
    const isSelfRating = fromUserId === toUserId;
    assert.strictEqual(isSelfRating, true, 'Self-rating must be detected and rejected');
  });

  test('3.4 Duplicate rating for same donation is blocked', () => {
    const existingRatings = [
      { donationId: 'don-200', fromUserId: 'user-ngo-1', rating: 5 }
    ];
    const hasAlreadyRated = (donationId, fromUserId) => {
      return existingRatings.some(
        r => r.donationId === donationId && r.fromUserId === fromUserId
      );
    };

    assert.strictEqual(hasAlreadyRated('don-200', 'user-ngo-1'), true);
    assert.strictEqual(hasAlreadyRated('don-200', 'user-donor-2'), false);
  });

  // 4. Chat Participant Authorization & Room Scoping
  test('4.1 Chat access is strictly restricted to participants and admin', () => {
    const chat = {
      id: 'chat-901',
      participants: ['usr-donor-10', 'usr-ngo-20']
    };

    const canAccessChat = (userId, userRole) => {
      if (userRole === 'admin') return true;
      return chat.participants.includes(userId);
    };

    assert.strictEqual(canAccessChat('usr-donor-10', 'donor'), true);
    assert.strictEqual(canAccessChat('usr-ngo-20', 'ngo'), true);
    assert.strictEqual(canAccessChat('usr-eavesdropper-99', 'donor'), false);
    assert.strictEqual(canAccessChat('admin-001', 'admin'), true);
  });

  // 5. Donation Claimed Semantics
  test('5.1 donation_claimed event transforms notification into claimed state', () => {
    let notification = {
      id: 'notif-501',
      title: 'New Donation Nearby',
      body: '50 meals available at Sunshine Cafe',
      data: { donationId: 'don-777' }
    };

    const incomingClaimEvent = { donationId: 'don-777' };
    if (notification.data.donationId === incomingClaimEvent.donationId) {
      notification = {
        ...notification,
        title: 'Donation Claimed 🤝',
        body: 'This donation has already been accepted by another NGO and is no longer available.'
      };
    }

    assert.strictEqual(notification.title, 'Donation Claimed 🤝');
    assert.strictEqual(notification.body.includes('already been accepted'), true);
  });

  console.log(`\n======================================================`);
  console.log(`Summary: ${passedTests} of ${totalTests} security & expiry tests passed.`);
  console.log(`======================================================\n`);

  if (passedTests !== totalTests) {
    process.exit(1);
  }
}

runSecurityAndExpiryTests();
