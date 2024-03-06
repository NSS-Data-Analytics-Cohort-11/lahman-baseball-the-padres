SELECT SUM(attendance) AS total_homegame_attendance, year
FROM homegames
WHERE attendance <> 0
GROUP BY year
ORDER BY year

SELECT h.attendance, (t.w::decimal/t.g::decimal) AS win_rate
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE h.attendance <> 0
ORDER BY h.attendance

SELECT AVG(t.g), h.year
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE h.attendance <> 0
GROUP BY h.year
ORDER BY year

SELECT *
FROM teams
ORDER BY yearid DESC

--attendance relative to max attendance for a year?