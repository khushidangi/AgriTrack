-- ============================================================
-- AGRITRACK: Database Migration & Deployment Script
-- This script orchestrates the full database setup
-- Run this once to initialize the entire database from scratch
-- ============================================================

-- Step 1: Drop existing database (clean slate for deployment)
DROP DATABASE IF EXISTS agri_db;
COMMIT;

-- Step 2: Source schema.sql (creates database and all tables)
-- Note: In production, source this from the file path
-- SOURCE schema.sql;

-- For now, inline the critical structure
CREATE DATABASE IF NOT EXISTS agri_db;
USE agri_db;

-- ── TABLES ──────────────────────────────────────────────────
CREATE TABLE Farmer (
    Farmer_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Name            VARCHAR(100) NOT NULL,
    Location        VARCHAR(100),
    Contact_No      VARCHAR(15),
    Total_Yield     DECIMAL(12,2) DEFAULT 0,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_contact_len CHECK (LENGTH(Contact_No) >= 10)
);

CREATE TABLE Crop (
    Crop_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Crop_Name       VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_crop_name CHECK (LENGTH(Crop_Name) > 0)
);

CREATE TABLE Season (
    Season_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Season_Name     VARCHAR(50) NOT NULL,
    Year            INT NOT NULL,
    CONSTRAINT chk_year CHECK (Year BETWEEN 2000 AND 2100),
    CONSTRAINT uq_season_year UNIQUE (Season_Name, Year)
);

CREATE TABLE Land_Record (
    Land_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Area_in_Hectare DECIMAL(8,2) NOT NULL,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    CONSTRAINT chk_area CHECK (Area_in_Hectare > 0)
);

CREATE TABLE Rainfall (
    Rainfall_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Season_ID       INT NOT NULL,
    Rainfall_Amount DECIMAL(8,2) NOT NULL,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE,
    CONSTRAINT chk_rainfall CHECK (Rainfall_Amount >= 0)
);

CREATE TABLE Pest_Report (
    Report_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Crop_ID         INT NOT NULL,
    Season_ID       INT NOT NULL,
    Pest_Type       VARCHAR(100) NOT NULL,
    Severity        ENUM('LOW', 'MEDIUM', 'HIGH') DEFAULT 'LOW',
    Description     TEXT,
    Reported_Date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    FOREIGN KEY (Crop_ID) REFERENCES Crop(Crop_ID) ON DELETE CASCADE,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE,
    CONSTRAINT chk_pest_type CHECK (LENGTH(Pest_Type) > 0)
);

CREATE TABLE Soil_Record (
    Soil_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Land_ID         INT NOT NULL,
    Season_ID       INT NOT NULL,
    pH_Level        DECIMAL(3,1),
    Nitrogen        DECIMAL(8,2),
    Phosphorus      DECIMAL(8,2),
    Potassium       DECIMAL(8,2),
    Recorded_Date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    FOREIGN KEY (Land_ID) REFERENCES Land_Record(Land_ID) ON DELETE CASCADE,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE,
    CONSTRAINT chk_pH CHECK (pH_Level BETWEEN 0 AND 14)
);

CREATE TABLE Yield (
    Yield_ID        INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Crop_ID         INT NOT NULL,
    Season_ID       INT NOT NULL,
    Yield_Amount    DECIMAL(10,2) NOT NULL,
    Recorded_Date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    FOREIGN KEY (Crop_ID) REFERENCES Crop(Crop_ID) ON DELETE CASCADE,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE,
    CONSTRAINT uq_yield UNIQUE (Farmer_ID, Crop_ID, Season_ID),
    CONSTRAINT chk_yield CHECK (Yield_Amount >= 0)
);

