-- ============================================================
-- Crop Yield & Weather Analysis System
-- Run this entire file once in MySQL Workbench
-- ============================================================

CREATE DATABASE IF NOT EXISTS agri_db;
USE agri_db;

-- ── TABLES ──────────────────────────────────────────────────

CREATE TABLE Farmer (
    Farmer_ID  INT AUTO_INCREMENT PRIMARY KEY,
    Name       VARCHAR(100) NOT NULL,
    Location   VARCHAR(100),
    Contact_No VARCHAR(15)
);

CREATE TABLE Crop (
    Crop_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Crop_Name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Season (
    Season_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Season_Name VARCHAR(50) NOT NULL,
    Year        INT NOT NULL
);

CREATE TABLE Rainfall (
    Rainfall_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Season_ID       INT NOT NULL,
    Rainfall_Amount DECIMAL(8,2) NOT NULL CHECK (Rainfall_Amount >= 0),
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE
);

CREATE TABLE Land_Record (
    Land_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Area_in_Hectare DECIMAL(8,2) NOT NULL CHECK (Area_in_Hectare > 0),
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE
);

CREATE TABLE Yield (
    Yield_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID    INT NOT NULL,
    Crop_ID      INT NOT NULL,
    Season_ID    INT NOT NULL,
    Yield_Amount DECIMAL(10,2) NOT NULL CHECK (Yield_Amount >= 0),
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    FOREIGN KEY (Crop_ID)   REFERENCES Crop(Crop_ID)    ON DELETE CASCADE,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE
);

-- ── SEED DATA ───────────────────────────────────────────────

INSERT INTO Farmer (Name, Location, Contact_No) VALUES
('Rajinder Singh',   'Ludhiana',  '9876501001'),
('Gurpreet Kaur',    'Amritsar',  '9876501002'),
('Harjit Sandhu',    'Patiala',   '9876501003'),
('Manpreet Dhillon', 'Bathinda',  '9876501004'),
('Sukhdev Brar',     'Ferozepur', '9876501005');

INSERT INTO Crop (Crop_Name) VALUES
('Wheat'), ('Rice'), ('Maize'), ('Sugarcane'), ('Cotton');

INSERT INTO Season (Season_Name, Year) VALUES
('Kharif', 2022), ('Rabi', 2022),
('Kharif', 2023), ('Rabi', 2023),
('Kharif', 2024);

INSERT INTO Rainfall (Season_ID, Rainfall_Amount) VALUES
(1, 320.5), (2, 45.0),
(3, 410.0), (4, 38.5),
(5, 375.0);

INSERT INTO Land_Record (Farmer_ID, Area_in_Hectare) VALUES
(1, 5.0), (2, 3.5), (3, 7.2), (4, 4.8), (5, 6.1);

INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount) VALUES
(1, 2, 1, 4200), (1, 1, 2, 5100),
(2, 2, 1, 3800), (2, 1, 2, 4700),
(3, 3, 1, 6200), (3, 1, 2, 5500),
(4, 5, 1, 3300), (4, 1, 2, 4900),
(5, 4, 1, 7100), (5, 1, 2, 5200),
(1, 2, 3, 4500), (2, 2, 3, 4000),
(3, 3, 3, 6800), (4, 5, 3, 3600),
(5, 4, 3, 7400), (1, 1, 4, 5300),
(2, 1, 4, 4900), (3, 1, 4, 5700),
(4, 1, 4, 5100), (5, 1, 4, 5400),
(1, 2, 5, 4800), (2, 2, 5, 4100),
(3, 3, 5, 7000), (4, 5, 5, 3800),
(5, 4, 5, 7600);

-- ── TRIGGERS ────────────────────────────────────────────────

DELIMITER $$

CREATE TRIGGER trg_yield_insert
BEFORE INSERT ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield cannot be negative.';
    END IF;
END$$

CREATE TRIGGER trg_yield_update
BEFORE UPDATE ON Yield FOR EACH ROW
BEGIN
    IF NEW.Yield_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Yield cannot be negative.';
    END IF;
END$$

CREATE TRIGGER trg_rainfall_insert
BEFORE INSERT ON Rainfall FOR EACH ROW
BEGIN
    IF NEW.Rainfall_Amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rainfall cannot be negative.';
    END IF;
END$$

-- ── STORED PROCEDURE: Insert yield record ───────────────────

