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
		, ROUND(sb/((sb+cs)*1.0)*100,2) AS succesful_stealing
FROM batting
INNER JOIN people
USING (playerid)
WHERE (sb+cs) >= 20
AND yearid = 2016
ORDER BY succesful_stealing DESC;

-- 7.

WITH most_wins AS
	(
		SELECT
			  yearid
			, MAX(w) AS w
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016
		AND yearid <> 1980
		GROUP BY yearid
		ORDER BY yearid
	),
most_wins_by_team AS
	(
		SELECT
			  name
			, yearid
			, wswin
		FROM teams
		INNER JOIN most_wins
		USING (yearid, w)
	)

SELECT 
	(	
		SELECT
				  COUNT(*)
		FROM most_wins_by_team
		WHERE WSWin ='Y'
	)
		* 100.0 / 
	(
		SELECT
				  COUNT(*)
		FROM most_wins_by_team);

-- 8.

SELECT *, 'top_5' AS flag
FROM
	(SELECT t.name, p.park_name, h.attendance/h.games AS avg_attendance_per_game
	FROM homegames h
	INNER JOIN parks p
	USING (park)
	INNER JOIN teams t
	ON h.year = t.yearid AND h.team = t.teamid
	WHERE games >= 10
	AND year = 2016
	--GROUP BY p.park_name, h.team, t.name
	ORDER BY avg_attendance_per_game DESC
	LIMIT 5) AS top_5
UNION
	SELECT *, 'lowest_5' AS flag
	FROM
	(SELECT t.name, p.park_name, h.attendance/h.games AS avg_attendance_per_game
	FROM homegames h
	INNER JOIN parks p
	USING (park)
	INNER JOIN teams t
	ON h.year = t.yearid AND h.team = t.teamid
	WHERE games >= 10
	AND year = 2016
	--GROUP BY p.park_name, h.team, t.name
	ORDER BY avg_attendance_per_game
	LIMIT 5)
ORDER BY flag DESC, avg_attendance_per_game DESC;

-- 9.

WITH both_league_winners AS (
SELECT
	playerid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid IN ('AL', 'NL')
GROUP BY playerid
HAVING COUNT(DISTINCT lgid) =2)

SELECT 
	namefirst || ' ' || namelast AS full_name,
	yearid,
	lgid,
	name
FROM people
INNER JOIN both_league_winners
USING (playerid)
INNER JOIN awardsmanagers
USING(playerid)
INNER JOIN managers
USING(playerid, yearid, lgid)
INNER JOIN teams
USING(teamid, yearid,lgid)
WHERE awardid = 'TSN Manager of the Year'
ORDER BY full_name, yearid;

-- SELECT *
-- FROM teams
-- awardsmanagers - awardid, yearid, playerid, igid
-- people - playerid, namefirst, namelast
-- managers - yearid, playerid, teamid, igid
-- teams - yearid, igid, teamid, name

-- SELECT namefirst, namelast, name

-- FROM teams t
-- INNER JOIN managers m
-- USING (yearid, igid)
-- INNER JOIN awardsmnagers

-- 10.

SELECT
    p.namefirst || ' ' || p.namelast AS player_name,
    b.hr AS home_runs_2016
FROM batting AS b
INNER JOIN people AS p ON b.playerID = p.playerid
WHERE b.yearid = 2016
	AND hr > 0
	AND EXTRACT(YEAR FROM debut::date) <= 2016 - 9
    AND b.hr = (
        SELECT MAX(hr)
        FROM batting
        WHERE playerid = b.playerid)
ORDER BY home_runs_2016 DESC;

-- OR

WITH highest_2016 AS
				/* return playerid and number of home runs if max was in 2016 */
			(SELECT  playerid,
						/* return hr when 2016 AND player hit their max hr */
						CASE WHEN hr = MAX(hr) OVER (PARTITION BY playerid) AND yearid = 2016 THEN hr
								END AS career_highest_2016
				FROM batting
				GROUP BY playerid, hr, yearid
				ORDER BY playerid)

SELECT  p.namefirst || ' ' || p.namelast AS name,
		h.career_highest_2016 AS num_hr
FROM highest_2016 AS h
LEFT JOIN people AS p
	ON h.playerid = p.playerid
WHERE h.career_highest_2016 IS NOT NULL
	AND h.career_highest_2016 > 0
	AND DATE_PART('year', p.debut::DATE) <= 2007
ORDER BY num_hr DESC;



