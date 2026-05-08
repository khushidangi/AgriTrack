-- ============================================================
-- AGRITRACK: Schema Definition
-- Tables + Constraints + Indexes + AuditLog
-- ============================================================

CREATE DATABASE IF NOT EXISTS agri_db;
USE agri_db;

-- ── TABLES ──────────────────────────────────────────────────

-- Farmer master table
CREATE TABLE Farmer (
    Farmer_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Name            VARCHAR(100) NOT NULL,
    Location        VARCHAR(100),
    Contact_No      VARCHAR(15),
    Total_Yield     DECIMAL(12,2) DEFAULT 0,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_contact_len CHECK (LENGTH(Contact_No) >= 10)
);

-- Crop types
CREATE TABLE Crop (
    Crop_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Crop_Name       VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_crop_name CHECK (LENGTH(Crop_Name) > 0)
);

-- Growing seasons
CREATE TABLE Season (
    Season_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Season_Name     VARCHAR(50) NOT NULL,
    Year            INT NOT NULL,
    CONSTRAINT chk_year CHECK (Year BETWEEN 2000 AND 2100),
    CONSTRAINT uq_season_year UNIQUE (Season_Name, Year)
);

-- Land records for farmers
CREATE TABLE Land_Record (
    Land_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Farmer_ID       INT NOT NULL,
    Area_in_Hectare DECIMAL(8,2) NOT NULL,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Farmer_ID) REFERENCES Farmer(Farmer_ID) ON DELETE CASCADE,
    CONSTRAINT chk_area CHECK (Area_in_Hectare > 0)
);

-- Rainfall data per season
CREATE TABLE Rainfall (
    Rainfall_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Season_ID       INT NOT NULL,
    Rainfall_Amount DECIMAL(8,2) NOT NULL,
    Created_At      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Season_ID) REFERENCES Season(Season_ID) ON DELETE CASCADE,
    CONSTRAINT chk_rainfall CHECK (Rainfall_Amount >= 0)
);

-- Pest or disease incidents
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

-- Soil quality or analysis records
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

-- Yield records (core business data)
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

-- Audit log — captures all changes (the key difference from before)
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

-- Performance indexes on foreign keys
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

-- Composite indexes for common queries
CREATE INDEX idx_yield_farmer_season ON Yield(Farmer_ID, Season_ID);
CREATE INDEX idx_yield_crop_season ON Yield(Crop_ID, Season_ID);
CREATE INDEX idx_pest_farmer_season ON Pest_Report(Farmer_ID, Season_ID);
CREATE INDEX idx_soil_farmer_season ON Soil_Record(Farmer_ID, Season_ID);

-- Index on audit log for efficient lookups
CREATE INDEX idx_audit_table ON AuditLog(Table_Name);
CREATE INDEX idx_audit_record ON AuditLog(Record_ID);
CREATE INDEX idx_audit_logged_at ON AuditLog(Logged_At);
