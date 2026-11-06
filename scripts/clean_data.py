"""
clean_data.py
-------------
Reads the raw COMAP Dancing with the Stars CSV, cleans it, and saves it
into a SQLite database with two tables:

    couples : one row per celebrity + pro partner per season
    scores  : one row per couple, per week, per judge (only real scores)

How to run it (from the project folder, with the .venv active):
    py scripts/clean_data.py

Input  : data/raw/2026_MCM_Problem_C_Data.csv   (never modified)
Output : data/dwts.db                           (rebuilt every time you run it)
"""

# --- Imports: load the tools we need --------------------------------------
import sqlite3          # built into Python; lets us create/write a SQLite database
import pandas as pd     # the table library we installed from requirements.txt

# --- File locations --------------------------------------------------------
# These paths are "relative", meaning measured from the folder you run the
# script from. That's why you run it from the project folder.
RAW_CSV = "data/raw/2026_MCM_Problem_C_Data.csv"
DB_PATH = "data/dwts.db"


# =============================================================================
# STEP 1: Read the raw CSV
# =============================================================================
# pd.read_csv turns the CSV into a "DataFrame" (pandas' name for a table).
# Note: pandas automatically treats the text "N/A" as a missing value (NaN),
# so those cells are already "empty" after this line.
raw = pd.read_csv(RAW_CSV)

# Give every couple a simple ID number: 1, 2, 3, ... 421.
# We need this so the two tables can be linked back together in SQL.
raw["couple_id"] = range(1, len(raw) + 1)

# One column name has a slash in it, which is awkward to type in SQL.
# rename() changes only the column NAME; the data stays the same.
raw = raw.rename(columns={"celebrity_homecountry/region": "celebrity_homecountry"})


# =============================================================================
# STEP 2: Build the "couples" table (facts that don't change week to week)
# =============================================================================
# Double square brackets [[...]] = "give me just these columns, as a table".
couples = raw[[
    "couple_id",
    "season",
    "celebrity_name",
    "ballroom_partner",
    "celebrity_industry",
    "celebrity_homestate",      # blank for non-U.S. celebrities; we leave it blank
    "celebrity_homecountry",
    "celebrity_age_during_season",
    "results",                  # text, e.g. "1st Place", "Eliminated Week 3", "Withdrew"
    "placement",                # number: 1 = winner
]]


# =============================================================================
# STEP 3: Reshape the scores from WIDE (44 columns) to LONG (one row each)
# =============================================================================
# First, collect the names of the 44 score columns. This is a "list
# comprehension": it loops over every column name and keeps the ones that
# end with "_score" (week1_judge1_score, week1_judge2_score, ...).
score_columns = [col for col in raw.columns if col.endswith("_score")]

# pd.melt does the reshape:
#   id_vars    = columns to KEEP as identifiers on every new row
#   value_vars = the wide columns to "melt" down into rows
#   var_name   = name for the new column that holds the OLD column name
#   value_name = name for the new column that holds the score itself
scores = pd.melt(
    raw,
    id_vars=["couple_id", "season"],
    value_vars=score_columns,
    var_name="source_column",
    value_name="score",
)
# Now each row looks like:  couple_id=1, season=1, source_column="week1_judge2_score", score=8.0

# Pull the week number and judge number out of the old column name.
# The pattern r"week(\d+)_judge(\d+)" means: the text "week", then a number
# (captured), then "_judge", then another number (captured).
# \d+ = "one or more digits". The ( ) mark the parts we want to keep.
scores[["week", "judge"]] = scores["source_column"].str.extract(r"week(\d+)_judge(\d+)")

# str.extract gives back TEXT ("1", "2"...), so convert those to whole numbers.
scores["week"] = scores["week"].astype(int)
scores["judge"] = scores["judge"].astype(int)

# We no longer need the old column name, so drop it.
scores = scores.drop(columns="source_column")

rows_after_melt = len(scores)   # remember this number for the checks below


# =============================================================================
# STEP 4: Remove scores that aren't real scores
# =============================================================================
# (a) Missing values (originally "N/A"): no 4th judge that season,
#     or that week didn't happen. dropna removes rows where score is empty.
scores = scores.dropna(subset=["score"])
rows_after_dropping_missing = len(scores)

# (b) Zeros: a 0 means the couple had already been eliminated and wasn't
#     dancing. It's NOT a real score of zero. Keep only scores above 0.
#     (We checked: zeros always fill an entire week, and only come AFTER a
#     couple's last real week, so dropping them can't remove a real score.)
scores = scores[scores["score"] > 0]

# (c) Scores ABOVE 10 are kept on purpose. COMAP's problem PDF says bonus
#     points (dance-offs, etc.) were spread evenly across the judge scores in
#     some weeks, and team-dance scores were averaged with individual dances.
#     That explains values like 11.25 and decimals like 8.125 or 9.3333.
#     Bonus points counted toward the judges' total on the show, and our
#     questions compare couples WITHIN the same week, so keeping them is fair.

# Put the columns in a sensible order and sort the rows so the table is easy to read.
scores = scores[["couple_id", "season", "week", "judge", "score"]]
scores = scores.sort_values(["season", "couple_id", "week", "judge"])


# =============================================================================
# STEP 5: Save both tables into SQLite
# =============================================================================
# sqlite3.connect opens the database file, creating it if it doesn't exist.
conn = sqlite3.connect(DB_PATH)

# to_sql writes a DataFrame as a table.
#   if_exists="replace" -> if the table is already there, throw it away and
#                          rewrite it, so re-running the script is always safe.
#   index=False         -> don't save pandas' internal row numbers as a column.
couples.to_sql("couples", conn, if_exists="replace", index=False)
scores.to_sql("scores", conn, if_exists="replace", index=False)

conn.close()   # close the file properly when we're done


# =============================================================================
# STEP 6: Checks, so you can SEE that it worked
# =============================================================================
print("=== Row counts ===")
print(f"Couples in raw CSV:            {len(raw)}")
print(f"Couples saved:                 {len(couples)}")
print(f"Score rows right after melt:   {rows_after_melt}   (421 couples x 44 columns)")
print(f"  removed as missing (N/A):    {rows_after_melt - rows_after_dropping_missing}")
print(f"  removed as 0 (not dancing):  {rows_after_dropping_missing - len(scores)}")
print(f"Real score rows saved:         {len(scores)}")

print("\n=== Seasons ===")
seasons = sorted(couples["season"].unique())
print(f"Seasons present: {seasons[0]} to {seasons[-1]} ({len(seasons)} seasons)")
print("Missing season numbers:", [s for s in range(1, 35) if s not in seasons] or "none")

print("\n=== Missing values in the couples table ===")
# isna().sum() counts the empty cells in each column.
print(couples.isna().sum().to_string())

print("\n=== Score range ===")
print(f"Lowest score:  {scores['score'].min()}")
print(f"Highest score: {scores['score'].max()}")
print(f"Scores above 10 (to investigate with the PDF): {(scores['score'] > 10).sum()}")

print(f"\nSaved to {DB_PATH}")
