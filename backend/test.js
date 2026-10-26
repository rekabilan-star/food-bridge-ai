require("dotenv").config();
const mongoose = require("mongoose");

const uri =
  process.env.MONGODB_URI ||
  process.env.MONGO_URI ||
  "mongodb://localhost:27017/foodbridge";

async function connectDB() {
  try {
    await mongoose.connect(uri);
    console.log("✅ MongoDB Connected Successfully!");
    process.exit(0);
  } catch (err) {
    console.error("❌ Connection Failed:");
    console.error(err.message || err);
    process.exit(1);
  }
}

connectDB();
