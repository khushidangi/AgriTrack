# AgriDB - Crop Yield & Weather Analysis System

A full-stack web application for tracking farmer data, crop yields, rainfall patterns, and generating analytics.

## 📋 Project Structure

```
agri-simple/
├── backend/          # Node.js + Express API
├── frontend/         # React + Vite SPA
├── database/         # MySQL schema & seed data
└── README.md
```

## 🛠️ Tech Stack

**Backend:**
- Node.js + Express.js
- MySQL2
- CORS enabled

**Frontend:**
- React 18
- Vite
- Recharts (charting)

**Database:**
- MySQL 8.0+

## 📦 Setup Instructions

### Prerequisites
- Node.js v16+
- MySQL Server
- npm or yarn

### 1. Database Setup

```bash
# Connect to MySQL
mysql -u root -p

# Run the SQL file
source database/agri_db.sql;
```

This creates the database with:
- Farmer
- Crop
- Season
- Rainfall
- Land_Record
- Yield

Plus sample data for testing.

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your MySQL password
# Then start the server
npm start
```

Server runs on `http://localhost:5000`

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create .env file (optional)
cp .env.example .env

# Start development server
npm run dev
```

Frontend runs on `http://localhost:5173`

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/farmers` | List all farmers |
| GET | `/api/crops` | List all crops |
| GET | `/api/seasons` | List all seasons |
| GET | `/api/records` | Get all yield records with details |
| GET | `/api/stats` | Get dashboard statistics |
| GET | `/api/chart` | Get yield vs rainfall chart data |
| POST | `/api/records` | Add new yield record |
| DELETE | `/api/records/:id` | Delete a yield record |

### POST /api/records Request Body
```json
{
  "farmer_id": 1,
  "crop_id": 1,
  "season_id": 1,
  "yield_amount": 5000,
  "rainfall_amount": 320.5
}
```

## 🚀 Running the Application

### Terminal 1 - Start Backend
```bash
cd backend
npm start
```

### Terminal 2 - Start Frontend
```bash
cd frontend
npm run dev
```

Then open http://localhost:5173 in your browser.

## 🎯 Features

- ✅ Dashboard with key statistics
- ✅ Yield vs Rainfall visualization (bar chart)
- ✅ Add new yield records
- ✅ View all records in table format
- ✅ Delete records
- ✅ Responsive design (mobile & desktop)

## ⚠️ Important Notes

- **MySQL Password**: Store in `.env` file, never commit to git
- **CORS**: Currently allows all origins. Restrict in production
- **Validation**: Add input validation before deployment
- **Error Handling**: Implement proper error logging

## 📝 Database Schema

**Farmer** - Stores farmer information
**Crop** - List of crops
**Season** - Year and season combinations
**Rainfall** - Rainfall data per season
**Yield** - Crop yield records
**Land_Record** - Land area records per farmer

## 🔧 Development

### Build Frontend
```bash
cd frontend
npm run build
```

Output will be in `frontend/dist/`

### Common Issues

**Backend won't start:**
- Check MySQL is running
- Verify .env file exists with correct password
- Check port 5000 is not in use

**Frontend API calls fail:**
- Ensure backend is running on http://localhost:5000
- Check vite.config.js proxy settings
- Verify CORS is enabled on backend

## 📚 Additional Resources

- [Express.js Docs](https://expressjs.com/)
- [React Docs](https://react.dev)
- [Vite Docs](https://vitejs.dev)
- [MySQL Docs](https://dev.mysql.com/doc/)
