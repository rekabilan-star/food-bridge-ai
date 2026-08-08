const mongoose = require('mongoose');
const User = require('../models/User');
const dotenv = require('dotenv');
const dns = require('dns');

dns.setServers(['8.8.8.8', '8.8.4.4']);
dns.setDefaultResultOrder('ipv4first');

dotenv.config({ path: './.env' });
if (!process.env.MONGODB_URI) {
    dotenv.config({ path: '../.env' });
}

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const adminExists = await User.findOne({ email: 'admin@foodrescue.com' });

    if (!adminExists) {
      await User.create({
        name: 'System Admin',
        email: 'admin@foodrescue.com',
        password: 'adminpassword123',
        role: 'admin',
        phoneNumber: '0000000000',
        status: 'approved',
      });
      console.log('Admin user created successfully');
    } else {
      console.log('Admin user already exists');
    }

    process.exit();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

seedAdmin();
