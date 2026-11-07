"""
export_results.py
-----------------
Runs the finished SQL queries and saves each result as a CSV in outputs/,
so Power BI can load them.

How to run it (from the project folder, with the .venv active):
    py scripts/export_results.py

Input  : data/dwts.db (built by clean_data.py) and the .sql files in sql/
Output : six CSV files in outputs/ (overwritten every time you run it)

Each .sql file has sections that start with a label line like
"-- Query A: ..." and "-- Query B: ...". This script splits each file at
those labels, so the SQL lives in ONE place: if you change a query, just
re-run this script and the CSVs update.
"""

import sqlite3
import pandas as pd

DB_PATH = "data/dwts.db"

# A dictionary: each KEY is (sql file, query letter) and each VALUE is the
# name of the CSV to save that query's result as.
EXPORTS = {
    ("sql/01_judges_favorite.sql", "A"): "outputs/q1_favorite_by_season.csv",
    ("sql/01_judges_favorite.sql", "B"): "outputs/q1_summary.csv",
    ("sql/02_lowest_scorer_saved.sql", "A"): "outputs/q2_elimination_weeks.csv",
    ("sql/02_lowest_scorer_saved.sql", "B"): "outputs/q2_summary.csv",
    ("sql/03_saved_by_celebrity_type.sql", "A"): "outputs/q3_lowest_appearances.csv",
    ("sql/03_saved_by_celebrity_type.sql", "B"): "outputs/q3_saved_by_type.csv",
}


def get_query(sql_file, letter):
    """Return the SQL text of one query (A or B) from a .sql file."""
    with open(sql_file, encoding="utf-8") as f:   # open the file and read all its text
        text = f.read()

    # split() cuts the text wherever "-- Query " appears. Piece 0 is the notes
    # at the top; piece 1 starts with "A: ..."; piece 2 starts with "B: ...".
    for piece in text.split("-- Query ")[1:]:     # [1:] = skip piece 0 (the notes)
        if piece.startswith(letter + ":"):
            # Drop the rest of the label line (everything up to the first line
            # break) and keep the SQL underneath it.
            return piece.split("\n", 1)[1]

    # If we get here, the label wasn't found, so stop with a clear message.
    raise ValueError(f"Couldn't find 'Query {letter}' in {sql_file}")


conn = sqlite3.connect(DB_PATH)

# Loop over the dictionary. .items() hands back each key and value as a pair;
# the key itself is a pair too, so we unpack it into sql_file and letter.
for (sql_file, letter), csv_path in EXPORTS.items():
    query = get_query(sql_file, letter)
    result = pd.read_sql(query, conn)     # run the SQL and get the result as a table
    result.to_csv(csv_path, index=False)  # save it; index=False = no extra row-number column
    print(f"{csv_path:40} {len(result):>4} rows")   # :40 and :>4 just line the columns up

conn.close()
print("\nDone. Open these in Power BI with Get Data > Text/CSV.")