CREATE TABLE AuditLog (
    Log_ID          INT AUTO_INCREMENT PRIMARY KEY,
    Table_Name      VARCHAR(50) NOT NULL,
    Record_ID       INT NOT NULL,
    Action_Type     ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    Old_Value       JSON,
    New_Value       JSON,
    Changed_By      VARCHAR(100),
    Logged_At       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_table_name CHECK (LENGTH(Table_Name) > 0)
);

-- ── INDEXES ─────────────────────────────────────────────────
CREATE INDEX idx_land_farmer ON Land_Record(Farmer_ID);
CREATE INDEX idx_rainfall_season ON Rainfall(Season_ID);
CREATE INDEX idx_pest_farmer ON Pest_Report(Farmer_ID);
CREATE INDEX idx_pest_crop ON Pest_Report(Crop_ID);
CREATE INDEX idx_pest_season ON Pest_Report(Season_ID);
CREATE INDEX idx_soil_farmer ON Soil_Record(Farmer_ID);
CREATE INDEX idx_soil_season ON Soil_Record(Season_ID);
CREATE INDEX idx_yield_farmer ON Yield(Farmer_ID);
CREATE INDEX idx_yield_crop ON Yield(Crop_ID);
CREATE INDEX idx_yield_season ON Yield(Season_ID);
CREATE INDEX idx_yield_farmer_season ON Yield(Farmer_ID, Season_ID);
CREATE INDEX idx_yield_crop_season ON Yield(Crop_ID, Season_ID);
CREATE INDEX idx_pest_farmer_season ON Pest_Report(Farmer_ID, Season_ID);
CREATE INDEX idx_soil_farmer_season ON Soil_Record(Farmer_ID, Season_ID);
CREATE INDEX idx_audit_table ON AuditLog(Table_Name);
CREATE INDEX idx_audit_record ON AuditLog(Record_ID);
CREATE INDEX idx_audit_logged_at ON AuditLog(Logged_At);

-- Step 3: Create Functions and Procedures
-- (These would normally be sourced from plsql_components.sql)

DELIMITER $$

-- Functions
CREATE FUNCTION Calculate_Yield_Per_Hectare(
    p_farmer_id INT, p_season_id INT
) RETURNS DECIMAL(10,2) DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_yield DECIMAL(10,2);
    DECLARE v_area DECIMAL(8,2);
    SELECT COALESCE(SUM(y.Yield_Amount), 0) INTO v_yield
    FROM Yield y WHERE y.Farmer_ID = p_farmer_id AND y.Season_ID = p_season_id;
    SELECT COALESCE(Area_in_Hectare, 1) INTO v_area
    FROM Land_Record WHERE Farmer_ID = p_farmer_id LIMIT 1;
    IF v_area = 0 OR v_area IS NULL THEN RETURN 0; 
    ELSE RETURN ROUND(v_yield / v_area, 2);
    END IF;
END$$

CREATE FUNCTION Get_Rainfall_Category(p_season_id INT)
RETURNS VARCHAR(20) DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_rainfall DECIMAL(8,2);
    SELECT COALESCE(Rainfall_Amount, 0) INTO v_rainfall
    FROM Rainfall WHERE Season_ID = p_season_id LIMIT 1;
    IF v_rainfall < 100 THEN RETURN 'LOW';
    ELSEIF v_rainfall < 300 THEN RETURN 'MODERATE';
    ELSE RETURN 'HIGH';
    END IF;
END$$

CREATE FUNCTION Get_Farmer_Total_Yield(p_farmer_id INT)
RETURNS DECIMAL(12,2) DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT COALESCE(SUM(Yield_Amount), 0) INTO v_total FROM Yield
    WHERE Farmer_ID = p_farmer_id;
    RETURN ROUND(v_total, 2);
END$$

CREATE FUNCTION Check_Season_Exists(
    p_season_name VARCHAR(50), p_year INT
) RETURNS BOOLEAN DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM Season
    WHERE Season_Name = p_season_name AND Year = p_year;
    RETURN v_count > 0;
END$$

