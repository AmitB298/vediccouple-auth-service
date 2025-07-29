
# ================================================
# 🛠️ VedicCouple Auth Service Full Setup Script
# ================================================

Write-Host "🔧 Fixing and Launching VedicCouple Auth Service..." -ForegroundColor Cyan

# 1. Set working directory
Set-Location "E:\VedicCouple\matchmaking-app-backend\services\auth-service"

# 2. Ensure folders exist
@("config", "controllers", "models", "routes") | ForEach-Object {
    if (-Not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
        Write-Host "✅ Created folder: $_"
    }
}

# 3. Write package.json patch for ES Modules
$jsonPath = "package.json"
if (Test-Path $jsonPath) {
    (Get-Content $jsonPath -Raw) -replace '"main": "(.*?)"', '"type": "module", "main": "`$1"' | Set-Content $jsonPath
    Write-Host "✅ Patched package.json with type: module"
} else {
    npm init -y | Out-Null
    (Get-Content $jsonPath -Raw) -replace '"main": "(.*?)"', '"type": "module", "main": "`$1"' | Set-Content $jsonPath
    Write-Host "✅ Initialized and patched package.json"
}

# 4. Install dependencies
npm install express cors dotenv mongoose bcryptjs jsonwebtoken --save
Write-Host "📦 Dependencies installed"

# 5. Create .env
@"
MONGO_URI=mongodb://localhost:27017/vediccouple
JWT_SECRET=VedicCoupleSecretKey
PORT=5001
"@ | Out-File -Encoding UTF8 ".env"
Write-Host "✅ Created .env file"

# 6. Create config/db.js
@"
import mongoose from 'mongoose';

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB connected`);
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    process.exit(1);
  }
};

export default connectDB;
"@ | Out-File -Encoding UTF8 "config/db.js"

# 7. Create models/User.js
@"
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

export default User;
"@ | Out-File -Encoding UTF8 "models/User.js"

# 8. Create controllers/authController.js
@"
import User from '../models/User.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: 'User already exists' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, password: hashed });
    res.status(201).json({ user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
"@ | Out-File -Encoding UTF8 "controllers/authController.js"

# 9. Create routes/authRoutes.js
@"
import express from 'express';
import { register, login } from '../controllers/authController.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);

export default router;
"@ | Out-File -Encoding UTF8 "routes/authRoutes.js"

# 10. Create server.js
@"
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import connectDB from './config/db.js';
import authRoutes from './routes/authRoutes.js';

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5001;

app.use(cors());
app.use(express.json());

connectDB();

app.use('/api/v1/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('✅ Auth Service Running');
});

app.listen(PORT, () => {
  console.log(`✅ Auth service running on port \${PORT}`);
});
"@ | Out-File -Encoding UTF8 "server.js"

# 11. Launch server
Start-Process "powershell" -ArgumentList "node server.js" -WorkingDirectory "."
Write-Host "🚀 Auth service launched on port 5001"
