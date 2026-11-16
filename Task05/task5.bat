#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите его название, год выпуска и средний рейтинг. Дополнительно добавьте столбец rank_by_avg_rating, в котором укажите ранг фильма среди всех фильмов по убыванию среднего рейтинга (фильмы с одинаковым средним рейтингом должны получить одинаковый ранг). Используйте оконную функцию RANK() или DENSE_RANK(). В результирующем наборе данных оставить 10 фильмов с наибольшим рангом."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT title, year, avg_rating, rank_by_avg_rating FROM (SELECT m.title, m.year, AVG(r.rating) AS avg_rating, RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rank_by_avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id) ORDER BY rank_by_avg_rating ASC LIMIT 10;"

echo " "
echo "2. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies. Для каждого жанра рассчитать средний рейтинг avg_rating фильмов в этом жанре. Выведите genre, avg_rating и ранг жанра по убыванию среднего рейтинга, используя оконную функцию RANK()."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, SUBSTR(genres, 1, INSTR(genres || '|', '|') - 1), SUBSTR(genres, INSTR(genres || '|', '|') + 1) FROM movies UNION ALL SELECT id, SUBSTR(rest, 1, INSTR(rest || '|', '|') - 1), SUBSTR(rest, INSTR(rest || '|', '|') + 1) FROM split_genres WHERE rest <> '') SELECT g.genre, AVG(r.rating) AS avg_rating, RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rank FROM split_genres g JOIN ratings r ON g.id = r.movie_id GROUP BY g.genre ORDER BY rank ASC;"

echo " "
echo "3. Посчитайте количество фильмов в каждом жанре. Выведите два столбца: genre и movie_count, отсортировав результат по убыванию количества фильмов."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, SUBSTR(genres, 1, INSTR(genres || '|', '|') - 1), SUBSTR(genres, INSTR(genres || '|', '|') + 1) FROM movies UNION ALL SELECT id, SUBSTR(rest, 1, INSTR(rest || '|', '|') - 1), SUBSTR(rest, INSTR(rest || '|', '|') + 1) FROM split_genres WHERE rest <> '') SELECT genre, COUNT(id) AS movie_count FROM split_genres GROUP BY genre ORDER BY movie_count DESC;"

echo " "
echo "4. Найдите жанры, в которых чаще всего оставляют теги (комментарии). Для этого подсчитайте общее количество записей в таблице tags для фильмов каждого жанра. Выведите genre, tag_count и долю этого жанра в общем числе тегов (tag_share), выраженную в процентах."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, SUBSTR(genres, 1, INSTR(genres || '|', '|') - 1), SUBSTR(genres, INSTR(genres || '|', '|') + 1) FROM movies UNION ALL SELECT id, SUBSTR(rest, 1, INSTR(rest || '|', '|') - 1), SUBSTR(rest, INSTR(rest || '|', '|') + 1) FROM split_genres WHERE rest <> ''), genre_tags AS (SELECT g.genre, COUNT(t.tag) AS tag_count FROM split_genres g JOIN tags t ON g.id = t.movie_id GROUP BY g.genre) SELECT genre, tag_count, ROUND((tag_count * 100.0 / (SELECT COUNT(*) FROM tags)), 2) AS tag_share FROM genre_tags ORDER BY tag_count DESC;"

echo " "
echo "5. Для каждого пользователя рассчитайте: общее количество выставленных оценок, средний выставленный рейтинг, дату первой и последней оценки (по полю timestamp в таблице ratings). Выведите user_id, rating_count, avg_rating, first_rating_date, last_rating_date. Отсортируйте результат по убыванию количества оценок и выведите только 10 первых строк."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(*) AS rating_count, ROUND(AVG(rating), 2) AS avg_rating, datetime(MIN(timestamp), 'unixepoch') AS first_rating_date, datetime(MAX(timestamp), 'unixepoch') AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10;"

echo " "
echo "6. Сегментируйте пользователей по типу поведения: «Комментаторы» — пользователи, у которых количество тегов (tags) больше количества оценок (ratings), «Оценщики» — наоборот, оценок больше, чем тегов, «Активные» — и оценок, и тегов ≥ 10, «Пассивные» — и оценок, и тегов < 5. Выведите user_id, общее число оценок, общее число тегов и категорию поведения. Используйте CASE."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH user_stats AS (SELECT u.user_id, COALESCE(r.rating_count, 0) AS rating_count, COALESCE(t.tag_count, 0) AS tag_count FROM (SELECT DISTINCT user_id FROM ratings UNION SELECT DISTINCT user_id FROM tags) u LEFT JOIN (SELECT user_id, COUNT(*) AS rating_count FROM ratings GROUP BY user_id) r ON u.user_id = r.user_id LEFT JOIN (SELECT user_id, COUNT(*) AS tag_count FROM tags GROUP BY user_id) t ON u.user_id = t.user_id) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Не определено' END AS category FROM user_stats;"

echo " "
echo "7. Для каждого пользователя выведите его имя и последний фильм, который он оценил (по времени из ratings.timestamp). Если пользователь не оценивал ни одного фильма, он всё равно должен быть в результате (с NULL в полях фильма). Результат: user_id, name, last_rated_movie_title, last_rating_timestamp."
echo "-------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH all_users AS (SELECT DISTINCT user_id FROM ratings UNION SELECT DISTINCT user_id FROM tags), last_rated AS (SELECT user_id, movie_id, timestamp, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY timestamp DESC) AS rn FROM ratings) SELECT au.user_id, SUBSTR(u.name, 1, INSTR(u.name || ' ', ' ') - 1) AS name, m.title AS last_rated_movie_title, datetime(lr.timestamp, 'unixepoch') AS last_rating_timestamp FROM all_users au LEFT JOIN users u ON au.user_id = u.id LEFT JOIN last_rated lr ON au.user_id = lr.user_id AND lr.rn = 1 LEFT JOIN movies m ON lr.movie_id = m.id;"