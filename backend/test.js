const mongoose = require("mongoose");

const uri =
  "mongodb+srv://kabilanr343_db_user:kabilan123@cluster0.jt233wu.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";

async function connectDB() {
  try {
    await mongoose.connect(uri);
    console.log("✅ MongoDB Atlas Connected Successfully!");
    process.exit(0);
  } catch (err) {
    console.error("❌ Connection Failed:");
    console.error(err);
    process.exit(1);
  }
}

connectDB();