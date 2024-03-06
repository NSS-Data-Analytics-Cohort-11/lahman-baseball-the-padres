--QUESTION 1: What range of years for baseball games played does the provided database cover?--
SELECT MAX(yearid),
		MIN(yearid),
		MAX(yearid)-MIN(yearid) AS year_range
FROM teams

--ANSWER 1: 1871-2016 over 145yrs; this information can also be found in the ReadMe--

--QUESTION 2: Find the name and height of the shortest player in the database. 
-- How many games did he play in? 
--What is the name of the team for which he played?

SELECT namefirst
	, namelast
	, MIN(height) AS shortest
	, g_all
	, teamid
	, name
FROM people
INNER JOIN appearances
	USING (playerid)
INNER JOIN teams
	USING (teamid)
GROUP BY namefirst
	, namelast
	, g_all
	, teamid
	, name
ORDER BY MIN(height)
LIMIT 1;

--ANSWER 2: Eddie Gaedel, appeared in 1 game for SLA, St. Louis Browns--

--QUESTION 3: Find all players in the database who played at Vanderbilt University. 
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT namefirst
	, namelast
	, schoolname
	, SUM(distinct(CAST(salary AS int)::money))
FROM people
INNER JOIN collegeplaying
	USING (playerid)
INNER JOIN schools
	USING (schoolid)
INNER JOIN salaries
	USING (playerid)
GROUP BY namefirst
	, namelast
	, schoolname
HAVING schoolname LIKE '%Vanderbilt%'
ORDER BY SUM(distinct(CAST(salary AS int)::money)) DESC


WITH vandy_players AS (
	SELECT DISTINCT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
)
SELECT 
	namefirst || namelast AS fullname, 
	SUM(salary)::int::MONEY AS total_salary
FROM salaries
INNER JOIN vandy_players
USING(playerid)
INNER JOIN people
USING(playerid)
GROUP BY namefirst || namelast
ORDER BY total_salary DESC;

--ANSWER Q3: Run above query--one with DISTINCT SUM, one with CTE---


--QUESTION 4: Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield",
--those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(po)
	, yearid
	, CASE WHEN pos ilike 'OF' THEN 'Outfield'
	WHEN pos IN('SS','1B','2B','3B') THEN 'Infield'
	WHEN pos IN('P','C') THEN 'Battery' END AS player_position
FROM fielding
WHERE yearid = '2016'
GROUP BY player_position, yearid

--ANSWER Q4: Run query above--


--Question 5: Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

SELECT ROUND(SUM(so)*1.0/SUM(g),2) AS avg_strikeouts
	, ROUND(SUM(hr)*1.0/SUM(g),2) AS avg_homeruns
	,(yearid)/10*10 AS Decade
FROM teams
WHERE yearid >= 1920
GROUP BY Decade
ORDER BY Decade

--ANSWER Q5: steroid usage became popular in 1980s, and we see a jump in HR avg per game from 1980s to 1990s and so on
--The average strikout per game is also generally higher than the average HR per game, therefore you are more likely to strikeout than hit a HR


--QUESTION 6: Find the player who had the most success stealing bases in 2016, 
--where success is measured as the percentage of stolen base attempts which are successful.
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted at least 20 stolen bases.

-- sb/(NULLIFsb,0)+NULLIF(cs,0))*100
	

SELECT namefirst
	, namelast
	, ROUND(sb/NULLIF((sb+cs)*1.0,0)*100,2) AS successful_steals
FROM people
INNER JOIN batting
	USING (playerid)
WHERE sb/NULLIF((sb+cs),0)*11 IS NOT NULL
	AND (sb+cs) >= 20
	AND yearid = 2016
ORDER BY successful_steals DESC

--ANSWER QUESTION 6: run code above--


--QUESTION 7: From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
--What is the smallest number of wins for a team that did win the world series? 
--Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case
--Then redo your query, excluding the problem year
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
--What percentage of the time?

--MAX wins per season by a single team--
SELECT yearid
	, MAX(w)
FROM teams
WHERE yearid >= 1970
GROUP BY yearid
ORDER BY yearid

--ANSWER 7 QUERY: OPTION 1--
WITH wins_and_ws AS
					/* if a team won WS and had the most wins that year */
					(SELECT yearid,
							CASE WHEN wswin = 'Y' AND w = MAX(w) OVER(PARTITION BY yearid) THEN 1		/* INTEGER: 1=yes, 0=no */
								ELSE 0 END AS winner_and_highest
					FROM teams
					WHERE yearid >= 1970)

SELECT SUM(winner_and_highest) AS num_occurances,																/* number of times WS winner team had the most wins */
		ROUND(SUM(winner_and_highest) / COUNT(DISTINCT yearid)::NUMERIC * 100, 2) || '%' AS percent_occured		/* percentage team w/ most wins won WS */
FROM wins_and_ws;
--QUESTION 7 QUERY: OPTION 2--
with most_wins as
	(select yearid,
	 		max(w) as w
	 from teams
	 where yearid>=1970
	 group by yearid
	 order by yearid
	),
	most_win_teams as
	(select yearid,
	 		name,
	 		wswin
	 from teams
	 inner join most_wins
	 using (yearid,w)
	)
--select * from most_wins_teams
select (select count(*)
		from most_win_teams
		where wswin = 'Y') * 100.0 / (select count(*)
									  from most_win_teams);

--QUESTION 7: Why such a low number of wins in 1981?--

SELECT yearid
	, wswin
	, teamid
	, w
	, name
	, G
FROM teams
WHERE yearid >= 1970
	AND wswin = 'Y'
ORDER BY w ASC

/*SELECT yearid --- number of games per year/season per team ordered ASC (lowest number of games at the bottom)
	, teamid
	, G
FROM teams
WHERE yearid >= 1970
ORDER BY G ASC*/


