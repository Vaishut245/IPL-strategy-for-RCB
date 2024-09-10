-- SUBMISSION BY: VAISHNAVI TAWDE
-- PROJECT: IPL Strategy for RCB
-- BATCH: DATA SCIENCE COURSE MAY 2024

-- use ipl;
-- Objective Questions:
-- Question No: 1 (List the different dtypes of columns in table “ball_by_ball”)
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'ball_by_ball';


-- Question No: 2 (What is the total number of runs scored in 1st season by RCB )
SELECT SUM(bs.Runs_Scored) + SUM(er.Extra_Runs) AS Total_Runs
FROM matches m
INNER JOIN team t ON (t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2)
INNER JOIN ball_by_ball bbb ON m.Match_Id = bbb.Match_Id
INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
LEFT JOIN extra_runs er ON bbb.Match_Id = er.Match_Id AND bbb.Over_Id = er.Over_Id AND bbb.Ball_Id = er.Ball_Id
WHERE t.Team_Id = 2 
  AND m.Season_Id = 1
  AND bbb.Team_Batting = t.Team_Id;


-- Question No: 3 (How many players were more than age of 25 during season 2)
SELECT COUNT(DISTINCT p.Player_Id) AS Number_of_Players_Above_25
FROM player p
INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
INNER JOIN matches m ON pm.Match_Id = m.Match_Id
INNER JOIN season s ON m.Season_Id = s.Season_Id
WHERE s.Season_id = 2
  AND TIMESTAMPDIFF(YEAR, p.DOB, m.Match_Date) > 25;


-- Question No: 4 (How many matches did RCB win in season 1)
SELECT COUNT(*) AS RCB_Wins_Season_1
FROM matches m
INNER JOIN season s ON s.Season_Id = m.Season_Id 
INNER JOIN team t ON t.Team_Id = m.Match_Winner
WHERE Team_Name = 'Royal Challengers Bangalore' AND s.Season_Id = 1;


-- Question No: 5 (List top 10 players according to their strike rate in last 4 seasons)
SELECT p.Player_Name, SUM(bs.Runs_Scored) AS Total_runs,
	COUNT(bs.Ball_Id) AS Balls_Faced,
    (SUM(bs.Runs_Scored) / COUNT(bs.Ball_Id))*100 AS Strike_rate
FROM player p
INNER JOIN ball_by_ball bbb ON bbb.Striker = p.Player_Id
INNER JOIN matches m ON m.Match_Id = bbb.Match_Id
INNER JOIN batsman_scored bs ON bs.Match_Id = bbb.Match_Id AND bs.Over_Id = bbb.Over_Id AND bs.Ball_Id = bbb.Ball_Id
INNER JOIN season s ON s.Season_Id = m.Season_Id
WHERE s.Season_Id IN (SELECT Season_Id FROM (
    SELECT Season_Id FROM season
    ORDER BY Season_Year DESC
    LIMIT 4
) AS XYZ)
GROUP BY Player_Id, Player_Name
HAVING COUNT(bs.Ball_Id) > 0
ORDER BY Strike_rate DESC
LIMIT 10;


-- Question No: 6 (Average runs scored by each batsman considering all the seasons)
SELECT p.Player_Name, 
       AVG(bs.Runs_Scored) AS Average_Runs
FROM player p
INNER JOIN ball_by_ball bbb ON bbb.Striker = p.Player_Id
INNER JOIN batsman_scored bs ON bs.Match_Id = bbb.Match_Id 
                             AND bs.Over_Id = bbb.Over_Id 
                             AND bs.Ball_Id = bbb.Ball_Id
GROUP BY p.Player_Name
ORDER BY Average_Runs DESC;


-- Question No: 7 (Average wickets taken by each bowler considering all the seasons)
SELECT p.Player_Name, 
       COUNT(wt.Player_Out) / COUNT(DISTINCT bbb.Match_Id) AS Average_Wickets
FROM player p
INNER JOIN ball_by_ball bbb ON bbb.Bowler = p.Player_Id
INNER JOIN wicket_taken wt ON wt.Match_Id = bbb.Match_Id 
                          AND wt.Over_Id = bbb.Over_Id 
                          AND wt.Ball_Id = bbb.Ball_Id
