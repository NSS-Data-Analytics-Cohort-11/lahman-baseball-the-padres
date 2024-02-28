-- 1.

SELECT 
		  MIN(year)
		, MAX(year)
		, MAX(year) - MIN(year) AS year_range
FROM homegames;

-- 2.

SELECT
		  namefirst
		, namelast
		, height
		, g_all
		, t.name
FROM people p
INNER JOIN appearances a
ON p.playerid = a.playerid
INNER JOIN teams t
ON a.teamid = t.teamid
ORDER BY height
LIMIT 1;

-- 3.

SELECT
		, players played at vandy
		, namefirst
		, namelast
		, SUM(salary) AS total_majors_sal
FROM
ORDER BY total_majors_sal