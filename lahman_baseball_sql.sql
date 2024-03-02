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
	Distinct namefirst, namelast, schoolname, SUM(distinct salary)::int::MONEY AS total_salary
FROM people p
INNER JOIN collegeplaying c
ON p.playerid = c.playerid
INNER JOIN schools sc 
ON c.schoolid = sc.schoolid
INNER JOIN salaries s
ON p.playerid = s.playerid
where schoolname = 'Vanderbilt University' 
GROUP BY namefirst,namelast,schoolname
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
 
SELECT sum(po),
 	CASE
 		WHEN pos = 'OF' THEN 'Outfield'
		WHEN POS  in ('SS','1B', '2B','3B') THEN 'Infield'
		WHEN pos  in ('P', 'C') THEN 'Battery' 
	END as fielding_position
FROM Fielding  
WHERE yearid = 2016
GROUP BY fielding_position

--Q5. Find the  average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
---   Do the same for home runs per game. Do you see any trends
/*SELECT p.avg(so), g, yearid
FROM batting b
INNER JOIN pitching p
ON b.playerid = p.playerid
WHERE yearid >= 1920
ORDER BY yearid*/


SELECT
	(yearid/10 * 10) as decade,
	ROUND(sum(SO)*1.0/SUM(g),2) as avg_strikeout,
	ROUND(sum(HR)*1.0/SUM(g),2) as avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade
	
--Q6. Find the player who had the most success stealing bases in 2016, where_success_is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted_at least_20 stolen bases. 

-- 1st attempt
SELECT 
		p.namefirst, p.playerid, p.namelast, sb,cs, ((sb/(sb+ cs)::float)*100) as success_stealing
FROM batting b
INNER JOIN people p
ON p.playerid = b.playerid
WHERE yearid = 2016 and sb + cs >=20
order by success_stealing desc

--2nd attempt, successful 
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


-- Q7 From 1970_2016, what is the largest number of wins for a team that did not win the world seies? What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for  a world series champion _ determine why this is the case.
-- Then redo your query,excluding the problem year. How often from 1970 - 2016 was it the case that a team with the most wins also won the world series?
--What percentage of the time?

SELECT * FROM teams 
--teams that did not win the world series with the largest wins.
/*SELECT 
		DISTINCT name,yearid, w,wswin
FROM teams
WHERE wswin = 'N'AND yearid BETWEEN 1970 AND 2016
ORDER BY w DESC
--ANSWER Seattle Mariners, 116 w(wins)*/
--teams that did win the world series with lowest wins
/*SELECT
		name, wswin, w, yearid
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w, wswin,yearid
ORDER BY w 
--Answer Los Angeles Dodgers, 63 w(wins)

SELECT
		name, COUNT(wswin), w, yearid
FROM teams
WHERE wswin = 'Y' AND yearid != 1981 AND yearid >=1970 AND name = 'New York Yankees'
GROUP BY name, w, wswin,yearid
ORDER BY w DESC */

-- different approach 

WITH most_wins AS
	(SELECT 
		yearid, max(w)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY  yearid
ORDER BY yearid),

---

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
		where wswin = 'N') * 100.0 / (select count(*)
									  from most_win_teams);




---Q8. Using the attendancee figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
--(where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. 
--Report the park name, team name,and average attendance. Repeat for the lowest 5 average attendance.
select * from homegames

/*--top 5 average attendance
select 
		team, p.park_name,h.park, (attendance/games) as avg_attendance
from homegames h
Inner join parks p
on h.park = p.park
where year = 2016 AND games >= 10
group by team, p.park_name, h.park, games, attendance
order by avg_attendance desc
limit 5
INNER JOIN teams t
ON t.team = 
---the lowest 5 average attendance 

bottom_avg as
	select *,(select 
		team, p.park_name,h.park, (attendance/games) as avg_attendance
from homegames h
Inner join parks p
on h.park = p.park
where year = 2016 AND games >= 10
group by team, p.park_name, h.park, games, attendance
order by avg_attendance 
limit 5)
SELECT avg_attendance
FROM */
--USING UNION
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



--Q9 Which managers have won the TSN Manager of the Year award in both the National Leauge (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.
/*select * from awardsmanagers
SELECT DISTINCT awardid from awardsmanagers
select * from managers
-- I only got the NL awards
WITH a_award As
	(SELECT 
		distinct namefirst, namelast,  a.playerid, t.teamid,  awardid,  m.lgid
FROM awardsmanagers a
INNER JOIN managers m
USING (yearid)
INNER JOIN people p
ON a.playerid = p.playerid
INNER JOIN teams t
USING (teamid)
WHERE awardid = 'TSN Manager of the Year' AND m.lgid ='AL' )
--
SELECT 
		distinct namefirst, namelast,  a.playerid, t.teamid,  awardid,  m.lgid
FROM awardsmanagers a
INNER JOIN managers m
USING (yearid)
INNER JOIN people p
ON a.playerid = p.playerid
INNER JOIN teams t
USING (teamid)
WHERE awardid = 'TSN Manager of the Year' AND m.lgid ='NL' 
---
SELECT 
		 namefirst, namelast,  a.playerid, teamid, awardid, lgid
FROM awardsmanagers a
INNER JOIN people p
ON a.playerid = p.playerid
WHERE awardid = 'TSN Manager of the Year' AND lgid = 'AL'*/



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

--Q10 Find all players who hit their career highest number of home runs in 2016
--- short code Jessica
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

--- Derek
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

								
