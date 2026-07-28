const geolib = require('geolib');

/**
 * Optimizes a route for a volunteer with multiple pickups and deliveries.
 * Uses a Greedy approach for the Traveling Salesperson Problem (TSP)
 * combined with urgency (expiry time) weighting.
 */
exports.optimizeRoute = (startLocation, tasks) => {
    if (!tasks || tasks.length === 0) return [];

    let currentPos = startLocation;
    let unvisited = [...tasks];
    const optimizedRoute = [];

    while (unvisited.length > 0) {
        let bestIndex = -1;
        let highestScore = -Infinity;

        for (let i = 0; i < unvisited.length; i++) {
            const task = unvisited[i];

            // Calculate Distance Score (Closer is better)
            const distance = geolib.getDistance(
                { latitude: currentPos.latitude, longitude: currentPos.longitude },
                { latitude: task.latitude, longitude: task.longitude }
            );
            const distanceScore = Math.max(0, 100 - (distance / 500)); // 100 points max, -1 point per 500m

            // Calculate Urgency Score (Closer to expiry is better)
            // Assuming task.bestBeforeTime exists for pickups
            let urgencyScore = 0;
            if (task.bestBeforeTime) {
                const hoursToExpiry = (new Date(task.bestBeforeTime) - new Date()) / (1000 * 60 * 60);
                urgencyScore = Math.max(0, (24 - hoursToExpiry) * 5); // Higher score for sooner expiry
            }

            // Total Score
            const totalScore = distanceScore + urgencyScore;

            if (totalScore > highestScore) {
                highestScore = totalScore;
                bestIndex = i;
            }
        }

        const nextTask = unvisited.splice(bestIndex, 1)[0];
        optimizedRoute.push(nextTask);
        currentPos = { latitude: nextTask.latitude, longitude: nextTask.longitude };
    }

    return optimizedRoute;
};