GROUP BY p.Player_Name
ORDER BY Average_Wickets DESC;


-- Question No: 8 (Players who's average runs scored greater than overall average and who's taken wickets greater than overall average)
WITH OverallAverages AS (
    SELECT AVG(Runs_Scored) AS Overall_Avg_Runs, AVG(Wickets_Taken) AS Overall_Avg_Wickets
    FROM (
        SELECT AVG(bs.Runs_Scored) AS Runs_Scored, COUNT(wt.Player_Out) AS Wickets_Taken
        FROM player p
        LEFT JOIN ball_by_ball bbb ON p.Player_Id = bbb.Striker
        LEFT JOIN batsman_scored bs ON bs.Match_Id = bbb.Match_Id AND bs.Over_Id = bbb.Over_Id AND bs.Ball_Id = bbb.Ball_Id
        LEFT JOIN wicket_taken wt ON wt.Match_Id = bbb.Match_Id AND wt.Over_Id = bbb.Over_Id AND wt.Ball_Id = bbb.Ball_Id
        GROUP BY p.Player_Id
    ) AS PlayerAverages
)
SELECT p.Player_Name, pa.Avg_Runs, pa.Total_Wickets
FROM player p
INNER JOIN (
    SELECT p.Player_Id, AVG(bs.Runs_Scored) AS Avg_Runs, COUNT(wt.Player_Out) AS Total_Wickets
    FROM player p
    LEFT JOIN ball_by_ball bbb ON p.Player_Id = bbb.Striker
    LEFT JOIN batsman_scored bs ON bs.Match_Id = bbb.Match_Id AND bs.Over_Id = bbb.Over_Id AND bs.Ball_Id = bbb.Ball_Id
    LEFT JOIN wicket_taken wt ON wt.Match_Id = bbb.Match_Id AND wt.Over_Id = bbb.Over_Id AND wt.Ball_Id = bbb.Ball_Id
    GROUP BY p.Player_Id
) pa ON p.Player_Id = pa.Player_Id
INNER JOIN OverallAverages oa ON pa.Avg_Runs > oa.Overall_Avg_Runs AND pa.Total_Wickets > oa.Overall_Avg_Wickets;


-- Question No: 9 (Create a table rcb_record table that shows wins and losses of RCB in an individual venue)
CREATE TABLE rcb_record AS
SELECT
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE WHEN m.Match_Winner != t.Team_Id AND (m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id) THEN 1 ELSE 0 END) AS Losses
FROM matches m
INNER JOIN team t ON (t.Team_Name = 'Royal Challengers Bangalore')
INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
WHERE (m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id)
GROUP BY v.Venue_Name;

SELECT * FROM rcb_record; -- To Describe table



-- Question No: 10 (Impact of bowling style on wickets taken)
SELECT bs.Bowling_skill, COUNT(wt.Player_Out) AS Wickets_Taken
FROM player p
INNER JOIN bowling_style bs ON p.Bowling_skill = bs.Bowling_Id
INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Bowler
INNER JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
GROUP BY bs.Bowling_skill
ORDER BY Wickets_Taken DESC;



-- Question No: 11 (status for whether the performance of the team better than the previous year performance on the basis 
-- 					of number of runs scored by the team in the season and number of wickets taken)
WITH TeamPerformance AS (
  SELECT t.Team_Name, s.Season_Year, SUM(bs.Runs_Scored) AS TotalRuns, COUNT(wt.Player_Out) AS TotalWickets
  FROM team t
    INNER JOIN player_match pm ON t.Team_Id = pm.Team_Id
    INNER JOIN matches m ON pm.Match_Id = m.Match_Id
    INNER JOIN (SELECT Match_Id, SUM(Runs_Scored) AS Runs_Scored FROM batsman_scored GROUP BY Match_Id) bs ON m.Match_Id = bs.Match_Id
    INNER JOIN (SELECT Match_Id, COUNT(Player_Out) AS Player_Out FROM wicket_taken GROUP BY Match_Id) wt ON m.Match_Id = wt.Match_Id
    INNER JOIN season s ON m.Season_Id = s.Season_Id
  GROUP BY t.Team_Name, s.Season_Year)
