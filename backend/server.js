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

// ── Stats (calls stored procedure) ──────────────────────────
app.get("/api/stats", async (_, res) => {
  try {
    // Call the analytics procedure that returns aggregated stats
    const [results] = await q("CALL Get_Analytics_Data()");
    
    // Extract first result set (summary stats)
    const summary = results[0][0];
    
    res.json({
      total_farmers: summary.Total_Farmers,
      total_yield: summary.Total_Yield,
      avg_rainfall: summary.Average_Rainfall,
      top_farmer: summary.Top_Farmer,
      top_crop: summary.Top_Crop
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── All records (uses view instead of raw SQL) ──────────────
app.get("/api/records", async (_, res) => {
  try {
    // Retrieve data from the vw_yield_detail view (no raw JOINs)
    const [r] = await q(
      `SELECT Yield_ID, Farmer_ID, Farmer, Crop, Season, Rainfall, Yield, Area_Ha, Yield_Per_Ha
       FROM vw_yield_detail
       ORDER BY Recorded_Date DESC`
    );
    res.json(r);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Chart data (simpler, view-based) ────────────────────────
app.get("/api/chart", async (_, res) => {
  try {
    // Use the season performance view for chart data
    const [r] = await q(
      `SELECT Season, Total_Yield, Rainfall FROM vw_season_performance ORDER BY Season`
    );
    res.json(r);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Add record (calls stored procedure) ─────────────────────
app.post("/api/records", async (req, res) => {
  const { farmer_id, crop_id, season_id, yield_amount, rainfall_amount } = req.body;
  const conn = await pool.getConnection();
  
  try {
    // Handle rainfall update/insert if provided
    if (rainfall_amount != null) {
      const [[ex]] = await conn.execute(
        "SELECT Rainfall_ID FROM Rainfall WHERE Season_ID = ?", 
        [season_id]
      );
      
      if (ex) {
        await conn.execute(
          "UPDATE Rainfall SET Rainfall_Amount = ? WHERE Season_ID = ?", 
          [rainfall_amount, season_id]
        );
      } else {
        await conn.execute(
          "INSERT INTO Rainfall (Season_ID, Rainfall_Amount) VALUES (?, ?)", 
          [season_id, rainfall_amount]
        );
      }
    }
    
    // Call the stored procedure for yield insertion (handles its own transaction internally)
    await conn.execute(
      "CALL Insert_Yield_Record(?, ?, ?, ?)",
      [farmer_id, crop_id, season_id, yield_amount]
    );
    
    res.json({ success: true, message: "Yield record inserted successfully" });
  } catch (e) {
    res.status(500).json({ 
      error: e.sqlMessage || e.message || "Failed to insert yield record"
    });
  } finally {
    conn.release();
  }
});

// ── Delete record ────────────────────────────────────────────
app.delete("/api/records/:id", async (req, res) => {
  try {
    const [result] = await q("DELETE FROM Yield WHERE Yield_ID = ?", [req.params.id]);
    
    if (result.affectedRows === 0) {
      res.status(404).json({ error: "Yield record not found" });
    } else {
      res.json({ success: true, message: "Yield record deleted successfully" });
    }
  } catch (e) {
    res.status(500).json({ 
      error: e.message || "Failed to delete yield record",
      details: e.sqlMessage
    });
  }
});

// ── Farmer Summary (view-based) ──────────────────────────────
app.get("/api/farmers/summary", async (_, res) => {
  try {
    const [r] = await q(
      `SELECT * FROM vw_farmer_summary ORDER BY Total_Yield DESC`
    );
    res.json(r);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Season Report (calls stored procedure with cursor) ───────
app.get("/api/season/:id/report", async (req, res) => {
  try {
    const [results] = await q("CALL Generate_Season_Report(?)", [req.params.id]);
    res.json(results[0]); // First result set from the procedure
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Full Analytics (multiple result sets) ────────────────────
app.get("/api/analytics", async (_, res) => {
  try {
    const [results] = await q("CALL Get_Analytics_Data()");
    res.json({
      summary: results[0][0],
      seasonal_comparison: results[1]
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));
