-- ============================================================
-- AGRITRACK: Sample Data + Verification Queries
-- Seed data, test data, and verification suite
-- ============================================================

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Farmers
-- ═══════════════════════════════════════════════════════════

INSERT INTO Farmer (Name, Location, Contact_No) VALUES
('Rajinder Singh',   'Ludhiana',  '9876501001'),
('Gurpreet Kaur',    'Amritsar',  '9876501002'),
('Harjit Sandhu',    'Patiala',   '9876501003'),
('Manpreet Dhillon', 'Bathinda',  '9876501004'),
('Sukhdev Brar',     'Ferozepur', '9876501005'),
('Priya Sharma',     'Jalandhar', '9876501006'),
('Vikram Patel',     'Kapurthala','9876501007'),
('Simran Kahal',     'Hisar',     '9876501008'),
('Rajan Mittal',     'Kaithal',   '9876501009'),
('Deepak Sharma',    'Sonipat',   '9876501010');

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Crops
-- ═══════════════════════════════════════════════════════════

INSERT INTO Crop (Crop_Name) VALUES
('Wheat'), ('Rice'), ('Maize'), ('Sugarcane'), ('Cotton'),
('Pulses'), ('Soybean'), ('Mustard'), ('Barley'), ('Oats');

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Seasons
-- ═══════════════════════════════════════════════════════════

INSERT INTO Season (Season_Name, Year) VALUES
('Kharif', 2022), ('Rabi', 2022),
('Kharif', 2023), ('Rabi', 2023),
('Kharif', 2024), ('Rabi', 2024);

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Rainfall
-- ═══════════════════════════════════════════════════════════

INSERT INTO Rainfall (Season_ID, Rainfall_Amount) VALUES
(1, 320.5),  -- Kharif 2022
(2, 45.0),   -- Rabi 2022
(3, 410.0),  -- Kharif 2023
(4, 38.5),   -- Rabi 2023
(5, 375.0),  -- Kharif 2024
(6, 52.3);   -- Rabi 2024

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Land Records
-- ═══════════════════════════════════════════════════════════

INSERT INTO Land_Record (Farmer_ID, Area_in_Hectare) VALUES
(1, 5.0), (2, 3.5), (3, 7.2), (4, 4.8), (5, 6.1),
(6, 4.5), (7, 8.0), (8, 3.2), (9, 5.5), (10, 6.8);

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Yield Records
-- ═══════════════════════════════════════════════════════════

INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount) VALUES
-- Kharif 2022 (Season 1)
(1, 2, 1, 4200), (2, 2, 1, 3800), (3, 3, 1, 6200),
(4, 5, 1, 3300), (5, 4, 1, 7100), (6, 2, 1, 4500),
(7, 3, 1, 6800), (8, 5, 1, 3100), (9, 4, 1, 7200),
(10, 2, 1, 4600),

-- Rabi 2022 (Season 2)
(1, 1, 2, 5100), (2, 1, 2, 4700), (3, 1, 2, 5500),
(4, 1, 2, 4900), (5, 1, 2, 5200), (6, 1, 2, 4800),
(7, 1, 2, 5400), (8, 1, 2, 4400), (9, 1, 2, 5600),
(10, 1, 2, 5000),

-- Kharif 2023 (Season 3)
(1, 2, 3, 4500), (2, 2, 3, 4000), (3, 3, 3, 6800),
(4, 5, 3, 3600), (5, 4, 3, 7400), (6, 2, 3, 4700),
(7, 3, 3, 7000), (8, 5, 3, 3400), (9, 4, 3, 7500),
(10, 2, 3, 4900),

-- Rabi 2023 (Season 4)
(1, 1, 4, 5300), (2, 1, 4, 4900), (3, 1, 4, 5700),
(4, 1, 4, 5100), (5, 1, 4, 5400), (6, 1, 4, 5000),
(7, 1, 4, 5600), (8, 1, 4, 4700), (9, 1, 4, 5800),
(10, 1, 4, 5200),

-- Kharif 2024 (Season 5)
(1, 2, 5, 4800), (2, 2, 5, 4100), (3, 3, 5, 7000),
(4, 5, 5, 3800), (5, 4, 5, 7600), (6, 2, 5, 4950),
(7, 3, 5, 7100), (8, 5, 5, 3600), (9, 4, 5, 7700),
(10, 2, 5, 5100),

