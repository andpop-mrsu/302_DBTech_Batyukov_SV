import csv
import re
import os


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_SQL = os.path.join(SCRIPT_DIR, 'db_init.sql')


def esc(value):
    if value is None:
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"


def parse_title(title):
    match = re.search(r'\((\d{4})\)\s*$', title)
    if match:
        return title[:match.start()].strip(), int(match.group(1))
    return title.strip(), None


def write_inserts(f, table, columns, rows, batch_size=500):
    if not rows:
        return
    col_list = ', '.join(columns)
    for i in range(0, len(rows), batch_size):
        chunk = rows[i:i + batch_size]
        f.write(f"INSERT INTO {table} ({col_list}) VALUES\n")
        f.write(",\n".join(chunk))
        f.write(";\n\n")


def main():
    with open(OUTPUT_SQL, 'w', encoding='utf-8') as f:
        f.write("-- Автоматически сгенерированный SQL-скрипт\n")
        f.write("PRAGMA foreign_keys = OFF;\n\n")

        f.write("DROP TABLE IF EXISTS movies;\n")
        f.write("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);\n\n""")

        rows = []
        with open(os.path.join(SCRIPT_DIR, 'movies.csv'), encoding='utf-8') as csvf:
            for r in csv.DictReader(csvf):
                title, year = parse_title(r['title'])
                year_sql = 'NULL' if year is None else str(year)
                rows.append(f"({r['movieId']}, {esc(title)}, {year_sql}, {esc(r['genres'])})")
        write_inserts(f, 'movies', ['id', 'title', 'year', 'genres'], rows)

        f.write("DROP TABLE IF EXISTS ratings;\n")
        f.write("""CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);\n\n""")

        rows = []
        with open(os.path.join(SCRIPT_DIR, 'ratings.csv'), encoding='utf-8') as csvf:
            for i, r in enumerate(csv.DictReader(csvf), start=1):
                rows.append(f"({i}, {r['userId']}, {r['movieId']}, {r['rating']}, {r['timestamp']})")
        write_inserts(f, 'ratings', ['id', 'user_id', 'movie_id', 'rating', 'timestamp'], rows)

        f.write("DROP TABLE IF EXISTS tags;\n")
        f.write("""CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);\n\n""")

        rows = []
        with open(os.path.join(SCRIPT_DIR, 'tags.csv'), encoding='utf-8') as csvf:
            for i, r in enumerate(csv.DictReader(csvf), start=1):
                rows.append(f"({i}, {r['userId']}, {r['movieId']}, {esc(r['tag'])}, {r['timestamp']})")
        write_inserts(f, 'tags', ['id', 'user_id', 'movie_id', 'tag', 'timestamp'], rows)

        f.write("DROP TABLE IF EXISTS users;\n")
        f.write("""CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);\n\n""")

        rows = []
        with open(os.path.join(SCRIPT_DIR, 'users.txt'), encoding='utf-8') as usrf:
            for r in csv.reader(usrf, delimiter='|'):
                if not r or len(r) < 6:
                    continue
                user_id, name, email, gender, register_date, occupation = r[:6]
                rows.append(
                    f"({user_id}, {esc(name)}, {esc(email)}, "
                    f"{esc(gender)}, {esc(register_date)}, {esc(occupation)})"
                )
        write_inserts(f, 'users', ['id', 'name', 'email', 'gender', 'register_date', 'occupation'], rows)

    print(f"[OK] Сгенерирован {OUTPUT_SQL}")


if __name__ == '__main__':
    main()