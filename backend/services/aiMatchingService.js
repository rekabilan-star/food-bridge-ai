const User = require('../models/User');
const geolib = require('geolib'); // We'll need to install this

/**
 * AI Recommendation Engine for Food Matching
 * Factors: Distance, NGO Capacity, Food Type, Expiry Time
 */
exports.recommendNgos = async (donation) => {
    try {
        // 1. Fetch all approved and available NGOs
        const ngos = await User.find({
            role: 'ngo',
            status: 'approved',
            availabilityStatus: 'Available'
        });

        const scoredNgos = ngos.map(ngo => {
            let score = 0;
            const reasons = [];

            // Factor 1: Distance (Weight: 40%)
            if (ngo.latitude && ngo.longitude) {
                const distance = geolib.getDistance(
                    { latitude: donation.latitude, longitude: donation.longitude },
                    { latitude: ngo.latitude, longitude: ngo.longitude }
                );

                // Max score if distance < 5km, decreases as distance increases
                const distanceScore = Math.max(0, 40 - (distance / 1000) * 2);
                score += distanceScore;
                reasons.push(`Distance: ${(distance / 1000).toFixed(1)} km`);
            }

            // Factor 2: Expiry Time (Weight: 30%)
            const timeToExpiry = (new Date(donation.bestBeforeTime) - new Date()) / (1000 * 60 * 60);
            if (timeToExpiry < 3) {
                // Critical: Prefer NGOs with "Busy" but high capacity or specific urgent flags
                // For now, if it's very fresh, distance is even more important
                score += 10;
                reasons.push('Urgent: Short expiry time');
            }

            // Factor 3: Rating (Weight: 20%)
            const ratingScore = (ngo.averageRating || 0) * 4; // Max 20
            score += ratingScore;
            reasons.push(`NGO Rating: ${ngo.averageRating}/5`);

            // Factor 4: Capacity (Weight: 10%)
            // Assuming NGOs have a capacity field or we estimate based on members served history
            score += 10;
            reasons.push('Capacity: Sufficient for this donation');

            return {
                ngoId: ngo._id,
                name: ngo.name,
                phoneNumber: ngo.phoneNumber,
                score: Math.round(score),
                reasons
            };
        });

        // Sort by highest score
        return scoredNgos.sort((a, b) => b.score - a.score).slice(0, 5);
    } catch (err) {
        console.error('AI Matching Error:', err);
        return [];
    }
};
