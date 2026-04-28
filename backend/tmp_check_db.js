const mongoose = require('mongoose');

mongoose.connect('mongodb://127.0.0.1:27017/travelappDB')
  .then(async () => {
    const db = mongoose.connection.db;
    const user = await db.collection('users').findOne({ email: 'bhanu@gmail.com' });
    console.log("User found:", user);
    process.exit(0);
  });
