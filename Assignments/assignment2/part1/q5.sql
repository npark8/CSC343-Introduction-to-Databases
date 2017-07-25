-- Uneven workloads

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q5;

-- You must not change this table definition.
CREATE TABLE q5 (
        assignment_id integer,
        username varchar(25),
        num_assigned integer
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS AIDGIDUser CASCADE;
DROP VIEW IF EXISTS idealLoad CASCADE;
DROP VIEW IF EXISTS actualLoad CASCADE;
DROP VIEW IF EXISTS heavyLoadedAss CASCADE;
DROP VIEW IF EXISTS actualLoadRefined CASCADE;

-- Define views for your intermediate steps here.
--Create base table with necessary info (assignment_id, group_id, username)
CREATE VIEW AIDGIDUser AS (SELECT assignment_id AS AID, group_id AS GID, username
FROM Grader NATURAL FULL JOIN AssignmentGroup NATURAL FULL JOIN Assignment);


--Create table with ideal situation where ALL TAs have been assigned to all assignments by some amount
CREATE VIEW idealLoad AS (SELECT assignment_id AS AID, username 
FROM Assignment, Grader GROUP BY assignment_id, username);


--Match assignment_id with assigned group_id's for each TA
CREATE VIEW actualLoad AS (SELECT assignment_id AS AID, username, count(Grader.group_id) AS num_assigned
FROM Grader JOIN AssignmentGroup ON Grader.group_id = AssignmentGroup.group_id
GROUP BY assignment_id, username);

--Compare the ideal and actual loads and fill out any missing loads
CREATE VIEW actualLoadRefined AS (SELECT idealLoad.AID AS AID, idealLoad.username AS username,
COALESCE(num_assigned,0) AS num_assigned
FROM idealLoad FULL JOIN actualLoad ON idealLoad.AID = actualLoad.AID 
AND idealLoad.username = actualLoad.username);

--Find assignments where TAs are heavyily workload (max,min difference > 10)
CREATE VIEW heavyLoadedAss AS (SELECT AID
FROM actualLoadRefined GROUP BY AID
HAVING (max(num_assigned)-min(num_assigned))>10);


-- Final answer.
--use the above table to filter out under-qualified assignments from workAssigned
INSERT INTO q5 (SELECT * FROM actualLoadRefined NATURAL JOIN heavyLoadedAss);

