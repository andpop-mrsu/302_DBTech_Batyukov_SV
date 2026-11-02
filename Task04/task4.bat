#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Вывести имена, название фильма. Первые 100 записей."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title \
FROM ratings r1 \
JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id \
JOIN users u1 ON r1.user_id = u1.id \
JOIN users u2 ON r2.user_id = u2.id \
JOIN movies m ON r1.movie_id = m.id \
LIMIT 100;"
echo "--------------------------------------------------------------------------------"

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена, оценку, дату в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH LatestRatings AS (SELECT user_id, movie_id, rating, timestamp, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY timestamp DESC) as rn FROM ratings) \
SELECT u.name, m.title, lr.rating, date(lr.timestamp, 'unixepoch') AS rating_date \
FROM LatestRatings lr \
JOIN users u ON lr.user_id = u.id \
JOIN movies m ON lr.movie_id = m.id \
WHERE lr.rn = 1 \
ORDER BY lr.timestamp DESC \
LIMIT 10;"
echo "--------------------------------------------------------------------------------"

echo "3. Вывести фильмы с максимальным и минимальным средним рейтингом. Сортировка по году и названию. Колонка 'Рекомендуем' (Да/Нет)."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH MovieAvg AS (SELECT movie_id, AVG(rating) as avg_rating FROM ratings GROUP BY movie_id), \
MaxMin AS (SELECT MAX(avg_rating) as max_avg, MIN(avg_rating) as min_avg FROM MovieAvg) \
SELECT m.title, m.year, ma.avg_rating, \
CASE WHEN ma.avg_rating = (SELECT max_avg FROM MaxMin) THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' \
FROM MovieAvg ma \
JOIN movies m ON ma.movie_id = m.id \
WHERE ma.avg_rating = (SELECT max_avg FROM MaxMin) \
OR ma.avg_rating = (SELECT min_avg FROM MaxMin) \
ORDER BY m.year, m.title;"
echo "--------------------------------------------------------------------------------"

echo "4. Вычислить количество оценок и среднюю оценку от женщин в период с 2010 по 2012 год."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.id) as ratings_count, \
AVG(r.rating) as avg_rating \
FROM ratings r \
JOIN users u ON r.user_id = u.id \
WHERE u.gender = 'female' AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2010' AND '2012';"
echo "--------------------------------------------------------------------------------"

echo "5. Список фильмов с указанием средней оценки и места в рейтинге. Сортировка по году и названию. Первые 20 записей."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH AvgRatings AS (SELECT movie_id, AVG(rating) as avg_rating FROM ratings GROUP BY movie_id) \
SELECT m.title, m.year, ar.avg_rating, RANK() OVER (ORDER BY ar.avg_rating DESC) as rank \
FROM AvgRatings ar \
JOIN movies m ON ar.movie_id = m.id \
ORDER BY m.year, m.title \
LIMIT 20;"
echo "--------------------------------------------------------------------------------"

echo "6. Вывести 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата'."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT SUBSTR(name, INSTR(name, ' ') + 1) || ' ' || \
SUBSTR(name, 1, INSTR(name, ' ') - 1) || '|' || register_date AS user_info \
FROM users \
ORDER BY register_date DESC \
LIMIT 10;"
echo "--------------------------------------------------------------------------------"

echo "7. С помощью рекурсивного CTE составить таблицу умножения от 1 до 10."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE nums(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM nums WHERE n < 10) \
SELECT a.n || 'x' || b.n || '=' || (a.n * b.n) AS multiplication \
FROM nums a \
CROSS JOIN nums b \
ORDER BY a.n, b.n;"
echo "--------------------------------------------------------------------------------"

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов (каждый жанр в отдельной строке)."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 0, INSTR(rest, '|')), \
SUBSTR(rest, INSTR(rest, '|') + 1) \
FROM split \
WHERE rest <> '') \
SELECT DISTINCT genre \
FROM split \
WHERE genre <> '';"
echo "--------------------------------------------------------------------------------"