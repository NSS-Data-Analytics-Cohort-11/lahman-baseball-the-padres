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
	, playerid
FROM people
INNER JOIN collegeplaying
	USING (playerid)
INNER JOIN schools
	USING (schoolid)
GROUP BY namefirst
	, namelast
	, schoolname
	, playerid
HAVING schoolname LIKE '%Vanderbilt%'



