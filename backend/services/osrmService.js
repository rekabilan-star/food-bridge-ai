const axios = require('axios');
const geolib = require('geolib');

/**
 * OSRM Routing Service (Phase 2B Step 2)
 * Provides road-aware routing with heuristic fallback.
 */

// Public OSRM API endpoint
const OSRM_BASE_URL = 'http://router.project-osrm.org/route/v1/driving/';

/**
 * Get route between origin and destination
 * @param {Object} origin {latitude, longitude}
 * @param {Object} destination {latitude, longitude}
 * @returns {Promise<Object>} Normalized route data
 */
exports.getRoute = async (origin, destination) => {
    // 1. Validation
    if (!origin || !destination ||
        !origin.latitude || !origin.longitude ||
        !destination.latitude || !destination.longitude) {
        return this.getHeuristicFallback(origin, destination, 'Invalid Input Coordinates');
    }

    const coords = `${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}`;
    const url = `${OSRM_BASE_URL}${coords}?overview=full&geometries=geojson`;

    try {
        const response = await axios.get(url, { timeout: 5000 });

        if (response.data && response.data.routes && response.data.routes.length > 0) {
            const route = response.data.routes[0];

            // Normalize response for Flutter
            return {
                success: true,
                source: 'OSRM',
                distanceMeters: route.distance,
                durationSeconds: route.duration,
                // OSRM GeoJSON is [lng, lat], we keep it for consistency with MongoDB/Map
                coordinates: route.geometry.coordinates
            };
        } else {
            return this.getHeuristicFallback(origin, destination, 'No Route Found');
        }
    } catch (error) {
        console.error('OSRM API Error:', error.message);
        return this.getHeuristicFallback(origin, destination, `OSRM Error: ${error.message}`);
    }
};

/**
 * Heuristic Fallback (Haversine distance + estimated time)
 */
exports.getHeuristicFallback = (origin, destination, reason = 'Fallback') => {
    if (!origin || !destination) {
        return { success: false, error: 'Insufficient data for routing' };
    }

    const distanceMeters = geolib.getDistance(
        { latitude: origin.latitude, longitude: origin.longitude },
        { latitude: destination.latitude, longitude: destination.longitude }
    );

    // Heuristic: 4 minutes per KM + 5 minutes baseline
    const distanceKm = distanceMeters / 1000;
    const durationSeconds = Math.round((distanceKm * 4 + 5) * 60);

    return {
        success: true,
        source: 'HEURISTIC_FALLBACK',
        reason: reason,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        // For fallback, just return the straight line between points
        coordinates: [
            [parseFloat(origin.longitude), parseFloat(origin.latitude)],
            [parseFloat(destination.longitude), parseFloat(destination.latitude)]
        ]
    };
};
