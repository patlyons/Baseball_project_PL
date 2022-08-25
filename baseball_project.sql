/*Question 1 
What range of years for baseball games played does the provided database cover? 
- 1871 -2016*/

SELECT MIN(yearid) AS mn,
		MAX(yearid) AS mn,
		MAX(yearid) -  MIN(yearid) 
FROM batting;

/*2 Find the name and height of the shortest player in the database. 
How many games did he play in? What is the name of the team for which he played?*/

-- Player and team

SELECT  p.namegiven,
		MIN(p.height),
		tf.franchname
FROM people AS p
INNER JOIN appearances as a
ON p.playerid = a.playerid
INNER JOIN teams AS t
on a.teamid = t.teamid
INNER JOIN teamsfranchises as tf
ON t.franchid = tf.franchid
GROUP BY p.namegiven, t.g, t.franchid, p.height, tf.franchname
ORDER BY p.height ASC
LIMIT 1;

-- Full Answer

WITH  smallest_player AS (SELECT playerid, namegiven, namelast, height
						 FROM people 
						 ORDER BY height
						 LIMIT 1)
SELECT teamid, namegiven, namelast, appearances.playerid,
		SUM(G_all) OVER (PARTITION BY appearances.playerid) AS games_played, HEIGHT
FROM smallest_player INNER JOIN  appearances USING (playerid);



-- Q3
/*Find all players in the database who played at Vanderbilt University. 
Create a list showing each player’s first and last names as well as the
total salary they earned in the major leagues. Sort this list in descending order
by the total salary earned. Which Vanderbilt player earned the most money in the majors? */

--step 1

SELECT *
FROM people INNER JOIN salaries USING (playerid)
			INNER JOIN  collegeplaying USING (playerid)
			INNER JOIN schools ON collegeplaying.schoolid = schools.schoolid
WHERE schools.schoolname = 'Vanderbilt University'

-- Full Answer
WITH vandy_players AS (SELECT distinct (playerid)
					   FROM collegeplaying INNER JOIN schools USING (schoolid)
					   WHERE schools.schoolname = 'Vanderbilt University'),
					   
	vandy_majors AS  (SELECT people.playerid, CONCAT(namefirst,' ', namelast) AS full_name
					  FROM people INNER JOIN vandy_players USING (playerid))

SELECT full_name, SUM(salary)::numeric::money AS  total_salary
FROM vandy_majors INNER JOIN salaries USING (playerid)
GROUP BY  full_name
ORDER BY total_salary DESC

--Q4
/*4. Using the fielding table, group players into three groups based on their position:
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups
in 2016.*/



WITH position_table AS(SELECT pos,
		  	 		PO AS sum_po,
	CASE WHEN pos = 'ss' or pos = '1B' or pos = '2B' or pos = '3B' THEN 'infield'
		 WHEN pos = 'OF' THEN 'outfield' 
		 WHEN pos = 'P' or pos = 'C' THEN 'battery' END AS position
		 	
		FROM fielding
		WHERE yearid = 2016
		ORDER BY pos)

SELECT DISTINCT(position), SUM(sum_po)
FROM position_table
WHERE position is not null
GROUP BY  position;

/*5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you
report to 2 decimal places. Do the same for home runs per game. Do you see any trendstry13?*/


SELECT CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
			WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
			WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
			WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
			WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
			WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
			WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
			WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
			WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
			END AS decade,
			ROUND((SUM(so)::decimal/(SUM(g)/2)), 2) AS avg_so,
			ROUND((SUM(hr)::decimal/(SUM(g)/2)), 2) AS avg_hr
FROM teams
WHERE yearid BETWEEN  1920 and 2009
GROUP BY decade
ORDER BY decade

-----

/* 6. Find the player who had the most success stealing bases in 2016, where __success__ 
is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either 
in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.*/

