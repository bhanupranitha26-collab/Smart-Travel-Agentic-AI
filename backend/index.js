const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');

const app = express();
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(cors());

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected"))
  .catch(err => console.log(err));

// User Schema
const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  hashed_password: String
});
const User = mongoose.model('User', UserSchema, 'users');

// Signup API
app.post('/signup', async (req, res) => {
  console.log("Signup:", req.body);
  try {
    const existingUser = await User.findOne({ email: req.body.email });
    if (existingUser) {
      return res.send("User already exists");
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(req.body.password, salt);

    const user = new User({
      name: req.body.name,
      email: req.body.email,
      password: hashedPassword
    });

    await user.save();
    res.json({
      message: "User registered",
      userId: user._id
    });
  } catch (err) {
    res.status(500).send(err);
  }
});

// Login API
app.post('/login', async (req, res) => {
  console.log("Login:", req.body);
  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user) {
      return res.send("Invalid credentials");
    }

    const storedPassword = user.password || user.hashed_password;
    if (!storedPassword) {
      return res.send("Invalid credentials");
    }

    const isMatch = await bcrypt.compare(req.body.password, storedPassword);
    if (!isMatch) {
      return res.send("Invalid credentials");
    }

    res.json({
      message: "Login successful",
      userId: user._id
    });
  } catch (err) {
    console.error("Login Error:", err);
    res.status(500).json({ message: "Server error", error: err.toString() });
  }
});

// Expense Schema
const ExpenseSchema = new mongoose.Schema({
  userId: String,
  amount: Number,
  category: String,
  date: String,
  description: String,
  trip_id: String
});
const Expense = mongoose.model('Expense', ExpenseSchema, 'expense');

app.post(['/add-expense', '/agents/add-expense'], async (req, res) => {
  console.log("BODY:", req.body);
  if (!req.body.userId && !req.body.user_id) {
    return res.status(400).json({ message: "User ID is required" });
  }
  try {
    const expense = new Expense({
      ...req.body,
      userId: req.body.userId || req.body.user_id
    });
    await expense.save();
    console.log("Saved to DB");
    res.send("Saved");
  } catch (err) {
    console.log("ERROR:", err);
    res.status(500).send(err);
  }
});

app.get('/expense/:userId', async (req, res) => {
  try {
    const data = await Expense.find({ $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] });
    res.json(data);
  } catch (err) {
    res.status(500).send(err);
  }
});

// Memory Schema
const MemorySchema = new mongoose.Schema({
  userId: String,
  image: String,
  description: String,
  trip_id: String
});
// Using explicit collection names to match their Compass screenshot
// But the user expects `expenses` to auto-create, so I'll let Memories become `memories`
const Memory = mongoose.model('Memory', MemorySchema);

app.post(['/add-memory', '/add-memories', '/agents/upload-memory'], async (req, res) => {
  console.log("MEMORY BODY:", req.body);
  if (!req.body.userId && !req.body.user_id) {
    return res.status(400).json({ message: "User ID is required" });
  }
  try {
    const memory = new Memory({
      ...req.body,
      userId: req.body.userId || req.body.user_id
    });
    await memory.save();
    console.log("Memory Saved to DB");
    res.send("Saved");
  } catch (err) {
    console.log("ERROR:", err);
    res.status(500).send(err);
  }
});

app.get('/memories/:userId', async (req, res) => {
  try {
    const data = await Memory.find({ $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] });
    res.json(data);
  } catch (err) {
    res.status(500).send(err);
  }
});

// Past Trip Schema
const PastTripSchema = new mongoose.Schema({
  userId: String,
  place: String,
  date: String,
  trip_id: String
});
// If we name it PastTrip, mongoose will create `pasttrips`. Let's specify `past_trip`
const PastTrip = mongoose.model('PastTrip', PastTripSchema, 'past_trip');

app.post('/add-past-trip', async (req, res) => {
  console.log("PAST TRIP BODY:", req.body);
  if (!req.body.userId) {
    return res.status(400).json({ message: "User ID is required" });
  }
  try {
    const trip = new PastTrip(req.body);
    await trip.save();
    console.log("Past Trip Saved to DB");
    res.send("Saved");
  } catch (err) {
    console.log("ERROR:", err);
    res.status(500).send(err);
  }
});

app.get(['/past_trip/:userId', '/past-trip/:userId'], async (req, res) => {
  try {
    const data = await PastTrip.find({ $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] });
    res.json(data);
  } catch (err) {
    res.status(500).send(err);
  }
});

app.listen(3000, () => {
  console.log("Server running on port 3000");
});
