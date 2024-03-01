--1. What range of years for baseball games played does the provided database cover?
select max(yearid), min(yearid), (max(yearid) - min(yearid)) as range_of_years
from public.teams

--2.Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
select distinct namefirst, namelast, height, teamid, name, g_all as total_games_played
from people
inner join appearances
using (playerid)
inner join teams
using (teamid)
where teamid ilike 'sla'
order by height
limit 1

--3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
select schoolname, namefirst, namelast,  sum(distinct(cast(salary as int)::money)) as total_salary
from people
inner join collegeplaying
using (playerid)
inner join schools
using (schoolid)
inner join salaries
using (playerid)
where schoolname ilike '%anderbil%'
group by schoolname, namefirst, namelast
order by total_salary desc
------------OR-------------
WITH vandy_players AS (
	SELECT DISTINCT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy')
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


--4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
select distinct sum(po),
	case when pos ilike 'of' then 'outfield'
		 when pos IN ('SS', '1B', '2B', '3B') then 'infield'
		 when pos IN ('P', 'C') then 'battery' end as outcome
from fielding
where yearid = 2016
group by outcome

--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
select (yearid)/10*10 as decade,
	round(sum(so)*1.0/sum(g),2) as avg_strikouts,
	round(sum(hr)*1.0/sum(g),2) as avg_homeruns
from teams
where yearid >= 1920
group by decade
order by decade


--6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
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
