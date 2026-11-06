-- 02_lowest_scorer_saved.sql
-- Question 2: How often do fans save the lowest-scored couple?
-- In what % of elimination weeks was the couple with the lowest judge score
-- NOT sent home?
--
-- Steps:
--   1. weekly       : average judge score per couple per week
--   2. eliminations : the week each couple was eliminated, pulled out of the
--                     results text ("Eliminated Week 3" -> 3)
--   3. flagged      : for every couple-week, is_lowest (tied for the lowest
--                     score that week) and was_eliminated (sent home that week)
--   4. weeks        : one row per elimination week: did the lowest scorer go home?
--
-- Rules (chosen to be conservative, giving the judges the benefit of the doubt):
--   1. Only weeks where at least one couple was eliminated (264 weeks).
--      The 44 weeks with no elimination are skipped.
--   2. Double eliminations: counts as "lowest went home" if the lowest scorer
--      was ANY of the couples sent home.
--   3. Ties for lowest: counts as "lowest went home" if ANY tied couple went home.
--   4. Withdrawals are not eliminations (only "Eliminated Week N" results count).
--
-- Data note: Diana Nyad (Season 18) is listed as "Eliminated Week 2" but has
-- scores only for week 1, so she never appears as a week-2 couple. That week
-- still counts because another couple was also eliminated.
--
-- Result: the lowest scorer was saved in 139 of 264 elimination weeks (52.7%).


-- Query A: one row per elimination week (used for the dashboard and Question 3)
WITH weekly AS (
    SELECT couple_id, season, week, AVG(score) AS avg_score
    FROM scores
    GROUP BY couple_id, season, week
),
eliminations AS (
    SELECT couple_id, CAST(SUBSTR(results, 17) AS INTEGER) AS elim_week
    FROM couples
    WHERE results LIKE 'Eliminated Week %'
),
flagged AS (
    SELECT
        w.couple_id,
        w.season,
        w.week,
        CASE
            WHEN w.avg_score = MIN(w.avg_score) OVER (PARTITION BY w.season, w.week) THEN 1
            ELSE 0
        END AS is_lowest,
        CASE WHEN e.elim_week = w.week THEN 1 ELSE 0 END AS was_eliminated
    FROM weekly AS w
    LEFT JOIN eliminations AS e
        ON w.couple_id = e.couple_id
)
SELECT
    season,
    week,
    SUM(was_eliminated) AS n_eliminated,
    SUM(is_lowest)      AS n_lowest,
    MAX(CASE WHEN is_lowest = 1 AND was_eliminated = 1 THEN 1 ELSE 0 END) AS lowest_went_home
FROM flagged
GROUP BY season, week
HAVING SUM(was_eliminated) > 0
ORDER BY season, week;


-- Query B: summary (how many elimination weeks the lowest scorer survived)
WITH weekly AS (
    SELECT couple_id, season, week, AVG(score) AS avg_score
    FROM scores
    GROUP BY couple_id, season, week
),
eliminations AS (
    SELECT couple_id, CAST(SUBSTR(results, 17) AS INTEGER) AS elim_week
    FROM couples
    WHERE results LIKE 'Eliminated Week %'
),
flagged AS (
    SELECT
        w.couple_id,
        w.season,
        w.week,
        CASE
            WHEN w.avg_score = MIN(w.avg_score) OVER (PARTITION BY w.season, w.week) THEN 1
            ELSE 0
        END AS is_lowest,
        CASE WHEN e.elim_week = w.week THEN 1 ELSE 0 END AS was_eliminated
    FROM weekly AS w
    LEFT JOIN eliminations AS e
        ON w.couple_id = e.couple_id
),
weeks AS (
    SELECT
        season,
        week,
        MAX(CASE WHEN is_lowest = 1 AND was_eliminated = 1 THEN 1 ELSE 0 END) AS lowest_went_home
    FROM flagged
    GROUP BY season, week
    HAVING SUM(was_eliminated) > 0
)
SELECT
    COUNT(*) AS elimination_weeks,
    SUM(CASE WHEN lowest_went_home = 0 THEN 1 ELSE 0 END) AS lowest_saved,
    ROUND(100.0 * SUM(CASE WHEN lowest_went_home = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_lowest_saved
FROM weeks;
