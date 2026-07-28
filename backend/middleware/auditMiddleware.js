const AuditLog = require('../models/AuditLog');

const auditLogger = async (req, res, next) => {
  // Only log state-changing requests or sensitive ones
  if (['POST', 'PUT', 'DELETE'].includes(req.method)) {
    const originalSend = res.send;

    // Create log entry after the request is processed
    res.send = function(data) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
            AuditLog.create({
                userId: req.user ? req.user.id : null,
                action: `${req.method} ${req.path}`,
                method: req.method,
                path: req.path,
                params: req.params,
                body: req.method === 'POST' || req.method === 'PUT' ? req.body : null,
                ip: req.ip
            }).catch(err => console.error('Audit Log Error:', err));
        }
        originalSend.apply(res, arguments);
    };
  }
  next();
};

module.exports = auditLogger;
