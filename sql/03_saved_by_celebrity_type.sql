-- 03_saved_by_celebrity_type.sql
-- Question 3: Which kinds of celebrities do fans save?
-- Each time a couple had the lowest judge score in an elimination week, were
-- they saved (not sent home)? Compare that save rate across celebrity industries.
--
-- Steps (the first three are the same as Question 2):
--   1. weekly            : average judge score per couple per week
--   2. eliminations      : the week each couple was eliminated
--   3. flagged           : is_lowest and was_eliminated for every couple-week
--   4. elimination_weeks : the 264 weeks where at least one couple went home
--   5. lowest            : every time a couple was (tied for) lowest in one of
--                          those weeks: 310 appearances (ties add extra rows)
--
-- Grouping: the five industries that were the lowest scorer at least 20 times
-- get their own row. Everything else is "Other" (fewer than 20 weeks makes a
-- percentage too jumpy: one week moves it 5+ points).
--
-- Note: this counts COUPLES, while Question 2 counts WEEKS. In a tie, the
-- couple who stayed counts as saved here, so the overall save rate (184 of
-- 310, 59%) is higher than Question 2's 52.7%. Both are correct for their question.
--
-- Result: TV Personalities were saved most often (65.7%, 46 of 70) and
-- Actors/Actresses least often (55.4%, 41 of 74). The gap is about 10 points,
-- roughly 7 weeks' worth, so it's suggestive, not proof.


-- Query A: every lowest-scorer appearance, with industry (310 rows)
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
elimination_weeks AS (
    SELECT season, week
    FROM flagged
    GROUP BY season, week
    HAVING SUM(was_eliminated) > 0
),
lowest AS (
    SELECT f.couple_id, f.season, f.week, f.was_eliminated
    FROM flagged AS f
    JOIN elimination_weeks AS ew
        ON f.season = ew.season AND f.week = ew.week
    WHERE f.is_lowest = 1
)
SELECT
    l.season,
    l.week,
    c.celebrity_name,
    c.celebrity_industry,
    l.was_eliminated
FROM lowest AS l
JOIN couples AS c
    ON l.couple_id = c.couple_id
ORDER BY l.season, l.week;


-- Query B: save rate by celebrity type (6 rows)
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
elimination_weeks AS (
    SELECT season, week
    FROM flagged
    GROUP BY season, week
    HAVING SUM(was_eliminated) > 0
),
lowest AS (
    SELECT f.couple_id, f.season, f.week, f.was_eliminated
    FROM flagged AS f
    JOIN elimination_weeks AS ew
        ON f.season = ew.season AND f.week = ew.week
    WHERE f.is_lowest = 1
)
SELECT
    CASE
        WHEN c.celebrity_industry IN ('Actor/Actress', 'TV Personality', 'Athlete', 'Singer/Rapper', 'Comedian')
            THEN c.celebrity_industry
        ELSE 'Other'
    END AS industry_group,
    COUNT(*) AS times_lowest,
    SUM(CASE WHEN l.was_eliminated = 0 THEN 1 ELSE 0 END) AS times_saved,
    ROUND(100.0 * SUM(CASE WHEN l.was_eliminated = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_saved
FROM lowest AS l
JOIN couples AS c
    ON l.couple_id = c.couple_id
GROUP BY industry_group
ORDER BY pct_saved DESC;
