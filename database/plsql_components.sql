-- ============================================================
-- AGRITRACK: PL/SQL Components
-- Functions + Procedures + Triggers
-- This is the brain of the database layer
-- ============================================================

USE agri_db;

DELIMITER $$

-- ═══════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Calculate yield per hectare for a specific farmer-season combination
CREATE FUNCTION Calculate_Yield_Per_Hectare(
    p_farmer_id INT,
    p_season_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_yield DECIMAL(10,2);
    DECLARE v_area DECIMAL(8,2);
    DECLARE v_per_hectare DECIMAL(10,2);

    -- Get total yield for farmer in that season
    SELECT COALESCE(SUM(y.Yield_Amount), 0) INTO v_yield
    FROM Yield y
    WHERE y.Farmer_ID = p_farmer_id AND y.Season_ID = p_season_id;

    -- Get land area for farmer
    SELECT COALESCE(Area_in_Hectare, 1) INTO v_area
    FROM Land_Record
    WHERE Farmer_ID = p_farmer_id
    LIMIT 1;

    -- Avoid division by zero
    IF v_area = 0 OR v_area IS NULL THEN
        SET v_per_hectare = 0;
    ELSE
        SET v_per_hectare = v_yield / v_area;
    END IF;

    RETURN ROUND(v_per_hectare, 2);
END$$

-- Categorize rainfall as LOW, MODERATE, or HIGH
CREATE FUNCTION Get_Rainfall_Category(p_season_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_rainfall DECIMAL(8,2);
    DECLARE v_category VARCHAR(20);

    SELECT COALESCE(Rainfall_Amount, 0) INTO v_rainfall
    FROM Rainfall
    WHERE Season_ID = p_season_id
    LIMIT 1;

    IF v_rainfall < 100 THEN
        SET v_category = 'LOW';
    ELSEIF v_rainfall < 300 THEN
        SET v_category = 'MODERATE';
    ELSE
        SET v_category = 'HIGH';
    END IF;

    RETURN v_category;
END$$

-- Get total cumulative yield for a farmer across all seasons
CREATE FUNCTION Get_Farmer_Total_Yield(p_farmer_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT COALESCE(SUM(Yield_Amount), 0) INTO v_total
    FROM Yield
    WHERE Farmer_ID = p_farmer_id;

    RETURN ROUND(v_total, 2);
END$$

-- Check if a season already exists
CREATE FUNCTION Check_Season_Exists(
    p_season_name VARCHAR(50),
    p_year INT
)
RETURNS BOOLEAN
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM Season
    WHERE Season_Name = p_season_name AND Year = p_year;

    RETURN v_count > 0;
END$$

-- ═══════════════════════════════════════════════════════════
-- PROCEDURES
-- ═══════════════════════════════════════════════════════════

-- Enhanced Insert Yield Record with validation and error handling
CREATE PROCEDURE Insert_Yield_Record(
    IN p_farmer_id INT,
    IN p_crop_id INT,
    IN p_season_id INT,
    IN p_yield_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_farmer_exists INT;
    DECLARE v_crop_exists INT;
    DECLARE v_season_exists INT;
    DECLARE v_yield_exists INT;

    START TRANSACTION;

    -- Validate farmer exists
    SELECT COUNT(*) INTO v_farmer_exists
    FROM Farmer WHERE Farmer_ID = p_farmer_id;

    IF v_farmer_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Farmer does not exist';
    END IF;

    -- Validate crop exists
    SELECT COUNT(*) INTO v_crop_exists
    FROM Crop WHERE Crop_ID = p_crop_id;

    IF v_crop_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Crop does not exist';
    END IF;

    -- Validate season exists
    SELECT COUNT(*) INTO v_season_exists
    FROM Season WHERE Season_ID = p_season_id;

    IF v_season_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Season does not exist';
    END IF;

    -- Check for duplicate yield (same farmer + crop + season)
    SELECT COUNT(*) INTO v_yield_exists
    FROM Yield
    WHERE Farmer_ID = p_farmer_id
      AND Crop_ID = p_crop_id
      AND Season_ID = p_season_id;

    IF v_yield_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield record already exists for this farmer-crop-season combination';
    END IF;

    -- Validate amount is non-negative
    IF p_yield_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield amount cannot be negative';
    END IF;

    -- All validations passed, insert the record
    INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount)
    VALUES (p_farmer_id, p_crop_id, p_season_id, p_yield_amount);

    COMMIT;
END$$

-- Update Yield Record with logging to AuditLog
CREATE PROCEDURE Update_Yield_Record(
    IN p_yield_id INT,
    IN p_new_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_yield_exists INT;
    DECLARE v_old_amount DECIMAL(10,2);
    DECLARE v_farmer_id INT;
    DECLARE v_crop_id INT;
    DECLARE v_season_id INT;

    START TRANSACTION;

    -- Check yield exists
    SELECT COUNT(*) INTO v_yield_exists
    FROM Yield WHERE Yield_ID = p_yield_id;

    IF v_yield_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield record does not exist';
    END IF;

    -- Validate new amount
    IF p_new_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield amount cannot be negative';
    END IF;

    -- Get current value for audit
    SELECT Yield_Amount, Farmer_ID, Crop_ID, Season_ID
    INTO v_old_amount, v_farmer_id, v_crop_id, v_season_id
    FROM Yield WHERE Yield_ID = p_yield_id;

    -- Log to AuditLog
    INSERT INTO AuditLog (
        Table_Name, Record_ID, Action_Type,
        Old_Value, New_Value, Changed_By, Logged_At
    ) VALUES (
        'Yield', p_yield_id, 'UPDATE',
        JSON_OBJECT('Yield_Amount', v_old_amount),
        JSON_OBJECT('Yield_Amount', p_new_amount),
        USER(), CURRENT_TIMESTAMP
    );

    -- Update the yield record
    UPDATE Yield
    SET Yield_Amount = p_new_amount
    WHERE Yield_ID = p_yield_id;

    COMMIT;
END$$

-- Generate Season Report with cursor — iterates through farmers with business logic
CREATE PROCEDURE Generate_Season_Report(IN p_season_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_farmer_id INT;
    DECLARE v_farmer_name VARCHAR(100);
    DECLARE v_total_yield DECIMAL(12,2);
    DECLARE v_yield_per_hectare DECIMAL(10,2);
    DECLARE v_rainfall_category VARCHAR(20);

    -- Cursor that fetches farmers with yield in the season
    DECLARE cur CURSOR FOR
        SELECT DISTINCT f.Farmer_ID, f.Name
        FROM Yield y
        JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID
        WHERE y.Season_ID = p_season_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Create temporary table for results
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_season_report (
        Farmer_ID INT,
        Farmer_Name VARCHAR(100),
        Total_Yield DECIMAL(12,2),
        Yield_Per_Hectare DECIMAL(10,2),
        Rainfall_Category VARCHAR(20)
    );

    DELETE FROM tmp_season_report;

    -- Get rainfall category for season
    SET v_rainfall_category = Get_Rainfall_Category(p_season_id);

    -- Iterate through farmers
    OPEN cur;
    farmer_loop: LOOP
        FETCH cur INTO v_farmer_id, v_farmer_name;

        IF done THEN LEAVE farmer_loop; END IF;

        -- Call functions inside the loop
        SELECT Get_Farmer_Total_Yield(v_farmer_id) INTO v_total_yield;
        SELECT Calculate_Yield_Per_Hectare(v_farmer_id, p_season_id) INTO v_yield_per_hectare;

        -- Insert computed row into temp table
        INSERT INTO tmp_season_report
        VALUES (v_farmer_id, v_farmer_name, v_total_yield, v_yield_per_hectare, v_rainfall_category);
    END LOOP;
    CLOSE cur;

    -- Return the report
    SELECT * FROM tmp_season_report ORDER BY Total_Yield DESC;
END$$

-- Get Analytics Data — calls functions internally, returns multiple datasets
CREATE PROCEDURE Get_Analytics_Data()
BEGIN
    DECLARE v_total_farmers INT;
    DECLARE v_total_yield DECIMAL(12,2);
    DECLARE v_avg_rainfall DECIMAL(8,2);
    DECLARE v_top_farmer VARCHAR(100);
    DECLARE v_top_farmer_yield DECIMAL(12,2);
    DECLARE v_top_crop VARCHAR(100);
    DECLARE v_top_crop_total DECIMAL(12,2);

    -- Calculate metrics
    SELECT COUNT(*) INTO v_total_farmers FROM Farmer;
    SELECT COALESCE(SUM(Yield_Amount), 0) INTO v_total_yield FROM Yield;
    SELECT COALESCE(AVG(Rainfall_Amount), 0) INTO v_avg_rainfall FROM Rainfall;

    -- Get top farmer
    SELECT f.Name, COALESCE(SUM(y.Yield_Amount), 0)
    INTO v_top_farmer, v_top_farmer_yield
    FROM Farmer f LEFT JOIN Yield y ON f.Farmer_ID = y.Farmer_ID
    GROUP BY f.Farmer_ID, f.Name
    ORDER BY SUM(y.Yield_Amount) DESC
    LIMIT 1;

    -- Get top crop
    SELECT c.Crop_Name, COALESCE(SUM(y.Yield_Amount), 0)
    INTO v_top_crop, v_top_crop_total
    FROM Crop c LEFT JOIN Yield y ON c.Crop_ID = y.Crop_ID
    GROUP BY c.Crop_ID, c.Crop_Name
    ORDER BY SUM(y.Yield_Amount) DESC
    LIMIT 1;

    -- Return summary result set
    SELECT
        v_total_farmers AS Total_Farmers,
        v_total_yield AS Total_Yield,
        v_avg_rainfall AS Average_Rainfall,
        v_top_farmer AS Top_Farmer,
        v_top_farmer_yield AS Top_Farmer_Yield,
        v_top_crop AS Top_Crop,
        v_top_crop_total AS Top_Crop_Total;

    -- Additional: Seasonal comparison
    SELECT CONCAT(s.Season_Name, ' ', s.Year) AS Season,
           SUM(y.Yield_Amount) AS Total_Yield,
           COALESCE(r.Rainfall_Amount, 0) AS Rainfall,
           Get_Rainfall_Category(s.Season_ID) AS Rainfall_Category
    FROM Season s
    LEFT JOIN Yield y ON s.Season_ID = y.Season_ID
    LEFT JOIN Rainfall r ON s.Season_ID = r.Season_ID
    GROUP BY s.Season_ID, s.Season_Name, s.Year, r.Rainfall_Amount
    ORDER BY s.Year, s.Season_Name;
END$$

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS — Enhanced with business logic and audit logging
-- ═══════════════════════════════════════════════════════════

-- BEFORE INSERT on Season: Check for duplicate season
CREATE TRIGGER trg_season_insert_check_duplicate
BEFORE INSERT ON Season FOR EACH ROW
BEGIN
    DECLARE v_exists INT;

    SELECT COUNT(*) INTO v_exists
    FROM Season
    WHERE Season_Name = NEW.Season_Name AND Year = NEW.Year;

    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Season already exists for this year';
    END IF;
END$$

-- BEFORE INSERT on Yield: Validate non-negative
CREATE TRIGGER trg_yield_insert_validate
BEFORE INSERT ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield cannot be negative';
    END IF;
END$$

-- BEFORE UPDATE on Yield: Validate non-negative
CREATE TRIGGER trg_yield_update_validate
BEFORE UPDATE ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Yield cannot be negative';
    END IF;
END$$

-- AFTER INSERT on Yield: Update farmer total_yield and log to audit
CREATE TRIGGER trg_yield_insert_update_total
AFTER INSERT ON Yield FOR EACH ROW
BEGIN
    -- Update farmer total yield
    UPDATE Farmer
    SET Total_Yield = Total_Yield + NEW.Yield_Amount
    WHERE Farmer_ID = NEW.Farmer_ID;

    -- Log to audit
    INSERT INTO AuditLog (Table_Name, Record_ID, Action_Type, New_Value, Changed_By, Logged_At)
    VALUES ('Yield', NEW.Yield_ID, 'INSERT',
            JSON_OBJECT('Farmer_ID', NEW.Farmer_ID, 'Crop_ID', NEW.Crop_ID,
                        'Season_ID', NEW.Season_ID, 'Yield_Amount', NEW.Yield_Amount),
            USER(), CURRENT_TIMESTAMP);
END$$

-- AFTER UPDATE on Yield: Update farmer total_yield and log difference
CREATE TRIGGER trg_yield_update_log_audit
AFTER UPDATE ON Yield FOR EACH ROW
BEGIN
    DECLARE v_difference DECIMAL(10,2);
    SET v_difference = NEW.Yield_Amount - OLD.Yield_Amount;

    -- Update farmer total yield
    UPDATE Farmer
    SET Total_Yield = Total_Yield + v_difference
    WHERE Farmer_ID = NEW.Farmer_ID;

    -- Log to audit
    INSERT INTO AuditLog (Table_Name, Record_ID, Action_Type, Old_Value, New_Value, Changed_By, Logged_At)
    VALUES ('Yield', NEW.Yield_ID, 'UPDATE',
            JSON_OBJECT('Yield_Amount', OLD.Yield_Amount),
            JSON_OBJECT('Yield_Amount', NEW.Yield_Amount),
            USER(), CURRENT_TIMESTAMP);
END$$

-- BEFORE INSERT on Rainfall: Validate non-negative
CREATE TRIGGER trg_rainfall_insert_validate
BEFORE INSERT ON Rainfall FOR EACH ROW
BEGIN
    IF NEW.Rainfall_Amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rainfall cannot be negative';
    END IF;
END$$

-- BEFORE DELETE on Farmer: Prevent if farmer has yield records
CREATE TRIGGER trg_farmer_delete_prevent
BEFORE DELETE ON Farmer FOR EACH ROW
BEGIN
    DECLARE v_yield_count INT;

    SELECT COUNT(*) INTO v_yield_count
    FROM Yield WHERE Farmer_ID = OLD.Farmer_ID;

    IF v_yield_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete farmer with existing yield records';
    END IF;
END$$

DELIMITER ;

-- ── VIEWS ────────────────────────────────────────────────────

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
