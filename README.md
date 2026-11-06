# Skill vs. Popularity: Do Judges or Fans Decide *Dancing with the Stars*?

On *Dancing with the Stars*, each week's result combines the judges' scores with fan votes.
This project uses 34 U.S. seasons of judge scores to look at how often the fans override the judges.

## Questions

1. **How often does the judges' favorite actually win the season?**
2. **How often do fans save the lowest-scored couple?** In what % of weeks was the couple with the lowest judge score *not* eliminated?
3. **Which kinds of celebrities do fans save?** When a couple had the lowest judge score, how often were they saved, broken down by celebrity industry (actor, athlete, TV personality, and so on)?

*Considered and set aside:* whether the "judges' save" (Seasons 28–31, when judges picked who left from the bottom two) reduced upsets. With only 4 seasons, and no data on who was in the bottom two, the data can't answer it reliably.

## Data

- **Source:** COMAP 2026 MCM Problem C, "Data with the Stars"
  (<https://comap.org/membership/member-resources/item/data-with-the-stars>). Free to download; not re-published in this repo.
- One row per celebrity + pro partner per season: 421 couples, seasons 1–34.

## Important caveat

Fan vote totals are never released. Fan influence is **inferred** from the gap between judge scores and results, not measured directly.

<!-- Findings, dashboard, and how-to-run sections will be added as the project progresses. -->