-- Rabi 2024 (Season 6)
(1, 1, 6, 5400), (2, 1, 6, 5000), (3, 1, 6, 5800),
(4, 1, 6, 5200), (5, 1, 6, 5500), (6, 1, 6, 5100),
(7, 1, 6, 5700), (8, 1, 6, 4800), (9, 1, 6, 5900),
(10, 1, 6, 5300);

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Pest Reports
-- ═══════════════════════════════════════════════════════════

INSERT INTO Pest_Report (Farmer_ID, Crop_ID, Season_ID, Pest_Type, Severity, Description) VALUES
(1, 2, 1, 'Stem Borer', 'MEDIUM', 'Moderate infestation observed in early July'),
(2, 2, 1, 'Leaf Folder', 'LOW', 'Minor damage, controlled with spraying'),
(3, 3, 1, 'Armyworm', 'HIGH', 'Severe outbreak in July, required intensive management'),
(5, 4, 1, 'Scale Insect', 'MEDIUM', 'Found on lower leaf surfaces'),
(6, 2, 3, 'Brown Spot', 'LOW', 'Minor fungal issue'),
(7, 3, 3, 'Stem Borer', 'MEDIUM', 'Mid-season infestation');

-- ═══════════════════════════════════════════════════════════
-- SEED DATA: Soil Records
-- ═══════════════════════════════════════════════════════════

INSERT INTO Soil_Record (Farmer_ID, Land_ID, Season_ID, pH_Level, Nitrogen, Phosphorus, Potassium) VALUES
(1, 1, 1, 7.2, 45.3, 18.5, 220.0),
(2, 2, 1, 6.8, 42.1, 16.2, 210.0),
(3, 3, 1, 7.5, 48.5, 20.1, 230.0),
(4, 4, 1, 6.9, 43.8, 17.3, 215.0),
(5, 5, 1, 7.3, 46.2, 19.0, 225.0),
(1, 1, 3, 7.4, 47.1, 19.2, 228.0),
(2, 2, 3, 7.0, 44.5, 17.8, 218.0),
(3, 3, 3, 7.6, 49.8, 21.3, 238.0),
(4, 4, 3, 7.1, 45.3, 18.5, 222.0),
(5, 5, 3, 7.5, 48.0, 20.5, 232.0);

-- ═══════════════════════════════════════════════════════════
-- VERIFICATION & TEST QUERIES
-- ═══════════════════════════════════════════════════════════

-- 1. Verify basic table counts
SELECT
    (SELECT COUNT(*) FROM Farmer) AS Farmer_Count,
    (SELECT COUNT(*) FROM Crop) AS Crop_Count,
    (SELECT COUNT(*) FROM Season) AS Season_Count,
    (SELECT COUNT(*) FROM Yield) AS Yield_Count,
    (SELECT COUNT(*) FROM Rainfall) AS Rainfall_Count,
    (SELECT COUNT(*) FROM Land_Record) AS Land_Count,
    (SELECT COUNT(*) FROM Pest_Report) AS Pest_Report_Count,
    (SELECT COUNT(*) FROM Soil_Record) AS Soil_Record_Count;

-- 2. Test Function: Calculate_Yield_Per_Hectare
SELECT 'Testing Calculate_Yield_Per_Hectare' AS Test;
SELECT
    f.Name AS Farmer,
    Calculate_Yield_Per_Hectare(f.Farmer_ID, 1) AS Yield_Per_Ha_Season1,
    Calculate_Yield_Per_Hectare(f.Farmer_ID, 3) AS Yield_Per_Ha_Season3
FROM Farmer f LIMIT 5;

-- 3. Test Function: Get_Rainfall_Category
SELECT 'Testing Get_Rainfall_Category' AS Test;
SELECT
    CONCAT(s.Season_Name, ' ', s.Year) AS Season,
    r.Rainfall_Amount,
    Get_Rainfall_Category(s.Season_ID) AS Category
FROM Season s LEFT JOIN Rainfall r ON s.Season_ID = r.Season_ID;

-- 4. Test Function: Get_Farmer_Total_Yield
SELECT 'Testing Get_Farmer_Total_Yield' AS Test;
SELECT
    f.Name AS Farmer,
    Get_Farmer_Total_Yield(f.Farmer_ID) AS Total_Yield,
    f.Total_Yield AS Total_Yield_From_Trigger
FROM Farmer f ORDER BY Total_Yield DESC;

