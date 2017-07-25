-- Inseparable

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q9;

-- You must not change this table definition.
CREATE TABLE q9 (
	student1 varchar(25),
	student2 varchar(25)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

--take Membership table and count number of members per group_id
DROP VIEW IF EXISTS CountMem CASCADE;
CREATE VIEW CountMem AS
    SELECT group_id, COUNT(username) AS NumGroup FROM Membership
    GROUP BY group_id;
    
--merge this result with the AssignmentGroup and Assignment table
--group_id, NumGroup, a_id, description, due_date, group_min, group_max 
DROP VIEW IF EXISTS AGandCMem CASCADE;
CREATE VIEW AGandCMem AS
    SELECT T1.group_id, T2.NumGroup, T1.assignment_id, T3.description,
            T3.due_date, T3.group_min, T3.group_max
    FROM AssignmentGroup T1
        INNER JOIN CountMem T2
            ON T1.group_id = T2.group_id
        INNER JOIN Assignment T3
            ON T3.assignment_id = T1.assignment_id;

--Finds groups/students that decided to go solo by choice at some point
DROP VIEW IF EXISTS SoloS CASCADE;
CREATE VIEW SoloS AS
    SELECT DISTINCT username FROM Membership T1 JOIN
    (SELECT group_id FROM AGandCMem T1
    WHERE EXISTS(SELECT * FROM AGandCMem T2
                WHERE (T1.group_id = T2.group_id) AND (group_max > 1) AND (NumGroup = 1))
    GROUP BY group_id) T2 ON T1.group_id = T2.group_id;

--these are the students that always form groups when possible
DROP VIEW IF EXISTS RelStudents CASCADE;
CREATE VIEW RelStudents AS
    SELECT username 
    FROM (SELECT DISTINCT username FROM Membership) T1 EXCEPT
            (SELECT DISTINCT username FROM SoloS)
    ORDER BY username;
    
----Now we need to find if any of these students tend to work together---
--Groups where more than one person was possible
DROP VIEW IF EXISTS GrMem CASCADE;
CREATE VIEW GrMem AS
    SELECT T1.group_id FROM AGandCMem T1
    WHERE T1.group_max > 1;
    
--add usernames
DROP VIEW IF EXISTS GandMem CASCADE;
CREATE VIEW GandMem AS
    SELECT T1.group_id, T2.username 
    FROM (GrMem T1 Join Membership T2 ON T1.group_id = T2.group_id);
--put up possible pairs: students who have always joined a group when possible
DROP VIEW IF EXISTS PossPairsList CASCADE;
CREATE VIEW PossPairsList AS
    SELECT T1.group_id, T1.username AS St1, T2.username AS St2
    FROM GandMem T1, GandMem T2
    WHERE T1.group_id = T2.group_id AND T1.username < T2.username
    AND T1.username IN (SELECT username FROM RelStudents) 
    AND T2.username IN (SELECT username FROM RelStudents)
    ORDER BY T1.group_id, T1.username, T2.username;
----take only pairs that show up together--
--pairs that don't show up together all the time
DROP VIEW IF EXISTS NotLoyal CASCADE;
CREATE VIEW NotLoyal AS
    SELECT T1.group_id, T1.St1, T1.St2 FROM PossPairsList T1
    WHERE EXISTS
        (SELECT T2.group_id, T2.St1 FROM PossPairsList T2 
            WHERE T2.group_id <> T1.group_id
            AND T1.St1 = T2.St1
            AND T1.St2 NOT IN 
                (SELECT T3.St2 FROM PossPairsList T3 
                WHERE T3.group_id = T2.group_id));
--remove the above pairs from the final pair list
DROP VIEW IF EXISTS FinalPairs CASCADE;
CREATE VIEW FinalPairs AS
    SELECT DISTINCT St1 AS student1, St2 AS student2 
    FROM (SELECT DISTINCT St1, St2 FROM PossPairsList) T1 EXCEPT
        (SELECT DISTINCT St1, St2 FROM NotLoyal)
    ORDER BY Student1, Student2;

-- Final answer.
INSERT INTO q9 SELECT * FROM FinalPairs;
	-- put a final query here so that its results will go into the table.