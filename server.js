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
  console.log(✅ Auth service running on port \);
});