SELECT t1.Team_Name, 
  t1.Season_Year AS Previous_Year, 
  t2.Season_Year AS Current_Year, 
  t1.TotalRuns AS Previous_Runs, 
  t2.TotalRuns AS Current_Runs, 
  t1.TotalWickets AS Previous_Wickets, 
  t2.TotalWickets AS Current_Wickets, 
  CASE 
    WHEN t2.TotalRuns > t1.TotalRuns AND t2.TotalWickets > t1.TotalWickets THEN 'Better'
    WHEN t2.TotalRuns = t1.TotalRuns AND t2.TotalWickets = t1.TotalWickets THEN 'Same'
    WHEN t2.TotalRuns > t1.TotalRuns AND t2.TotalWickets = t1.TotalWickets THEN 'Mixed'
    WHEN t2.TotalRuns = t1.TotalRuns AND t2.TotalWickets > t1.TotalWickets THEN 'Mixed'
    ELSE 'Worse'
  END AS Performance_Status
FROM TeamPerformance t1
  INNER JOIN TeamPerformance t2 ON t1.Team_Name = t2.Team_Name AND t1.Season_Year = t2.Season_Year - 1
ORDER BY t1.Team_Name, t1.Season_Year;



-- Question No: 12 (Derive more KPIs for the team strategy if possible)
-- 1.Top Order Contribution 
WITH Top_Order_Stats AS (
    SELECT m.Match_Id, t.Team_Name, SUM(bs.Runs_Scored) AS Top_Order_Runs, TotalRuns.Match_Total_Runs
    FROM matches m
    INNER JOIN ball_by_ball bbb ON m.Match_Id = bbb.Match_Id
    INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id 
        AND bbb.Over_Id = bs.Over_Id 
        AND bbb.Ball_Id = bs.Ball_Id
    INNER JOIN team t ON t.Team_Id = bbb.Team_Batting
    INNER JOIN (SELECT Match_Id, SUM(Runs_Scored) AS Match_Total_Runs FROM batsman_scored GROUP BY Match_Id) 
		AS TotalRuns ON m.Match_Id = TotalRuns.Match_Id
    WHERE bbb.Striker_Batting_Position <= 3
    GROUP BY m.Match_Id, t.Team_Name, TotalRuns.Match_Total_Runs
)
SELECT Team_Name, 
       AVG((Top_Order_Runs / Match_Total_Runs) * 100) AS Avg_Top_Order_Contribution
FROM Top_Order_Stats
GROUP BY Team_Name
ORDER BY Avg_Top_Order_Contribution DESC;


-- 2.Boundary Frequency 
SELECT p.Player_Name, 
	ROUND(SUM(CASE WHEN bs.Runs_Scored IN (4, 6) THEN 1 ELSE 0 END) / COUNT(bbb.Ball_Id) * 100, 2) AS Player_Boundary_Frequency
FROM player p
INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Striker
INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id 
	AND bbb.Innings_No = bs.Innings_No
GROUP BY p.Player_Name
ORDER BY Player_Boundary_Frequency DESC
LIMIT 10;


-- 3.Powerplay Performance 
WITH Powerplay_Data AS (
    SELECT m.Match_Id, bbb.Team_Batting, SUM(bs.Runs_Scored) AS Powerplay_Runs, COUNT(wt.Player_Out) AS Wickets_Lost
    FROM matches m
    INNER JOIN ball_by_ball bbb ON m.Match_Id = bbb.Match_Id
    INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
    LEFT JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
    WHERE bbb.Over_Id <= 6
    GROUP BY m.Match_Id, bbb.Team_Batting )
SELECT t.Team_Name, AVG(pd.Powerplay_Runs) AS Avg_Powerplay_Runs, AVG(pd.Wickets_Lost) AS Avg_Wickets_Lost,
       AVG(pd.Powerplay_Runs) - AVG(pd.Wickets_Lost) AS Run_to_Wicket_Ratio
FROM Powerplay_Data pd
INNER JOIN team t ON pd.Team_Batting = t.Team_Id
GROUP BY t.Team_Name
ORDER BY Avg_Powerplay_Runs DESC;


