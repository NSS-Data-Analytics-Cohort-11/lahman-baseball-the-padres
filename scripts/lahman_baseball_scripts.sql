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

