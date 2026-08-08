const User = require('../models/User');

/**
 * Find nearby NGOs using MongoDB Geospatial queries
 */
exports.getNearbyNgos = async (latitude, longitude, maxDistanceKm = 15) => {
    try {
        if (!latitude || !longitude) return [];

        return await User.aggregate([
            {
                $geoNear: {
                    near: {
                        type: "Point",
                        coordinates: [parseFloat(longitude), parseFloat(latitude)]
                    },
                    distanceField: "distance",
                    maxDistance: maxDistanceKm * 1000,
                    query: {
                        role: 'ngo',
                        status: 'approved',
                        availabilityStatus: { $in: ['Available', 'Busy'] }
                    },
                    spherical: true
                }
            },
            {
                $project: {
                    _id: 1,
                    name: 1,
                    phoneNumber: 1,
                    address: 1,
                    distance: 1,
                    averageRating: 1,
                    availabilityStatus: 1,
                    profileImage: 1
                }
            },
            { $limit: 15 }
        ]);
    } catch (err) {
        console.error('Nearby NGO Search Error:', err);
        return [];
    }
};

/**
 * AI Recommendation Engine for Food Matching
 * Logic: Distance (35%), ETA (15%), Urgency (25%), Availability (15%), Rating (10%)
 */
exports.recommendNgos = async (donation) => {
    try {
        const nearbyNgos = await this.getNearbyNgos(donation.latitude, donation.longitude);
        const now = new Date();
        const bestBefore = new Date(donation.bestBeforeTime);
        const prepared = new Date(donation.preparedTime);

        // Calculate Global Donation Factors
        const hoursTotal = (bestBefore - prepared) / (1000 * 60 * 60);
        const hoursLeft = (bestBefore - now) / (1000 * 60 * 60);
        const freshnessPercentage = Math.max(0, Math.min(100, (hoursLeft / hoursTotal) * 100));
        const isUrgent = hoursLeft < 3;

        const scoredNgos = nearbyNgos.map(ngo => {
            let score = 0;
            const explanations = [];
            const metrics = {
                distance: (ngo.distance / 1000).toFixed(1),
                eta: Math.round((ngo.distance / 1000) * 4 + 5),
            };

            // 1. Distance Score (Max 30) - Heavy optimization for proximity
            const distKm = ngo.distance / 1000;
            const distScore = Math.max(0, 30 - (distKm * 2));
            score += distScore;

            // 2. ETA & Freshness Sync (Max 30) - The "Intelligence" core
            // We reward fast NGOs more when the food is less fresh
            let freshnessImpact = 0;
            if (freshnessPercentage < 25) { // Critical
                freshnessImpact = metrics.eta < 15 ? 30 : (metrics.eta < 30 ? 20 : 5);
                if (metrics.eta < 15) explanations.push("CRITICAL: Immediate rescue recommended due to extremely low shelf life.");
            } else if (freshnessPercentage < 50) { // High
                freshnessImpact = metrics.eta < 25 ? 25 : 15;
                explanations.push(`Urgent: Food is at ${Math.round(freshnessPercentage)}% freshness. Partner can arrive within ${metrics.eta} mins.`);
            } else { // Moderate
                freshnessImpact = 15;
                explanations.push(`Optimal: Food is fresh (${Math.round(freshnessPercentage)}%).`);
            }
            score += freshnessImpact;

            // 3. NGO Availability (Max 20)
            if (ngo.availabilityStatus === 'Available') {
                score += 20;
                explanations.push("Partner is standby and ready for instant dispatch.");
            } else {
                score += 10;
                explanations.push("Partner is currently active on another route but can redirect if needed.");
            }

            // 4. Rating & Reliability (Max 20)
            const reliabilityScore = (ngo.averageRating || 3) * 4; // Default to 3 star if new
            score += reliabilityScore;
            if (ngo.averageRating >= 4.0) explanations.push(`Verified partner with a high reliability rating of ${ngo.averageRating}/5.`);

            // 5. Confidence Calculation
            // High confidence if we have multiple strong signals (Distance < 5km AND Rating > 4 AND Available)
            let confidence = 70; // Base confidence
            if (distKm < 5) confidence += 10;
            if (ngo.averageRating >= 4) confidence += 10;
            if (ngo.availabilityStatus === 'Available') confidence += 10;
            confidence = Math.min(99, confidence);

            const finalScore = Math.min(100, Math.round(score));

            return {
                ngoId: ngo._id,
                name: ngo.name,
                phoneNumber: ngo.phoneNumber,
                distanceKm: parseFloat(metrics.distance),
                etaMinutes: metrics.eta,
                etaText: metrics.eta > 60 ? `${Math.floor(metrics.eta/60)}h ${metrics.eta%60}m` : `${metrics.eta} mins`,
                score: finalScore,
                confidence: confidence,
                availability: ngo.availabilityStatus,
                reasons: explanations,
                explanation: explanations.join(' ')
            };
        });

        // Sort by highest score and filter out very low matches
        return scoredNgos
            .sort((a, b) => b.score - a.score)
            .filter(n => n.score > 30)
            .slice(0, 5);
    } catch (err) {
        console.error('AI Matching Error:', err);
        return [];
    }
};
