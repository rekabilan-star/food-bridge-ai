const SMSLog = require('../models/SMSLog');

// @desc    Get all SMS logs (Admin)
// @route   GET /api/admin/sms-logs
// @access  Private (Admin)
exports.getSMSLogs = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 20;
        const startIndex = (page - 1) * limit;

        const query = {};
        if (req.query.status) query.status = req.query.status;
        if (req.query.phoneNumber) query.phoneNumber = { $regex: req.query.phoneNumber };

        const total = await SMSLog.countDocuments(query);
        const logs = await SMSLog.find(query)
            .populate('userId', 'name email role')
            .sort('-createdAt')
            .skip(startIndex)
            .limit(limit);

        res.status(200).json({
            success: true,
            count: logs.length,
            pagination: {
                total,
                page,
                pages: Math.ceil(total / limit)
            },
            data: logs
        });
    } catch (err) {
        next(err);
    }
};

// @desc    Get stats for SMS logs
// @route   GET /api/admin/sms-stats
// @access  Private (Admin)
exports.getSMSStats = async (req, res, next) => {
    try {
        const stats = await SMSLog.aggregate([
            { $group: { _id: '$status', count: { $sum: 1 } } }
        ]);

        const providerStats = await SMSLog.aggregate([
            { $group: { _id: '$provider', count: { $sum: 1 } } }
        ]);

        res.status(200).json({
            success: true,
            data: {
                status: stats,
                providers: providerStats
            }
        });
    } catch (err) {
        next(err);
    }
};
