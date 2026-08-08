const axios = require('axios');
const SMSLog = require('../models/SMSLog');

/**
 * SMS Templates Configuration
 */
const TEMPLATES = {
    DONATION_ACCEPTED: (ngoName, foodName) => `Your donation for ${foodName} has been accepted by ${ngoName}. - FoodBridge AI`,
    DONATION_REJECTED: (foodName, reason) => `Your donation for ${foodName} was rejected. Reason: ${reason}. - FoodBridge AI`,
    NGO_ASSIGNED: (foodName) => `A new food rescue task is assigned to you: ${foodName}. Please check the app. - FoodBridge AI`,
    PICKUP_STARTED: (foodName) => `The driver has started the pickup for ${foodName} and is on the way. - FoodBridge AI`,
    PICKUP_COMPLETED: (foodName) => `Great news! Your donation for ${foodName} has been picked up. - FoodBridge AI`,
    DONATION_CANCELLED: (foodName) => `The donation for ${foodName} has been cancelled. - FoodBridge AI`,
    PASSWORD_OTP: (otp) => `Your FoodBridge AI password reset OTP is ${otp}. Valid for 10 minutes.`,
    ADMIN_ALERT: (msg) => `ADMIN ALERT: ${msg} - FoodBridge AI`
};

/**
 * Main SMS Service
 */
class SMSService {
    constructor() {
        this.provider = process.env.SMS_PROVIDER || 'Fast2SMS'; // Default to Fast2SMS for Indian numbers
        this.apiKey = process.env.SMS_API_KEY;
        this.twilioSid = process.env.TWILIO_SID;
        this.twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;
        this.twilioNumber = process.env.TWILIO_PHONE_NUMBER;
    }

    /**
     * Send SMS to a user
     * @param {Object} options
     * @param {string} options.userId
     * @param {string} options.phoneNumber
     * @param {string} options.templateKey - Key from TEMPLATES
     * @param {Array} options.args - Arguments for template function
     */
    async send(options) {
        const { userId, phoneNumber, templateKey, args = [] } = options;

        if (!phoneNumber) return;

        const message = TEMPLATES[templateKey] ? TEMPLATES[templateKey](...args) : templateKey;

        // 1. Create Log Entry
        const log = await SMSLog.create({
            userId,
            phoneNumber,
            message,
            provider: this.provider,
            templateName: templateKey,
            status: 'sent'
        });

        try {
            let response;
            if (this.provider === 'Twilio') {
                response = await this._sendTwilio(phoneNumber, message);
            } else if (this.provider === 'Fast2SMS') {
                response = await this._sendFast2SMS(phoneNumber, message);
            } else {
                throw new Error('Unsupported SMS Provider');
            }

            log.status = 'delivered';
            await log.save();
            return true;
        } catch (err) {
            console.error('SMS Error:', err.message);
            log.status = 'failed';
            log.error = err.message;
            await log.save();

            // Automatic Retry Logic (1 attempt)
            if (log.retryCount < 1) {
                setTimeout(() => this.retry(log._id), 5000);
            }
            return false;
        }
    }

    async _sendTwilio(to, body) {
        // Implementation for Twilio
        // const client = require('twilio')(this.twilioSid, this.twilioAuthToken);
        // return client.messages.create({ body, from: this.twilioNumber, to });
        console.log(`[Twilio Mock] SMS to ${to}: ${body}`);
        return { success: true };
    }

    async _sendFast2SMS(to, body) {
        // Implementation for Fast2SMS (Indian numbers)
        // const res = await axios.post('https://www.fast2sms.com/dev/bulkV2', {
        //     message: body,
        //     language: 'english',
        //     route: 'q',
        //     numbers: to
        // }, { headers: { authorization: this.apiKey } });
        // return res.data;
        console.log(`[Fast2SMS Mock] SMS to ${to}: ${body}`);
        return { success: true };
    }

    async retry(logId) {
        const log = await SMSLog.findById(logId);
        if (!log || log.status === 'delivered') return;

        log.retryCount += 1;
        try {
            if (log.provider === 'Twilio') await this._sendTwilio(log.phoneNumber, log.message);
            else await this._sendFast2SMS(log.phoneNumber, log.message);

            log.status = 'delivered';
            await log.save();
        } catch (err) {
            log.status = 'failed';
            log.error = `Retry failed: ${err.message}`;
            await log.save();
        }
    }
}

module.exports = new SMSService();
