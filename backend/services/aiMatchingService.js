const User = require('../models/User');
const Donation = require('../models/Donation');

/**
 * Find nearby NGOs using MongoDB Geospatial queries
 * Enforces the strict 20 KM business rule.
 */
exports.getNearbyNgos = async (latitude, longitude, maxDistanceKm = 20) => {
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
                    totalRatings: 1,
                    availabilityStatus: 1,
                    profileImage: 1,
                    acceptedCategories: 1,
                    maxDailyMeals: 1
                }
            },
            { $limit: 20 }
        ]);
    } catch (err) {
        console.error('Nearby NGO Search Error:', err);
        return [];
    }
};

/**
 * Enhanced Smart NGO Matching Engine (Phase 2A Step 2)
 * Normalized Score: 0-100
 * Weights: Distance (30%), Freshness/ETA (25%), Availability (15%),
 *          Workload (15%), Rating (10%), Completion History (5%)
 */
exports.recommendNgos = async (donation) => {
    try {
        const nearbyNgos = await this.getNearbyNgos(donation.latitude, donation.longitude);
        if (nearbyNgos.length === 0) return [];

        const ngoIds = nearbyNgos.map(n => n._id);

        // Batch fetch workload and history for eligible NGOs to avoid N+1 queries
        const stats = await Donation.aggregate([
            { $match: { assignedNgoId: { $in: ngoIds } } },
            { $group: {
                _id: "$assignedNgoId",
                activeCount: {
                    $sum: { $cond: [{ $in: ["$status", ["accepted", "on_the_way", "arrived", "picked_up"]] }, 1, 0] }
                },
                completedCount: { $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] } },
                failedCount: { $sum: { $cond: [{ $in: ["$status", ["cancelled", "rejected"]] }, 1, 0] } }
            }}
        ]);

        const statsMap = new Map(stats.map(s => [s._id.toString(), s]));

        const now = new Date();
        const bestBefore = new Date(donation.bestBeforeTime);
        const prepared = new Date(donation.preparedTime);

        // Global Donation Factors
        const shelfLifeTotal = Math.max(1, (bestBefore - prepared) / (1000 * 60 * 60));
        const hoursRemaining = (bestBefore - now) / (1000 * 60 * 60);
        const freshnessPercent = Math.max(0, Math.min(100, (hoursRemaining / shelfLifeTotal) * 100));

        const scoredNgos = nearbyNgos.map(ngo => {
            let score = 0;
            const explanations = [];
            const ngoStats = statsMap.get(ngo._id.toString()) || { activeCount: 0, completedCount: 0, failedCount: 0 };

            const distKm = ngo.distance / 1000;
            const etaMins = Math.round(distKm * 4 + 5); // Rough heuristic: 4 mins/km + 5 mins prep

            // 1. Distance Score (30%)
            // Linear decay: 30 at 0km, 0 at 20km
            const distanceScore = Math.max(0, 30 * (1 - distKm / 20));
            score += distanceScore;

            // 2. Freshness vs ETA Score (25%)
            // Logic: High score if NGO can reach before 50% shelf life loss
            const travelHours = etaMins / 60;
            const bufferRatio = hoursRemaining > 0 ? (hoursRemaining - travelHours) / hoursRemaining : 0;
            let freshnessScore = 0;
            if (bufferRatio > 0.8) freshnessScore = 25;
            else if (bufferRatio > 0.5) freshnessScore = 18;
            else if (bufferRatio > 0) freshnessScore = 10;
            else freshnessScore = 0; // Likely to expire before arrival

            score += freshnessScore;
            if (freshnessPercent < 30 && bufferRatio > 0.5) {
                explanations.push("Rapid Response: Partner can reach before food quality degrades further.");
            }

            // 3. Availability Score (15%)
            let availabilityScore = 0;
            if (ngo.availabilityStatus === 'Available') {
                availabilityScore = 15;
                explanations.push("Ready Now: Partner is on standby for immediate rescue.");
            } else if (ngo.availabilityStatus === 'Busy') {
                availabilityScore = 7;
                explanations.push("Active: Partner is on route but can accept secondary tasks.");
            }
            score += availabilityScore;

            // 4. Workload Balance Score (15%)
            // Comparison of active tasks vs declared daily capacity
            const capacity = ngo.maxDailyMeals || 50; // Default 50 if unset
            const loadRatio = ngoStats.activeCount / (capacity / 5); // Assume roughly 5 concurrent tasks max
            const workloadScore = Math.max(0, 15 * (1 - Math.min(1, loadRatio)));
            score += workloadScore;
            if (loadRatio < 0.2) explanations.push("High Capacity: Partner has significant resources available for this rescue.");

            // 5. Reliability / Rating Score (10%)
            // Bayesian-lite approach: penalize low totalRatings
            const ratingWeight = Math.min(ngo.totalRatings || 0, 10) / 10;
            const normalizedRating = (ngo.averageRating || 3) / 5;
            const reliabilityScore = 10 * normalizedRating * ratingWeight;
            score += reliabilityScore;
            if (ngo.averageRating >= 4.5 && ngo.totalRatings > 5) {
                explanations.push(`Top Rated: Highly reliable partner with ${ngo.averageRating}/5 score.`);
            }

            // 6. Completion History Score (5%)
            const totalTasks = ngoStats.completedCount + ngoStats.failedCount;
            const completionRate = totalTasks > 0 ? ngoStats.completedCount / totalTasks : 0.8; // Neutral 80% for new
            const historyScore = 5 * completionRate;
            score += historyScore;

            // 7. Food Suitability Adjustment (Adjustment within 0-100 logic)
            // If category mismatch, apply a 20% penalty to the total accumulated score
            let suitabilityMultiplier = 1.0;
            const hasCategories = ngo.acceptedCategories && ngo.acceptedCategories.length > 0;
            if (hasCategories) {
                const isMatch = ngo.acceptedCategories.includes(donation.category);
                if (isMatch) {
                    explanations.push(`Specialist: Partner specifically handles ${donation.category} items.`);
                } else {
                    suitabilityMultiplier = 0.8;
                    explanations.push("Secondary Match: Category outside partner's primary focus.");
                }
            }

            const finalScore = Math.min(100, Math.round(score * suitabilityMultiplier));

            return {
                ngoId: ngo._id,
                name: ngo.name,
                phoneNumber: ngo.phoneNumber,
                distanceKm: parseFloat(distKm.toFixed(1)),
                etaMinutes: etaMins,
                etaText: etaMins > 60 ? `${Math.floor(etaMins/60)}h ${etaMins%60}m` : `${etaMins} mins`,
                score: finalScore,
                confidence: Math.round(completionRate * 100),
                availability: ngo.availabilityStatus,
                workload: ngoStats.activeCount,
                capacity: capacity,
                reasons: explanations,
                explanation: explanations.slice(0, 2).join(' ') // Keep it concise
            };
        });

        // Sort descending by score
        return scoredNgos.sort((a, b) => b.score - a.score);
    } catch (err) {
        console.error('Smart Matching Error:', err);
        return [];
    }
};
