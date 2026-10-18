#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, m.year \
FROM movies m \
JOIN ratings r ON m.id = r.movie_id \
ORDER BY m.year ASC, m.title ASC LIMIT 10;"
echo "--------------------------------------------------------------------------------"
echo " "

echo "2. Вывести список всех пользователей, фамилии которых начинаются на букву 'A'.Отсортировать по дате регистрации. Оставить первых 5."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT name, register_date \
FROM users \
WHERE SUBSTR(name, INSTR(name, ' ') + 1, 1) = 'A' \
ORDER BY register_date ASC \
LIMIT 5;"
echo "--------------------------------------------------------------------------------"
echo " "

echo "3. Написать запрос, возвращающий информацию о рейтингах в более читаемом формате: имя и фамилия эксперта, название фильма, год выпуска, оценка и дата оценки в формате ГГГГ-ММ-ДД. "
echo "Отсортировать данные по имени эксперта, затем названию фильма и оценке."
echo "В списке оставить первые 50 записей."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT users.name, movies.title, movies.year, ratings.rating, date(ratings.timestamp, 'unixepoch') AS rating_date \
FROM ratings \
JOIN users ON users.id = ratings.user_id \
JOIN movies ON movies.id = ratings.movie_id \
ORDER BY users.name ASC, movies.title ASC, ratings.rating ASC \
LIMIT 50;"
echo "--------------------------------------------------------------------------------"
echo " "

echo "4. Вывести список фильмов с указанием тегов, которые были им присвоены пользователями. Сортировать по году выпуска, затем по названию фильма, затем по тегу. В списке оставить первые 40 записей."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT movies.title, movies.year, GROUP_CONCAT(tags.tag, ', ') AS tags \
FROM movies \
JOIN tags ON movies.id = tags.movie_id \
GROUP BY movies.id \
ORDER BY movies.year ASC, movies.title ASC, tags.tag ASC \
LIMIT 40;"
echo "--------------------------------------------------------------------------------"

echo " "
echo "5. Вывести список самых свежих фильмов. В список должны войти все фильмы последнего года выпуска, имеющиеся в базе данных. Запрос должен быть универсальным (год определяется в запросе, а не задается жестко)."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT title, year \
FROM movies \
WHERE year = (SELECT MAX(year) FROM movies) \
ORDER BY title ASC;"
echo "--------------------------------------------------------------------------------"

echo ""
echo "6. Найти все комедии, выпущенные после 2000 года, которые понравились мужчинам (оценка не ниже 4.5). Для каждого фильма вывести: название, год выпуска и количество таких оценок. Результат отсортировать по году выпуска и названию фильма."
echo "--------------------------------------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT movies.title, movies.year, COUNT(ratings.id) AS good_ratings \
FROM movies \
JOIN ratings ON movies.id = ratings.movie_id \
JOIN users ON users.id = ratings.user_id \
WHERE movies.genres LIKE '%Comedy%' AND movies.year > 2000 AND users.gender = 'male' AND ratings.rating >= 4.5 \
GROUP BY movies.id \
ORDER BY movies.year ASC, movies.title ASC;"
echo "--------------------------------------------------------------------------------"

echo ""
echo "7. Провести анализ занятий (профессий) пользователей - вывести количество пользователей для каждого рода занятий. Найти самую распространенную и самую редкую профессию посетителей сайта."
echo "--------------------------------------------------------------------------------"
echo "Количество пользователей по профессиям:"
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(id) AS users_count \
FROM users \
GROUP BY occupation \
ORDER BY users_count DESC;"
echo ""
echo "Самая распространенная профессия:"
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(id) AS users_count \
FROM users \
GROUP BY occupation \
ORDER BY users_count DESC \
LIMIT 1;"
echo ""
echo "Самая редкая профессия:"
sqlite3 movies_rating.db -box -echo "SELECT occupation, COUNT(id) AS users_count \
FROM users \
GROUP BY occupation \
ORDER BY users_count ASC \
LIMIT 1;"
echo "--------------------------------------------------------------------------------"