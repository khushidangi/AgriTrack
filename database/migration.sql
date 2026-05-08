-- ============================================================
-- AGRITRACK: Database Migration & Deployment Script
-- Orchestrates full setup by sourcing the 3 component files
-- Run once from the /database directory:
--   mysql -u root -p < migration.sql
-- ============================================================

-- Step 1: Clean slate
DROP DATABASE IF EXISTS agri_db;
CREATE DATABASE agri_db;
USE agri_db;

-- Step 2: Create all tables and indexes
SOURCE schema.sql;

-- Step 3: Create all PL/SQL components
SOURCE plsql_components.sql;

-- Step 4: Load seed data
SOURCE sample_data.sql;

-- ═══════════════════════════════════════════════════════════
-- STEP 5: DEPLOYMENT VERIFICATION
-- ═══════════════════════════════════════════════════════════

SELECT '=== AGRITRACK DEPLOYMENT VERIFICATION ===' AS Status;

-- Table counts
SELECT
    (SELECT COUNT(*) FROM Farmer)      AS Farmers,
    (SELECT COUNT(*) FROM Crop)        AS Crops,
    (SELECT COUNT(*) FROM Season)      AS Seasons,
    (SELECT COUNT(*) FROM Yield)       AS Yield_Records,
    (SELECT COUNT(*) FROM Rainfall)    AS Rainfall_Records,
    (SELECT COUNT(*) FROM Land_Record) AS Land_Records,
    (SELECT COUNT(*) FROM Pest_Report) AS Pest_Reports,
    (SELECT COUNT(*) FROM Soil_Record) AS Soil_Records,
    (SELECT COUNT(*) FROM AuditLog)    AS Audit_Entries;

-- Verify triggers fired (AuditLog should have entries from seed data inserts)
SELECT 'AuditLog entries after seed load:' AS Check_Label,
       COUNT(*) AS Count FROM AuditLog;

-- Verify Total_Yield on Farmer was maintained by triggers
SELECT 'Farmer Total_Yield maintained by trigger:' AS Check_Label;
SELECT Name, Total_Yield FROM Farmer ORDER BY Total_Yield DESC LIMIT 3;

-- Test each function
SELECT 'Function: Calculate_Yield_Per_Hectare(1, 1)' AS Fn_Test,
        Calculate_Yield_Per_Hectare(1, 1) AS Result;

SELECT 'Function: Get_Rainfall_Category(1)' AS Fn_Test,
        Get_Rainfall_Category(1) AS Result;

SELECT 'Function: Get_Farmer_Total_Yield(1)' AS Fn_Test,
        Get_Farmer_Total_Yield(1) AS Result;

SELECT 'Function: Check_Season_Exists(Kharif, 2024)' AS Fn_Test,
        Check_Season_Exists('Kharif', 2024) AS Result;

-- Test procedures
SELECT '=== Procedure: Generate_Season_Report(1) ===' AS Proc_Test;
CALL Generate_Season_Report(1);

SELECT '=== Procedure: Get_Analytics_Data() ===' AS Proc_Test;
CALL Get_Analytics_Data();

-- Test views
SELECT 'View: vw_yield_detail row count' AS View_Test,
        COUNT(*) AS Rows FROM vw_yield_detail;

SELECT 'View: vw_farmer_summary row count' AS View_Test,
        COUNT(*) AS Rows FROM vw_farmer_summary;

SELECT 'View: vw_season_performance row count' AS View_Test,
        COUNT(*) AS Rows FROM vw_season_performance;

SELECT '=== MIGRATION COMPLETED SUCCESSFULLY ===' AS Final_Status;