-- Procedures
CREATE PROCEDURE Insert_Yield_Record(
    IN p_farmer_id INT, IN p_crop_id INT,
    IN p_season_id INT, IN p_yield_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_farmer_exists INT;
    DECLARE v_crop_exists INT;
    DECLARE v_season_exists INT;
    DECLARE v_yield_exists INT;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_farmer_exists FROM Farmer WHERE Farmer_ID = p_farmer_id;
    IF v_farmer_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Farmer does not exist';
    END IF;
    SELECT COUNT(*) INTO v_crop_exists FROM Crop WHERE Crop_ID = p_crop_id;
    IF v_crop_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Crop does not exist';
    END IF;
    SELECT COUNT(*) INTO v_season_exists FROM Season WHERE Season_ID = p_season_id;
    IF v_season_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Season does not exist';
    END IF;
    SELECT COUNT(*) INTO v_yield_exists FROM Yield
    WHERE Farmer_ID = p_farmer_id AND Crop_ID = p_crop_id AND Season_ID = p_season_id;
    IF v_yield_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield record already exists for this combination';
    END IF;
    IF p_yield_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield amount cannot be negative';
    END IF;
    INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount)
    VALUES (p_farmer_id, p_crop_id, p_season_id, p_yield_amount);
    COMMIT;
END$$