-- 4.Death Over Efficiency
WITH Death_Over_Player_Data AS (
    SELECT p.Player_Name, t.Team_Name, SUM(bs.Runs_Scored + COALESCE(er.Extra_Runs, 0)) AS Runs_In_Death, 
		COUNT(wt.Player_Out) AS Wickets_Taken
    FROM matches m
    INNER JOIN ball_by_ball bbb ON m.Match_Id = bbb.Match_Id
    INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
    LEFT JOIN extra_runs er ON bbb.Match_Id = er.Match_Id AND bbb.Over_Id = er.Over_Id AND bbb.Ball_Id = er.Ball_Id
    LEFT JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
    INNER JOIN player p ON p.Player_Id = bbb.Striker
    INNER JOIN team t ON t.Team_Id = bbb.Team_Batting
    WHERE bbb.Over_Id > (SELECT MAX(Over_Id) FROM ball_by_ball WHERE Match_Id = m.Match_Id) - 4
    GROUP BY p.Player_Name, t.Team_Name )
SELECT Player_Name, Team_Name, Runs_In_Death, Wickets_Taken
FROM Death_Over_Player_Data
ORDER BY Runs_In_Death DESC, Wickets_Taken DESC
LIMIT 10;


-- 5.Win/Loss Ratio by Venue
SELECT t.Team_Name,
       v.Venue_Name,
       SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Wins,
       SUM(CASE WHEN m.Match_Winner != t.Team_Id AND (m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id) THEN 1 ELSE 0 END) AS Losses,
       (SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) / COUNT(*)) AS Win_Loss_Ratio
FROM matches m
JOIN team t ON t.Team_Id IN (m.Team_1, m.Team_2)
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY t.Team_Name, v.Venue_Name
ORDER BY wins DESC, losses ASC
LIMIT 20;



-- Question No: 13 (Average wickets taken by each bowler in each venue)
SELECT p.Player_Name, v.Venue_Name, AVG(wt.Player_Out) AS Average_Wickets, RANK() OVER (ORDER BY AVG(wt.Player_Out) DESC) 
	   AS Wicket_Rank
FROM player p
INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
INNER JOIN matches m ON pm.Match_Id = m.Match_Id
INNER JOIN wicket_taken wt ON m.Match_Id = wt.Match_Id AND p.Player_Id = wt.Player_Out
INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY p.Player_Name, v.Venue_Name
ORDER BY Wicket_Rank;



-- Question No: 14 (players who have consistently scored runs or taken wickets across multiple seasons)
WITH Player_Season_Performance AS (
    SELECT p.Player_Name, s.Season_Year, SUM(bs.Runs_Scored) AS Total_Runs, COUNT(wt.Player_Out) AS Total_Wickets,
           COUNT(DISTINCT m.Match_Id) AS Matches_Played
    FROM player p
    INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Striker
    LEFT JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id 
    AND p.Player_Id = bbb.Striker
    LEFT JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
    INNER JOIN matches m ON bbb.Match_Id = m.Match_Id
    INNER JOIN season s ON m.Season_Id = s.Season_Id
    WHERE p.Player_Id = bbb.Bowler OR p.Player_Id = bbb.Striker
    GROUP BY p.Player_Name, s.Season_Year
)
SELECT Player_Name, AVG(Total_Runs) AS Avg_Runs_Per_Season, AVG(Total_Wickets) AS Avg_Wickets_Per_Season,
       COUNT(Season_Year) AS Seasons_Played
FROM Player_Season_Performance
GROUP BY Player_Name
HAVING Seasons_Played > 3
ORDER BY Avg_Runs_Per_Season DESC, Avg_Wickets_Per_Season DESC
LIMIT 10;



-- Question No: 15 (players whose performance is more suited to specific venues or conditions)
WITH Player_Performance AS (
    SELECT p.Player_Name, v.Venue_Name, AVG(bs.Runs_Scored) AS Avg_Runs, COUNT(wt.Player_Out) AS Wickets_Taken
    FROM player p
    INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Striker
    INNER JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
    INNER JOIN matches m ON m.Match_Id = bbb.Match_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    LEFT JOIN wicket_taken wt ON p.Player_Id = wt.Player_Out AND m.Match_Id = wt.Match_Id
    GROUP BY p.Player_Name, v.Venue_Name
    HAVING AVG(bs.Runs_Scored) > 1000 OR COUNT(wt.Player_Out) > 500
)
SELECT Player_Name, Venue_Name, 
       MAX(Avg_Runs) AS Max_Avg_Runs, 
       MAX(Wickets_Taken) AS Max_Wickets_Taken