--QUESTION 8: Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016
--(where average attendance is defined as total attendance divided by number of games). 
--Only consider parks where there were at least 10 games played. 
--Report the park name, team name, and average attendance. 
--Repeat for the lowest 5 average attendance.

--avg attendance = attendance/games--
avg_attendance AS
	(SELECT team
	 	,(attendance)/(games) AS attendance
		FROM homegames)
		
--top/bottom park name, team, attendance with UNION--
WITH top_5 AS
	(SELECT  p.park_name
		, t.name
		, (hg.attendance)/(hg.games) AS avg_attendance
	FROM homegames AS hg
	INNER JOIN parks AS p
		USING (park)
	INNER JOIN teams AS t
		ON hg.team = t.teamid
			AND hg.year = t.yearid
	WHERE year = 2016
		AND hg.games >= 10
	ORDER BY avg_attendance DESC
	LIMIT 5),
bottom_5 AS
	(SELECT  p.park_name
		, t.name
		, (hg.attendance)/(hg.games) AS avg_attendance
	FROM homegames AS hg
	INNER JOIN parks AS p
		USING (park)
	INNER JOIN teams AS t
		ON hg.team = t.teamid
			AND hg.year = t.yearid
	WHERE year = 2016
		AND hg.games >= 10
	ORDER BY avg_attendance ASC
	LIMIT 5)
SELECT 	*, 'top 5' AS FLAG
FROM top_5
UNION
SELECT *, 'bottom 5' AS FLAG
FROM bottom_5
ORDER BY avg_attendance DESC


--QUESTION 8: ^ Run query above--


--QUESTION 9: Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.

SELECT distinct awardid
FROM awardsmanagers
-----

WITH both_league_winners AS (
	SELECT
		playerid--, count(DISTINCT lgid)
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid IN ('AL', 'NL')
	GROUP BY playerid
	--order by COUNT(DISTINCT lgid) desc
	HAVING COUNT(DISTINCT lgid) = 2
	)
SELECT
	namefirst || ' ' || namelast AS full_name,
	yearid,
	lgid,
	name
FROM people
INNER JOIN both_league_winners
USING(playerid)
INNER JOIN awardsmanagers
USING(playerid)
INNER JOIN managers
USING(playerid, yearid, lgid)
INNER JOIN teams
USING(teamid, yearid,lgid)
WHERE awardid = 'TSN Manager of the Year'
ORDER BY full_name, yearid;

--QUESTION 10: Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.

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


/****************
--SOLO PRESENTATION WORK--
--Are left-handed pitchers more effective than right handed?
--How much more rare are left-handers than right?
-- Are left-handed pitchers more likely to win the Cy Young Award?
--Are they more likely to make it into the hall of fame?
*****************/
SELECT throws
FROM people
WHERE throws = 'R'

SELECT DISTINCT playerid
FROM people

--How much more rare are left-handers than right?--NOTE there is one switch hitter
--The CTEs below convery the varchar of Throws to integers so that they can be summed

WITH l_throw_count AS
	(SELECT DISTINCT playerid
	 	,namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'L' THEN 1 
		ELSE '0' END AS left_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
	,
r_throw_count AS
	(SELECT DISTINCT playerid
	 	, namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'R' THEN 1 
		ELSE '0' END AS right_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
SELECT SUM(left_throw_count) AS total_lefthanded
	, SUM(right_throw_count) AS total_righthanded
FROM l_throw_count AS l
INNER JOIN r_throw_count AS r
	USING (playerid)
	
-- Are left-handed pitchers more likely to win the Cy Young Award?--

WITH l_throw_count AS
	(SELECT DISTINCT playerid
	 	,namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'L' THEN 1 
		ELSE '0' END AS left_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
	,
r_throw_count AS
	(SELECT DISTINCT playerid
	 	, namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'R' THEN 1 
		ELSE '0' END AS right_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
SELECT SUM(left_throw_count) AS total_lefthanded
	, SUM(right_throw_count) AS total_righthanded
	, awardid
FROM l_throw_count AS l
INNER JOIN r_throw_count AS r
	USING (playerid)
INNER JOIN awardsplayers
	USING (playerid)
WHERE awardid = 'Cy Young Award'
GROUP BY awardid

--Are they more likely to make it into the hall of fame?--

WITH l_throw_count AS
	(SELECT DISTINCT playerid
	 	,namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'L' THEN 1 
		ELSE '0' END AS left_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
	,
r_throw_count AS
	(SELECT DISTINCT playerid
	 	, namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'R' THEN 1 
		ELSE '0' END AS right_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
SELECT SUM(left_throw_count) AS total_lefthanded
	, SUM(right_throw_count) AS total_righthanded
	, inducted
FROM l_throw_count AS l
INNER JOIN r_throw_count AS r
	USING (playerid)
INNER JOIN halloffame
	USING (playerid)
GROUP BY inducted

--Pitcher with Highest ERA--

WITH l_throw_count AS
	(SELECT DISTINCT playerid
	 	,namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'L' THEN 1 
		ELSE '0' END AS left_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
	,
r_throw_count AS
	(SELECT DISTINCT playerid
	 	, namefirst || ' ' || namelast
		,
		CASE WHEN throws = 'R' THEN 1 
		ELSE '0' END AS right_throw_count
	FROM people
	INNER JOIN fielding
	 	USING (playerid)
	WHERE pos = 'P')
SELECT MIN(ERA)
	, namefirst || ' ' || namelast
	, playerid
FROM pitching
INNER JOIN l_throw_count AS l
	USING (playerid)
INNER JOIN r_throw_count AS r
	USING (playerid)
WHERE ERA <> 0
	
SELECT *
FROM pitching
WHERE ERA = 0.31
