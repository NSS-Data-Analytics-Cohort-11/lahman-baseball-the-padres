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
		  CONCAT( p.namefirst,' ', p.namelast)
		, SUM(DISTINCT(CAST(sa.salary AS INT)::MONEY)) AS total_majors_sal
FROM people p
INNER JOIN collegeplaying c
USING (playerid)
INNER JOIN schools s
USING (schoolid)
INNER JOIN salaries sa
USING (playerid)
WHERE s.schoolname ILIKE '%Vanderbilt%'
GROUP BY p.namefirst, p.namelast
ORDER BY total_majors_sal DESC;

-- 4.

SELECT
	  SUM(po)
	, CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery'
	  END AS position
FROM fielding
WHERE yearid = '2016'
GROUP BY position;

-- 5.
		
SELECT
		  (yearid/10 * 10) AS decade
		, ROUND(SUM(SO)*1.0/SUM(g),2) AS avg_strikeouts
		, ROUND(SUM(HR)*1.0/SUM(g),2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

-- 6.

SELECT    namefirst
		, namelast
		, ROUND(sb/NULLIF((sb+cs)*1.0,0)*100,2) AS succesful_stealing
FROM batting
INNER JOIN people
USING (playerid)
WHERE sb/NULLIF((sb+cs),0)*100 IS NOT NULL
AND (sb+cs) >= 20
AND yearid = 2016
ORDER BY succesful_stealing DESC;

-- 7.