FROM Player_Performance
GROUP BY Player_Name, Venue_Name
ORDER BY Max_Avg_Runs DESC, Max_Wickets_Taken DESC;





-- Subjective Questions
-- Question No: 1 (how toss decisions have influenced match results)
WITH Toss_Win_Stats AS (
    SELECT v.Venue_Name, td.Toss_Name AS Toss_Decision, COUNT(*) AS Total_Matches,
           SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS Matches_Won_After_Toss,
           (SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY v.Venue_Name, td.Toss_Name
)
SELECT Venue_Name, Toss_Decision, Total_Matches, Matches_Won_After_Toss, Win_Percentage
FROM Toss_Win_Stats
WHERE Total_Matches >= 10
ORDER BY Win_Percentage DESC, Total_Matches DESC;



-- Question No: 2 (Suggest some of the players who would be best fit for the team)
WITH Player_Stats AS (
    SELECT p.Player_Name, t.Team_Name, SUM(bs.Runs_Scored) AS Total_Runs, 
           SUM(CASE WHEN wt.Player_Out IS NOT NULL THEN 1 ELSE 0 END) AS Total_Wickets_Taken,
           COUNT(DISTINCT m.Match_Id) AS Matches_Played
    FROM player p
    JOIN player_match pm ON p.Player_Id = pm.Player_Id
    JOIN team t ON pm.Team_Id = t.Team_Id
    JOIN matches m ON pm.Match_Id = m.Match_Id
    LEFT JOIN ball_by_ball bbb ON m.Match_Id = bbb.Match_Id AND p.Player_Id = bbb.Bowler
    LEFT JOIN batsman_scored bs ON m.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
    LEFT JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
    GROUP BY p.Player_Name, t.Team_Name
    HAVING Total_Runs > 2000 OR Total_Wickets_Taken > 200
)
SELECT Player_Name, Team_Name, Total_Runs, Total_Wickets_Taken, Matches_Played
FROM Player_Stats
ORDER BY Total_Runs DESC, Total_Wickets_Taken DESC
LIMIT 20;



-- Question No: 3 (some of parameters that should be focused while selecting the players)
WITH Playerstats AS (
	SELECT p.Player_Name,
		   SUM(bs.Runs_Scored) AS Total_Runs,
           AVG(bs.Runs_Scored) AS Avg_Runs_Per_Match,
           (SUM(bs.Runs_Scored) / COUNT(bs.Ball_Id)) * 100 AS Strike_Rate, 
           COUNT(wt.Player_Out) AS Total_Wickets
	FROM player p
	INNER JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
	LEFT JOIN batsman_scored bs ON bb.Match_Id = bs.Match_Id AND bb.Ball_Id = bs.Ball_Id AND bb.Over_Id = bs.Over_Id
	LEFT JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Ball_Id = wt.Ball_Id  AND bs.Over_Id = wt.Over_Id
	GROUP BY p.Player_Name
	ORDER BY Total_Runs DESC
	LIMIT 10
	)
SELECT * FROM Playerstats;



-- Question No: 4 (Which players offer versatility in their skills and can contribute effectively with both bat and ball)
-- Step 1: Calculate batting performance
CREATE TEMPORARY TABLE IF NOT EXISTS BattingPerformance AS
SELECT p.Player_Name, SUM(bs.Runs_Scored) AS Total_Runs, COUNT(bbb.Ball_Id) AS Balls_Faced
FROM player p
INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
INNER JOIN ball_by_ball bbb ON pm.Match_Id = bbb.Match_Id
LEFT JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
WHERE bbb.Striker = p.Player_Id
GROUP BY p.Player_Name;

-- Step 2: Calculate bowling performance
CREATE TEMPORARY TABLE IF NOT EXISTS BowlingPerformance AS
SELECT p.Player_Name, COUNT(bbb.Ball_Id) AS Balls_Bowled,SUM(bs.Runs_Scored) AS Runs_Conceded
FROM player p
INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
INNER JOIN ball_by_ball bbb ON pm.Match_Id = bbb.Match_Id
LEFT JOIN batsman_scored bs ON bbb.Match_Id = bs.Match_Id AND bbb.Over_Id = bs.Over_Id AND bbb.Ball_Id = bs.Ball_Id
WHERE bbb.Bowler = p.Player_Id
GROUP BY p.Player_Name;

-- Step 3: Combine both performances and calculate metrics
SELECT bp.Player_Name, bp.Total_Runs, (bp.Total_Runs / bp.Balls_Faced) AS Strike_Rate, wp.Runs_Conceded, 
    (wp.Runs_Conceded / wp.Balls_Bowled) AS Economy_Rate
FROM BattingPerformance bp
INNER JOIN BowlingPerformance wp ON bp.Player_Name = wp.Player_Name
WHERE bp.Balls_Faced > 50 AND wp.Balls_Bowled > 30
ORDER BY Strike_Rate DESC, Economy_Rate ASC
LIMIT 10;



-- Question No: 5 (Are there players whose presence positively influences the morale and performance of the team)
-- Step 1: Calculate the team's win percentage with each player
WITH PlayerWinStats AS (
    SELECT p.Player_Name, pm.Team_Id, COUNT(m.Match_Id) AS Total_Matches, 
           SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS Matches_Won
    FROM player p
    INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
    INNER JOIN matches m ON pm.Match_Id = m.Match_Id
    WHERE m.Outcome_type = 1 -- considering only completed matches
    GROUP BY p.Player_Name, pm.Team_Id
),
-- Step 2: Calculate Win Percentage for each player
PlayerWinPercentage AS (
    SELECT pws.Player_Name, pws.Team_Id, pws.Total_Matches, pws.Matches_Won, 
           (pws.Matches_Won / pws.Total_Matches) * 100 AS Win_Percentage
    FROM PlayerWinStats pws
    WHERE pws.Total_Matches > 5 -- consider players with more than 5 matches
)
-- Step 3: Combine Player Performance (runs scored, wickets taken, etc.)
SELECT pwp.Player_Name, t.Team_Name, pwp.Total_Matches, pwp.Matches_Won, 
       pwp.Win_Percentage
FROM PlayerWinPercentage pwp
INNER JOIN team t ON pwp.Team_Id = t.Team_Id
ORDER BY Win_Percentage DESC
LIMIT 10;



-- Question No: 6,7
-- ANS: 
-- 		Well I don't know but The question is more subjective and don't need a query.



-- Question No: 8 (Impact of home ground advantage on team performance)
WITH HomeMatches AS (
    SELECT t.Team_Name, v.Venue_Name, COUNT(*) AS Matches_Played,
           SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Wins
    FROM matches m
    JOIN team t ON t.Team_Id IN (m.Team_1, m.Team_2)
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    WHERE (t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2) AND t.Team_Id = m.Toss_Winner
    GROUP BY t.Team_Name, v.Venue_Name
),
WinPercentage AS (
    SELECT Team_Name, Venue_Name, Matches_Played, Wins,
           (Wins / Matches_Played) * 100 AS Win_Percentage
    FROM HomeMatches
)
SELECT Team_Name, Venue_Name, Matches_Played, Wins, Win_Percentage
FROM WinPercentage
WHERE Win_Percentage != 0
ORDER BY Win_Percentage DESC;



-- Question No: 9 (RCB past seasons performance)
WITH RCB_Performance AS (
    SELECT m.Season_Id, COUNT(m.Match_Id) AS Matches_Played,
           SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Matches_Won,
           SUM(CASE WHEN m.Match_Winner != t.Team_Id THEN 1 ELSE 0 END) AS Matches_Lost,
           (SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) / COUNT(m.Match_Id)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN team t ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    WHERE t.Team_Name = 'Royal Challengers Bangalore'
    GROUP BY m.Season_Id
)
SELECT s.Season_Year, rp.Matches_Played, rp.Matches_Won, rp.Matches_Lost, rp.Win_Percentage
FROM RCB_Performance rp
INNER JOIN season s ON rp.Season_Id = s.Season_Id
ORDER BY s.Season_Year;



-- Question No: 10
-- ANS: 
-- 		Well I don't know but The question is more subjective and don't need a query.



-- Question No: 11 (SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils)
UPDATE matches
SET Opponent_Team = 'Delhi_Daredevils'
WHERE Opponent_Team = 'Delhi_Capitals';

