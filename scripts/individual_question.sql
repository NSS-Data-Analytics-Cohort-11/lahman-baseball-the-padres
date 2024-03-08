SELECT SUM(attendance) AS total_homegame_attendance, year
FROM homegames
WHERE attendance <> 0
GROUP BY year
ORDER BY year

SELECT h.attendance, (t.w::decimal/t.g::decimal) AS win_rate, h.team
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE h.attendance <> 0
AND h.team LIKE '%BOS%'
OR h.team LIKE '%PHI%'
OR h.team LIKE '%NYA%'
OR h.team LIKE '%SLN%'
OR h.team LIKE '%LAN%'
ORDER BY h.team, h.attendance

-- LIKE ANY (h.team('%NYY%'), ('%BOS%'), ('%PHI%'))
-- AND h.team like '%NYY%' 
-- AND h.team like '%PHI%' 
-- AND h.team like '%LAN%' 
-- AND h.team like '%BOS%'
-- AND h.team like '%SLN%'

SELECT h.year, (t.w::decimal/t.g::decimal) AS win_rate
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE h.attendance <> 0
ORDER BY h.year

SELECT AVG(t.g), h.year
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE h.attendance <> 0
GROUP BY h.year
ORDER BY year

SELECT *
FROM teams
ORDER BY yearid DESC


SELECT teamid, SUM(h.attendance), yearid,
  LEAD(SUM(h.attendance), 1) OVER (
    ORDER BY 
      yearid
  ) next_year_attendance,
  LEAD(yearid, 1) OVER (
    ORDER BY 
      yearid
  ) next_year
FROM homegames h
INNER JOIN teams t
ON h.year = t.yearid
AND h.team = t.teamid
WHERE WSwin ILIKE 'Y'
GROUP BY teamid, yearid
HAVING SUM(h.attendance) <> 0
ORDER BY yearid

-- SELECT teamid, SUM(h.attendance), yearid,
--   LEAD(SUM(h.attendance), 1) OVER (
--     ORDER BY 
--       yearid
--   ) next_year_attendance,
--   LEAD(yearid, 1) OVER (
--     ORDER BY 
--       yearid
--   ) next_year
-- FROM homegames h
-- INNER JOIN teams t
-- ON h.year = t.yearid
-- AND h.team = t.teamid
-- WHERE divwin ILIKE 'Y'
-- OR wcwin ILIKE 'Y'
-- GROUP BY teamid, yearid
-- HAVING SUM(h.attendance) <> 0
-- ORDER BY yearid