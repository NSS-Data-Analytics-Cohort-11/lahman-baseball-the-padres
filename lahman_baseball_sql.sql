select * from teams
select * from people
select * from awardsplayers
select * from appearances
select * from batting
select * from appearances
select * from homegames
select distinct * from schools
select * from salaries




--Q1.What range of years for baseball games played does the provided database cover?
select 
	Min(year), Max(year), max(year) - min(year)
FROM homegames

--Q2.Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
		
SELECT min(height) 
FROM people

SELECT 
	height,namefirst, namelast, count(g_all), t.name
FROM people p 
Inner Join appearances a
ON p.playerid = a.playerid
Inner Join teams t
ON a.teamid =t.teamid
Where height = (SELECT min(height) FROM people) 
GROUP BY namefirst, namelast, height, t.name

--Q3.Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues.
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	namefirst, namelast, schoolname, SUM(salary) AS total_salary,lgid
FROM people p
INNER JOIN collegeplaying c
ON p.playerid = c.playerid
INNER JOIN schools sc 
ON c.schoolid = sc.schoolid
INNER JOIN salaries s
ON p.playerid = s.playerid
where schoolname = 'Vanderbilt University' 
GROUP BY namefirst,namelast,schoolname,lgid
ORDER BY total_salary DESC


/*SELECT 
	namefirst,namelast, sum(salary), lgid
FROM people p
INNER JOIN salaries s
ON p.playerid = s.playerid
GROUP BY namefirst, namelast, lgid*/

--Q4.Using the fielding table, group players into three groups based on their position: lable players with position OF as 'Outfield', those with position "SS","1B",
--"2B",and "3B" as "Infield" and those wih position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
 
 SELECT * 
 FROM fielding
 
SELECT COUNT(po), yearid,
 	CASE
 		WHEN pos = 'OF' THEN 'Outfield'
		WHEN POS  in ('SS','1B', '2B','3B') THEN 'Infield'
		WHEN pos  in ('P', 'C') THEN 'Battery' 
	END as fielding_position
FROM Fielding
WHERE yearid = 2016
GROUP BY POS, yearid

