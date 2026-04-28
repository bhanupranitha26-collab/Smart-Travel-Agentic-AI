const mongoose = require('mongoose');
mongoose.connect('mongodb://127.0.0.1:27017/travelappDB').then(async () => {
    const expenses = mongoose.connection.collection('expense');
    const res = await expenses.updateMany(
        {trip_id: {$in: [null, ""]}}, 
        {$set: {trip_id: 'kerala_2026-04-06T00:00:00.000_2026-04-09T00:00:00.000'}}
    );
    console.log("Expense update:", res);

    const memories = mongoose.connection.collection('memories');
    const res2 = await memories.updateMany(
        {trip_id: {$in: [null, ""]}}, 
        {$set: {trip_id: 'kerala_2026-04-06T00:00:00.000_2026-04-09T00:00:00.000'}}
    );
    console.log("Memories update:", res2);

    process.exit(0);
});