CREATE PROCEDURE Update_Yield_Record(
    IN p_yield_id INT, IN p_new_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_yield_exists INT;
    DECLARE v_old_amount DECIMAL(10,2);
    DECLARE v_farmer_id INT;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_yield_exists FROM Yield WHERE Yield_ID = p_yield_id;
    IF v_yield_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield record does not exist';
    END IF;
    IF p_new_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield amount cannot be negative';
    END IF;
    SELECT Yield_Amount, Farmer_ID INTO v_old_amount, v_farmer_id
    FROM Yield WHERE Yield_ID = p_yield_id;
    INSERT INTO AuditLog (Table_Name, Record_ID, Action_Type, Old_Value, New_Value, Changed_By)
    VALUES ('Yield', p_yield_id, 'UPDATE',
            JSON_OBJECT('Yield_Amount', v_old_amount),
            JSON_OBJECT('Yield_Amount', p_new_amount), USER());
    UPDATE Yield SET Yield_Amount = p_new_amount WHERE Yield_ID = p_yield_id;
    COMMIT;
END$$

CREATE PROCEDURE Generate_Season_Report(IN p_season_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_farmer_id INT;
    DECLARE v_farmer_name VARCHAR(100);
    DECLARE v_total_yield DECIMAL(12,2);
    DECLARE v_yield_per_hectare DECIMAL(10,2);
    DECLARE v_rainfall_category VARCHAR(20);
    DECLARE cur CURSOR FOR
        SELECT DISTINCT f.Farmer_ID, f.Name FROM Yield y
        JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID WHERE y.Season_ID = p_season_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_season_report (
        Farmer_ID INT, Farmer_Name VARCHAR(100), Total_Yield DECIMAL(12,2),
        Yield_Per_Hectare DECIMAL(10,2), Rainfall_Category VARCHAR(20)
    );
    DELETE FROM tmp_season_report;
    SET v_rainfall_category = Get_Rainfall_Category(p_season_id);
    OPEN cur;
    farmer_loop: LOOP
        FETCH cur INTO v_farmer_id, v_farmer_name;
        IF done THEN LEAVE farmer_loop; END IF;
        SELECT Get_Farmer_Total_Yield(v_farmer_id) INTO v_total_yield;
        SELECT Calculate_Yield_Per_Hectare(v_farmer_id, p_season_id) INTO v_yield_per_hectare;
        INSERT INTO tmp_season_report
        VALUES (v_farmer_id, v_farmer_name, v_total_yield, v_yield_per_hectare, v_rainfall_category);
    END LOOP;
    CLOSE cur;
    SELECT * FROM tmp_season_report ORDER BY Total_Yield DESC;
END$$

CREATE PROCEDURE Get_Analytics_Data()
BEGIN
    DECLARE v_total_farmers INT;
    DECLARE v_total_yield DECIMAL(12,2);
    DECLARE v_avg_rainfall DECIMAL(8,2);
    DECLARE v_top_farmer VARCHAR(100);
    DECLARE v_top_farmer_yield DECIMAL(12,2);
    DECLARE v_top_crop VARCHAR(100);
    DECLARE v_top_crop_total DECIMAL(12,2);
    SELECT COUNT(*) INTO v_total_farmers FROM Farmer;
    SELECT COALESCE(SUM(Yield_Amount), 0) INTO v_total_yield FROM Yield;
    SELECT COALESCE(AVG(Rainfall_Amount), 0) INTO v_avg_rainfall FROM Rainfall;
    SELECT f.Name, COALESCE(SUM(y.Yield_Amount), 0)
    INTO v_top_farmer, v_top_farmer_yield
    FROM Farmer f LEFT JOIN Yield y ON f.Farmer_ID = y.Farmer_ID
    GROUP BY f.Farmer_ID, f.Name ORDER BY SUM(y.Yield_Amount) DESC LIMIT 1;
    SELECT c.Crop_Name, COALESCE(SUM(y.Yield_Amount), 0)
    INTO v_top_crop, v_top_crop_total
    FROM Crop c LEFT JOIN Yield y ON c.Crop_ID = y.Crop_ID
    GROUP BY c.Crop_ID, c.Crop_Name ORDER BY SUM(y.Yield_Amount) DESC LIMIT 1;
    SELECT v_total_farmers AS Total_Farmers, v_total_yield AS Total_Yield,
           v_avg_rainfall AS Average_Rainfall, v_top_farmer AS Top_Farmer,
           v_top_farmer_yield AS Top_Farmer_Yield, v_top_crop AS Top_Crop,
           v_top_crop_total AS Top_Crop_Total;
    SELECT CONCAT(s.Season_Name, ' ', s.Year) AS Season,
           SUM(y.Yield_Amount) AS Total_Yield,
           COALESCE(r.Rainfall_Amount, 0) AS Rainfall
    FROM Season s LEFT JOIN Yield y ON s.Season_ID = y.Season_ID
    LEFT JOIN Rainfall r ON s.Season_ID = r.Season_ID
    GROUP BY s.Season_ID, s.Season_Name, s.Year, r.Rainfall_Amount
    ORDER BY s.Year, s.Season_Name;
END$$

-- Triggers
CREATE TRIGGER trg_season_insert_check_duplicate BEFORE INSERT ON Season FOR EACH ROW
BEGIN
    DECLARE v_exists INT;
    SELECT COUNT(*) INTO v_exists FROM Season
    WHERE Season_Name = NEW.Season_Name AND Year = NEW.Year;
    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Season already exists for this year';
    END IF;
END$$

CREATE TRIGGER trg_yield_insert_validate BEFORE INSERT ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield cannot be negative';
    END IF;
END$$

CREATE TRIGGER trg_yield_update_validate BEFORE UPDATE ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield cannot be negative';
    END IF;
END$$

CREATE TRIGGER trg_yield_insert_update_total AFTER INSERT ON Yield FOR EACH ROW
BEGIN
    UPDATE Farmer SET Total_Yield = Total_Yield + NEW.Yield_Amount
    WHERE Farmer_ID = NEW.Farmer_ID;
    INSERT INTO AuditLog (Table_Name, Record_ID, Action_Type, New_Value, Changed_By)
    VALUES ('Yield', NEW.Yield_ID, 'INSERT',
            JSON_OBJECT('Farmer_ID', NEW.Farmer_ID, 'Yield_Amount', NEW.Yield_Amount), USER());
END$$

CREATE TRIGGER trg_yield_update_log_audit AFTER UPDATE ON Yield FOR EACH ROW
BEGIN
    DECLARE v_difference DECIMAL(10,2);
    SET v_difference = NEW.Yield_Amount - OLD.Yield_Amount;
    UPDATE Farmer SET Total_Yield = Total_Yield + v_difference WHERE Farmer_ID = NEW.Farmer_ID;
    INSERT INTO AuditLog (Table_Name, Record_ID, Action_Type, Old_Value, New_Value, Changed_By)
    VALUES ('Yield', NEW.Yield_ID, 'UPDATE',
            JSON_OBJECT('Yield_Amount', OLD.Yield_Amount),
            JSON_OBJECT('Yield_Amount', NEW.Yield_Amount), USER());
END$$

CREATE TRIGGER trg_rainfall_insert_validate BEFORE INSERT ON Rainfall FOR EACH ROW
BEGIN
    IF NEW.Rainfall_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rainfall cannot be negative';
    END IF;
END$$

CREATE TRIGGER trg_farmer_delete_prevent BEFORE DELETE ON Farmer FOR EACH ROW
BEGIN
    DECLARE v_yield_count INT;
    SELECT COUNT(*) INTO v_yield_count FROM Yield WHERE Farmer_ID = OLD.Farmer_ID;
    IF v_yield_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete farmer with existing yield records';
    END IF;
END$$

DELIMITER ;

-- Step 4: Create Views
CREATE VIEW vw_yield_detail AS
    SELECT f.Farmer_ID, f.Name AS Farmer, c.Crop_Name AS Crop,
           CONCAT(s.Season_Name,' ',s.Year) AS Season,
           COALESCE(r.Rainfall_Amount, 0) AS Rainfall,
           y.Yield_Amount AS Yield,
           COALESCE(lr.Area_in_Hectare, 0) AS Area_Ha,
           ROUND(y.Yield_Amount / COALESCE(lr.Area_in_Hectare, 1), 2) AS Yield_Per_Ha,
           y.Recorded_Date
    FROM Yield y
    JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID
    JOIN Crop c ON c.Crop_ID = y.Crop_ID
    JOIN Season s ON s.Season_ID = y.Season_ID
    LEFT JOIN Rainfall r ON r.Season_ID = y.Season_ID
    LEFT JOIN Land_Record lr ON lr.Farmer_ID = y.Farmer_ID;

CREATE VIEW vw_farmer_summary AS
    SELECT f.Farmer_ID, f.Name, f.Location,
           COUNT(DISTINCT y.Yield_ID) AS Total_Records,
           COALESCE(SUM(y.Yield_Amount), 0) AS Total_Yield,
           ROUND(AVG(y.Yield_Amount), 2) AS Avg_Yield,
           f.Total_Yield AS Total_Yield_Maintained
    FROM Farmer f
    LEFT JOIN Yield y ON f.Farmer_ID = y.Farmer_ID
    GROUP BY f.Farmer_ID, f.Name, f.Location, f.Total_Yield;

CREATE VIEW vw_season_performance AS
    SELECT CONCAT(s.Season_Name, ' ', s.Year) AS Season,
           COUNT(DISTINCT y.Farmer_ID) AS Farmer_Count,
           COUNT(y.Yield_ID) AS Record_Count,
           SUM(y.Yield_Amount) AS Total_Yield,
           ROUND(AVG(y.Yield_Amount), 2) AS Avg_Yield,
           COALESCE(r.Rainfall_Amount, 0) AS Rainfall
    FROM Season s
    LEFT JOIN Yield y ON s.Season_ID = y.Season_ID
    LEFT JOIN Rainfall r ON s.Season_ID = r.Season_ID
    GROUP BY s.Season_ID, s.Season_Name, s.Year, r.Rainfall_Amount;

-- ═══════════════════════════════════════════════════════════
-- STEP 5: LOAD SEED DATA (from sample_data.sql)
-- ═══════════════════════════════════════════════════════════

-- Insert Farmers
INSERT INTO Farmer (Name, Location, Contact_No) VALUES
('Rajinder Singh','Ludhiana','9876501001'),
('Gurpreet Kaur','Amritsar','9876501002'),
('Harjit Sandhu','Patiala','9876501003'),
('Manpreet Dhillon','Bathinda','9876501004'),
('Sukhdev Brar','Ferozepur','9876501005'),
('Priya Sharma','Jalandhar','9876501006'),
('Vikram Patel','Kapurthala','9876501007'),
('Simran Kahal','Hisar','9876501008'),
('Rajan Mittal','Kaithal','9876501009'),
('Deepak Sharma','Sonipat','9876501010');

-- Insert Crops
INSERT INTO Crop (Crop_Name) VALUES
('Wheat'),('Rice'),('Maize'),('Sugarcane'),('Cotton'),
('Pulses'),('Soybean'),('Mustard'),('Barley'),('Oats');

-- Insert Seasons
INSERT INTO Season (Season_Name, Year) VALUES
('Kharif',2022),('Rabi',2022),
('Kharif',2023),('Rabi',2023),
('Kharif',2024),('Rabi',2024);

-- Insert Rainfall
INSERT INTO Rainfall (Season_ID, Rainfall_Amount) VALUES
(1,320.5),(2,45.0),(3,410.0),(4,38.5),(5,375.0),(6,52.3);

-- Insert Land Records
INSERT INTO Land_Record (Farmer_ID, Area_in_Hectare) VALUES
(1,5.0),(2,3.5),(3,7.2),(4,4.8),(5,6.1),
(6,4.5),(7,8.0),(8,3.2),(9,5.5),(10,6.8);

-- Insert Yield Records (first 20 to keep migration concise)
INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount) VALUES
(1,2,1,4200),(2,2,1,3800),(3,3,1,6200),(4,5,1,3300),(5,4,1,7100),
(6,2,1,4500),(7,3,1,6800),(8,5,1,3100),(9,4,1,7200),(10,2,1,4600),
(1,1,2,5100),(2,1,2,4700),(3,1,2,5500),(4,1,2,4900),(5,1,2,5200),
(6,1,2,4800),(7,1,2,5400),(8,1,2,4400),(9,1,2,5600),(10,1,2,5000);

-- ═══════════════════════════════════════════════════════════
-- STEP 6: VERIFICATION & FINAL CHECKS
-- ═══════════════════════════════════════════════════════════

SELECT '=== DEPLOYMENT VERIFICATION ===' AS Status;

-- Check table counts
SELECT
    CONCAT('Farmers: ', COUNT(*)) AS Farmer_Count
FROM Farmer;

SELECT
    CONCAT('Crops: ', COUNT(*)) AS Crop_Count
FROM Crop;

SELECT
    CONCAT('Seasons: ', COUNT(*)) AS Season_Count
FROM Season;

SELECT
    CONCAT('Yield Records: ', COUNT(*)) AS Yield_Count
FROM Yield;

-- Test functions
SELECT
    'Functions: AvgYield(1)' AS Test,
    AvgYield(1) AS Result;

SELECT
    'Functions: Get_Rainfall_Category(1)' AS Test,
    Get_Rainfall_Category(1) AS Result;

SELECT
    'Functions: Get_Farmer_Total_Yield(1)' AS Test,
    Get_Farmer_Total_Yield(1) AS Result;

-- Test views
SELECT
    'Views: vw_yield_detail' AS Test,
    COUNT(*) AS Row_Count
FROM vw_yield_detail;

SELECT
    'Views: vw_farmer_summary' AS Test,
    COUNT(*) AS Row_Count
FROM vw_farmer_summary;

SELECT '=== MIGRATION COMPLETED SUCCESSFULLY ===' AS Final_Status;
