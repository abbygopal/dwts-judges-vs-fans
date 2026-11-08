-- 01_judges_favorite.sql
-- Question 1: How often does the judges' favorite actually win the season?
--
-- Definition: the "judges' favorite" is the couple with the highest
-- season-average judge score. Steps:
--   1. weekly      : average judge score per couple per week (handles 3 vs 4 judges)
--   2. season_avgs : average of those weekly scores per couple (each week counts equally)
--   3. ranked      : rank couples within each season, 1 = highest average
-- Caveat: couples who last longer dance in later, higher-scoring weeks, which
-- boosts their average. That favors the eventual winner, so the share of
-- favorites who won is, if anything, overstated.
--
-- Result: the favorite won 14 of 34 seasons (41.2%).


-- Query A: one row per season showing the judges' favorite and whether they won
WITH weekly AS (
    SELECT couple_id, season, week, AVG(score) AS avg_score
    FROM scores
    GROUP BY couple_id, season, week
),
season_avgs AS (
    SELECT couple_id, season, AVG(avg_score) AS season_avg
    FROM weekly
    GROUP BY couple_id, season
),
ranked AS (
    SELECT
        couple_id,
        season,
        season_avg,
        RANK() OVER (PARTITION BY season ORDER BY season_avg DESC) AS judge_rank
    FROM season_avgs
)
SELECT
    r.season,
    c.celebrity_name,
    c.ballroom_partner,
    ROUND(r.season_avg, 2) AS season_avg,
    c.placement,
    CASE WHEN c.placement = 1 THEN 'Yes' ELSE 'No' END AS favorite_won,
    -- A text label for the dashboard chart "Where the judges' favorite finished".
    -- 4th-6th are grouped because each happened only once.
    CASE
        WHEN c.placement = 1 THEN '1st'
        WHEN c.placement = 2 THEN '2nd'
        WHEN c.placement = 3 THEN '3rd'
        ELSE '4th or lower'
    END AS finish_label
FROM ranked AS r
JOIN couples AS c
    ON r.couple_id = c.couple_id
WHERE r.judge_rank = 1
ORDER BY r.season;


-- Query B: summary (how many favorites won, and what percent)
WITH weekly AS (
    SELECT couple_id, season, week, AVG(score) AS avg_score
    FROM scores
    GROUP BY couple_id, season, week
),
season_avgs AS (
    SELECT couple_id, season, AVG(avg_score) AS season_avg
    FROM weekly
    GROUP BY couple_id, season
),
ranked AS (
    SELECT
        couple_id,
        season,
        season_avg,
        RANK() OVER (PARTITION BY season ORDER BY season_avg DESC) AS judge_rank
    FROM season_avgs
)
SELECT
    COUNT(*) AS seasons,
    SUM(CASE WHEN c.placement = 1 THEN 1 ELSE 0 END) AS favorite_won,
    ROUND(100.0 * SUM(CASE WHEN c.placement = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_favorite_won
FROM ranked AS r
JOIN couples AS c
    ON r.couple_id = c.couple_id
WHERE r.judge_rank = 1;
