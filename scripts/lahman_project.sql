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

----------------------OR-------------------------
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

----------------------OR------------------------
with full_batting  as 
	(select playerid,
			sum(sb) as sb,
			sum (cs) as cs
	 from batting where yearid = 2016
	 group by playerid
	)
select namefirst || ' ' || namelast as full_name,
		sb,
		sb + cs as attempts,
		sb *100.0 / (sb +cs) as sb_pct
from full_batting
inner join people using (playerid)
where sb+cs >= 20
order by sb_pct desc;
--7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
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
									  from most_win_teams) as pct_time;
									  
					
--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
with top_5_avg as 
			(select park_name,
		  			t.name,
		  			h.attendance/games as avg_attendance
			 from homegames as h
			 inner join parks as p
			 using (park)
			 inner join teams as t
			 on h.team = t.teamid
			 and h.year = t.yearid
			 where year = 2016 and games >= 10
			 order by avg_attendance desc
			 limit 5
			),
	bot_5_avg as
			(select park_name,
	  				t.name,
	   				h.attendance/games as avg_attendance
			 from homegames as h
			 inner join parks as p
			 using (park)
			 inner join teams as t
			 on h.team = t.teamid
			 and h.year = t.yearid
			 where year = 2016 
			   and games >= 10
			 order by avg_attendance
			 limit 5
	         )
select *, 'top 5' as avg
from top_5_avg
union
select *, 'lowest 5' as avg
from bot_5_avg
order by avg_attendance desc

--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT people.namefirst, people.namelast, teams.name, teams.lgid, awardsmanagers.yearid
FROM
	(SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid IN('NL', 'AL')
	GROUP BY playerid
	HAVING COUNT(DISTINCT lgid) > 1) AS mb
INNER JOIN awardsmanagers ON mb.playerid = awardsmanagers.playerid
INNER JOIN people ON awardsmanagers.playerid = people.playerid
INNER JOIN managers ON people.playerid = managers.playerid AND awardsmanagers.yearid = managers.yearid
INNER JOIN teams ON managers.teamid = teams.teamid AND teams.yearid = managers.yearid
WHERE awardid = 'TSN Manager of the Year';

--------------------------------------OR----------------------------------------
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

--10.  Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
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

--------------------------------------OR----------------------------------------
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