-- 5. Test Function: Check_Season_Exists
SELECT 'Testing Check_Season_Exists' AS Test;
SELECT
    Check_Season_Exists('Kharif', 2024) AS Kharif_2024_Exists,
    Check_Season_Exists('Zaid', 2024) AS Zaid_2024_Exists;

-- 6. View: vw_yield_detail
SELECT 'Testing vw_yield_detail' AS Test;
SELECT Farmer, Crop, Season, Rainfall, Yield, Area_Ha, Yield_Per_Ha
FROM vw_yield_detail
LIMIT 10;

-- 7. View: vw_farmer_summary
SELECT 'Testing vw_farmer_summary' AS Test;
SELECT * FROM vw_farmer_summary
ORDER BY Total_Yield DESC;

-- 8. View: vw_season_performance
SELECT 'Testing vw_season_performance' AS Test;
SELECT * FROM vw_season_performance;

-- 9. Test Procedure: Generate_Season_Report (calling with Season 1)
SELECT 'Testing Generate_Season_Report(1)' AS Test;
CALL Generate_Season_Report(1);

-- 10. Test Procedure: Get_Analytics_Data
SELECT 'Testing Get_Analytics_Data' AS Test;
CALL Get_Analytics_Data();

-- 11. Crop production summary
SELECT 'Crop Production Summary' AS Report;
SELECT
    c.Crop_Name,
    COUNT(y.Yield_ID) AS Record_Count,
    SUM(y.Yield_Amount) AS Total_Production,
    ROUND(AVG(y.Yield_Amount), 2) AS Avg_Yield,
    MIN(y.Yield_Amount) AS Min_Yield,
    MAX(y.Yield_Amount) AS Max_Yield
FROM Crop c LEFT JOIN Yield y ON c.Crop_ID = y.Crop_ID
GROUP BY c.Crop_ID, c.Crop_Name
ORDER BY Total_Production DESC;

-- 12. Farmer yields by season
SELECT 'Farmer Yields by Season' AS Report;
SELECT
    f.Name AS Farmer,
    CONCAT(s.Season_Name, ' ', s.Year) AS Season,
    COUNT(y.Yield_ID) AS Record_Count,
    SUM(y.Yield_Amount) AS Season_Total,
    ROUND(AVG(y.Yield_Amount), 2) AS Season_Avg
FROM Farmer f
LEFT JOIN Yield y ON f.Farmer_ID = y.Farmer_ID
LEFT JOIN Season s ON y.Season_ID = s.Season_ID
GROUP BY f.Farmer_ID, f.Name, s.Season_ID, s.Season_Name, s.Year
ORDER BY f.Name, s.Year, s.Season_Name;

-- 13. Audit log inspection
SELECT 'Audit Log' AS Report;
SELECT Log_ID, Table_Name, Record_ID, Action_Type, Changed_By, Logged_At
FROM AuditLog
ORDER BY Logged_At DESC
LIMIT 20;

-- 14. Pest reports by severity
SELECT 'Pest Reports Summary' AS Report;
SELECT
    Severity,
    Pest_Type,
    COUNT(*) AS Count,
    GROUP_CONCAT(DISTINCT (SELECT Name FROM Farmer WHERE Farmer_ID = pr.Farmer_ID)) AS Affected_Farmers
FROM Pest_Report pr
GROUP BY Severity, Pest_Type
ORDER BY
    CASE Severity
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
    END;

-- 15. Soil quality analysis
SELECT 'Soil Quality Summary' AS Report;
SELECT
    f.Name AS Farmer,
    ROUND(AVG(sr.pH_Level), 2) AS Avg_pH,
    ROUND(AVG(sr.Nitrogen), 2) AS Avg_Nitrogen,
    ROUND(AVG(sr.Phosphorus), 2) AS Avg_Phosphorus,
    ROUND(AVG(sr.Potassium), 2) AS Avg_Potassium
FROM Soil_Record sr
JOIN Farmer f ON sr.Farmer_ID = f.Farmer_ID
GROUP BY f.Farmer_ID, f.Name;

-- ═══════════════════════════════════════════════════════════
-- DEMONSTRATION: Calling procedures and functions
-- ═══════════════════════════════════════════════════════════

-- Test Insert_Yield_Record (this will be used by backend)
-- Uncomment to test: CALL Insert_Yield_Record(1, 7, 6, 5100);

-- Test Update_Yield_Record
-- Uncomment to test: CALL Update_Yield_Record(1, 4250);