SELECT CONCAT(namefirst, ' ', namelast), ROUND(sb::decimal/(sb+cs),2) AS sb_pct
FROM batting INNER JOIN people USING(playerid)
WHERE (sb + cs) >= 20 AND yearid = 2016
ORDER BY sb_pct DESC;


--Q7

/*From 1970 – 2016, what is the largest number of wins for a team that did not win
the world series? What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion – 
determine why this is the case. 
Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
What percentage of the time?
*/

-- STEP 1 
SELECT teamid, yearid, w AS wins
FROM teams
WHERE w = (SELECT MIN(w) FROM teams WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016 AND yearid != 1981)
AND wswin ='Y' AND yearid BETWEEN 1970 and 2016
AND yearid != 1981 ;

--
WITH ws_most_w AS (SELECT yearid, MAX(w) AS most_w
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016
					GROUP BY yearid)


SELECT ROUND(COUNT(yearid)::DECIMAL/ 47, 2) AS question_pct
FROM ws_most_w INNER JOIN teams USING (yearid)
WHERE w = most_w AND wswin = 'Y';

--

WITH ws_most_w AS (SELECT yearid, MAX(w) AS most_w
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016
					GROUP BY yearid)


SELECT ROUND(AVG(CASE WHEN wswin = 'Y' THEN 1
					  WHEN wswin = 'N' THEN 0 END),2) AS question_pct	  
FROM ws_most_w INNER JOIN teams USING (yearid)
WHERE w = most_w 

------
--Q8

SELECT *
FROM homegames INNER JOIN teams ON homegames.team = teams.teamid;

--- Full Answer

(SELECT 'highest 5' AS category,
 		park_name,
		name,
		homegames.attendance/games as avg_attendance
FROM homegames
INNER JOIN  parks
		USING (park)
INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT 'lowest 5' AS category,
 		park_name,
		name,
		homegames.attendance/games as avg_attendance
FROM homegames
INNER JOIN  parks
		USING (park)
INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance ASC
LIMIT 5)
ORDER BY avg_attendance ASC ;


-- Q9

WITH ntl AS (SELECT p.namefirst as firstn, p.namelast as lastn, a.yearid as ntl_yr, a.playerid as pid
		    FROM awardsmanagers as a
		    LEFT JOIN people as p
		    ON a.playerid = p.playerid
		    WHERE a.awardid ='TSN Manager of the Year' AND a.lgid = 'NL'
			ORDER BY ntl_yr),
			
			alls AS (SELECT p.namefirst as fname, p.namelast as lname, a.yearid as al_yr, a.playerid as pid
		   			   FROM awardsmanagers as a
		    		   LEFT JOIN people as p
		    		   ON a.playerid = p.playerid
		    		   where a.awardid ='TSN Manager of the Year' AND a.lgid = 'AL'
					   ORDER BY al_yr),
					
			mg AS    (SELECT teamid AS tm, lgid, yearid, m.playerid
				    	FROM managers as m
						LEFT JOIN people as p on m.playerid = p.playerid
						ORDER BY yearid)
		 
SELECT  firstn, lastn, ntl_yr, alls.al_yr, ntl.pid, mg.tm, mgalls.tm 
FROM ntl
INNER JOIN  alls
ON ntl.pid = alls.pid
LEFT join mg on mg.playerid = ntl.pid AND mg.yearid = ntl.ntl_yr
LEFT JOIN mg AS mgalls  on mgalls.playerid = alls.pid AND mgalls.yearid = alls.al_yr
ORDER BY ntl_yr; 

--Q10

WITH max_hr AS (select playerid, MAX(hr) AS max_hr
				FROM batting
				GROUP BY playerid)
				
SELECT CONCAT(namelast, ' ', namelast), max_hr
FROM max_hr INNER JOIN people USING (playerid)
			INNER JOIN  batting USING (playerid)
WHERE yearid = 2016
AND max_hr > 0
AND hr = max_hr
AND (2016 - EXTRACT(YEAR FROM debut::date)) >= 10
ORDER BY max_hr DESC













































