const express = require("express");
const cors    = require("cors");
const mysql   = require("mysql2/promise");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

// ── Database Configuration (from .env) ────────────────────────
const pool = mysql.createPool({
  host:     process.env.DB_HOST     || "localhost",
  user:     process.env.DB_USER     || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME     || "agri_db",
});

const q = (sql, p) => pool.execute(sql, p);

// ── Dropdowns ────────────────────────────────────────────────
app.get("/api/farmers", async (_, res) => {
  const [r] = await q("SELECT * FROM Farmer ORDER BY Name");
  res.json(r);
});
app.get("/api/crops", async (_, res) => {
  const [r] = await q("SELECT * FROM Crop ORDER BY Crop_Name");
  res.json(r);
});
app.get("/api/seasons", async (_, res) => {
  const [r] = await q("SELECT * FROM Season ORDER BY Year, Season_Name");
  res.json(r);
});

// ── Stats ────────────────────────────────────────────────────
app.get("/api/stats", async (_, res) => {
  const [[{ total_farmers }]] = await q("SELECT COUNT(*) AS total_farmers FROM Farmer");
  const [[{ avg_yield }]]     = await q("SELECT ROUND(AVG(Yield_Amount),2) AS avg_yield FROM Yield");
  const [[{ total_records }]] = await q("SELECT COUNT(*) AS total_records FROM Yield");
  const [[{ top_crop }]]      = await q(
    `SELECT c.Crop_Name AS top_crop FROM Yield y
     JOIN Crop c ON c.Crop_ID = y.Crop_ID
     GROUP BY c.Crop_ID ORDER BY SUM(y.Yield_Amount) DESC LIMIT 1`
  );
  res.json({ total_farmers, avg_yield, total_records, top_crop });
});

// ── All records (joined) ─────────────────────────────────────
app.get("/api/records", async (_, res) => {
  const [r] = await q(
    `SELECT y.Yield_ID, f.Name AS farmer, c.Crop_Name AS crop,
            CONCAT(s.Season_Name,' ',s.Year) AS season,
            r.Rainfall_Amount AS rainfall, y.Yield_Amount AS yield
     FROM Yield y
     JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID
     JOIN Crop   c ON c.Crop_ID   = y.Crop_ID
     JOIN Season s ON s.Season_ID = y.Season_ID
     LEFT JOIN Rainfall r ON r.Season_ID = y.Season_ID
     ORDER BY y.Yield_ID DESC`
  );
  res.json(r);
});

// ── Chart data ───────────────────────────────────────────────
app.get("/api/chart", async (_, res) => {
  const [r] = await q(
    `SELECT CONCAT(s.Season_Name,' ',s.Year) AS season,
            ROUND(AVG(y.Yield_Amount),2) AS avg_yield,
            r.Rainfall_Amount AS rainfall
     FROM Yield y
     JOIN Season s ON s.Season_ID = y.Season_ID
     LEFT JOIN Rainfall r ON r.Season_ID = y.Season_ID
     GROUP BY y.Season_ID, s.Season_Name, s.Year, r.Rainfall_Amount
     ORDER BY s.Year, s.Season_Name`
  );
  res.json(r);
});

// ── Add record ───────────────────────────────────────────────
app.post("/api/records", async (req, res) => {
  const { farmer_id, crop_id, season_id, yield_amount, rainfall_amount } = req.body;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    if (rainfall_amount != null) {
      const [[ex]] = await conn.execute(
        "SELECT Rainfall_ID FROM Rainfall WHERE Season_ID = ?", [season_id]
      );
      if (ex) {
        await conn.execute("UPDATE Rainfall SET Rainfall_Amount=? WHERE Season_ID=?", [rainfall_amount, season_id]);
      } else {
        await conn.execute("INSERT INTO Rainfall (Season_ID,Rainfall_Amount) VALUES(?,?)", [season_id, rainfall_amount]);
      }
    }
    await conn.execute(
      "INSERT INTO Yield (Farmer_ID,Crop_ID,Season_ID,Yield_Amount) VALUES(?,?,?,?)",
      [farmer_id, crop_id, season_id, yield_amount]
    );
    await conn.commit();
    res.json({ success: true });
  } catch (e) {
    await conn.rollback();
    res.status(500).json({ error: e.message });
  } finally {
    conn.release();
  }
});

// ── Delete record ────────────────────────────────────────────
app.delete("/api/records/:id", async (req, res) => {
  await q("DELETE FROM Yield WHERE Yield_ID=?", [req.params.id]);
  res.json({ success: true });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));
