-- 00_data_checks.sql
-- Basic checks run after loading the data (scripts/clean_data.py).
-- The numbers should match what the Python script printed.

-- Check 1: scores table should have 9,112 rows across 34 seasons
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT season) AS num_seasons
FROM scores;

-- Check 2: couples table should have 421 rows across 34 seasons
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT season) AS num_seasons
FROM couples;
