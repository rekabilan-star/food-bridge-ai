const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    console.log('Attempting to connect to MongoDB Atlas...');
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 20000, // Increase to 20s
      socketTimeoutMS: 45000,
      connectTimeoutMS: 20000,
      family: 4
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Detailed Connection Error: ${error.message}`);
    if (error.reason) {
        console.error('Error Reason:', JSON.stringify(error.reason, null, 2));
    }
  }
};

module.exports = connectDB;
