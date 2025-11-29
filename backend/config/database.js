const mongoose = require('mongoose');

const connectDB = async (retries = 5) => {
  for (let i = 0; i < retries; i++) {
    try {
      const conn = await mongoose.connect(process.env.COSMOS_DB_URI, {
        serverSelectionTimeoutMS: 10000,
        socketTimeoutMS: 45000,
        maxPoolSize: 10,
        retryWrites: false,
        retryReads: false
      });
      
      console.log(`MongoDB Connected: ${conn.connection.host}`);
      return;
    } catch (error) {
      console.error(`Database connection attempt ${i + 1} failed:`, error.message);
      
      if (i === retries - 1) {
        console.error('All database connection attempts failed');
        process.exit(1);
      }
      
      console.log(`Retrying in ${(i + 1) * 2} seconds...`);
      await new Promise(resolve => setTimeout(resolve, (i + 1) * 2000));
    }
  }
};

module.exports = connectDB;