CREATE PROCEDURE InsertYield(
    IN p_farmer  INT,
    IN p_crop    INT,
    IN p_season  INT,
    IN p_amount  DECIMAL(10,2)
)
BEGIN
    START TRANSACTION;
    INSERT INTO Yield (Farmer_ID, Crop_ID, Season_ID, Yield_Amount)
    VALUES (p_farmer, p_crop, p_season, p_amount);
    COMMIT;
END$$

-- ── FUNCTION: Average yield for a crop ──────────────────────

CREATE FUNCTION AvgYield(p_crop_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(10,2);
    SELECT AVG(Yield_Amount) INTO v_avg FROM Yield WHERE Crop_ID = p_crop_id;
    RETURN IFNULL(v_avg, 0);
END$$

-- ── CURSOR PROCEDURE: Season report ─────────────────────────

CREATE PROCEDURE SeasonReport(IN p_season INT)
BEGIN
    DECLARE done    INT DEFAULT FALSE;
    DECLARE v_name  VARCHAR(100);
    DECLARE v_total DECIMAL(12,2);
    DECLARE cur CURSOR FOR
        SELECT f.Name, SUM(y.Yield_Amount)
        FROM Yield y JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID
        WHERE y.Season_ID = p_season
        GROUP BY f.Farmer_ID, f.Name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_report (
        Farmer VARCHAR(100), Total_Yield DECIMAL(12,2)
    );
    DELETE FROM tmp_report;

    OPEN cur;
    lp: LOOP
        FETCH cur INTO v_name, v_total;
        IF done THEN LEAVE lp; END IF;
        INSERT INTO tmp_report VALUES (v_name, v_total);
    END LOOP;
    CLOSE cur;

    SELECT * FROM tmp_report ORDER BY Total_Yield DESC;
END$$

DELIMITER ;

-- ── VIEWS ───────────────────────────────────────────────────

CREATE VIEW vw_yield_detail AS
    SELECT f.Name AS Farmer, c.Crop_Name AS Crop,
           CONCAT(s.Season_Name,' ',s.Year) AS Season,
           r.Rainfall_Amount AS Rainfall, y.Yield_Amount AS Yield,
           lr.Area_in_Hectare AS Area_Ha,
           ROUND(y.Yield_Amount / lr.Area_in_Hectare, 2) AS Yield_Per_Ha
    FROM Yield y
    JOIN Farmer f      ON f.Farmer_ID  = y.Farmer_ID
    JOIN Crop c        ON c.Crop_ID    = y.Crop_ID
    JOIN Season s      ON s.Season_ID  = y.Season_ID
    LEFT JOIN Rainfall r    ON r.Season_ID  = y.Season_ID
    LEFT JOIN Land_Record lr ON lr.Farmer_ID = y.Farmer_ID;

-- ── ANALYTICAL QUERIES ───────────────────────────────────────

-- Full detail
SELECT * FROM vw_yield_detail;

-- Total production per crop
SELECT c.Crop_Name, SUM(y.Yield_Amount) AS Total_Production
FROM Yield y JOIN Crop c ON c.Crop_ID = y.Crop_ID
GROUP BY c.Crop_Name ORDER BY Total_Production DESC;

-- Average rainfall per season
SELECT CONCAT(s.Season_Name,' ',s.Year) AS Season, r.Rainfall_Amount
FROM Rainfall r JOIN Season s ON s.Season_ID = r.Season_ID;

-- Highest producing farmer
SELECT f.Name, SUM(y.Yield_Amount) AS Total_Yield
FROM Yield y JOIN Farmer f ON f.Farmer_ID = y.Farmer_ID
GROUP BY f.Name ORDER BY Total_Yield DESC LIMIT 1;

-- Seasonal comparison
SELECT CONCAT(s.Season_Name,' ',s.Year) AS Season,
       SUM(y.Yield_Amount) AS Total_Yield, r.Rainfall_Amount
FROM Yield y
JOIN Season s ON s.Season_ID = y.Season_ID
LEFT JOIN Rainfall r ON r.Season_ID = y.Season_ID
GROUP BY s.Season_ID, s.Season_Name, s.Year, r.Rainfall_Amount;

-- Call procedure
CALL SeasonReport(1);

-- Use function
SELECT AvgYield(1) AS Avg_Yield_Wheat;
