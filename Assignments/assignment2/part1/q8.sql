-- Never solo by choice

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q8;

-- You must not change this table definition.
CREATE TABLE q8 (
	username varchar(25),
	group_average real,
	solo_average real
);

--Find students that didn't contributed at some point

--Usernames in each group that submitted something
DROP VIEW IF EXISTS ContrStudents CASCADE;
CREATE VIEW ContrStudents AS
    SELECT DISTINCT group_id, username FROM Submissions;
    
--Usernames for all the students who didn't participate at some point
DROP VIEW IF EXISTS NonCStudents CASCADE;
CREATE VIEW NonCStudents AS
    SELECT username FROM 
    ((SELECT group_id, username FROM Membership)
        EXCEPT
    (SELECT group_id, username FROM ContrStudents)) T1;

--all relevant student usernames
DROP VIEW IF EXISTS AllStudents CASCADE;
CREATE VIEW AllStudents AS
    ((SELECT DISTINCT username FROM Membership)
        EXCEPT
    (SELECT DISTINCT username FROM NonCStudents));

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

--Finds students that decided to go solo by choice at some point
DROP VIEW IF EXISTS SoloS CASCADE;
CREATE VIEW SoloS AS
    SELECT group_id FROM AGandCMem T1
    WHERE EXISTS(SELECT * FROM AGandCMem T2
                WHERE (T1.group_id = T2.group_id) AND (group_max > 1) AND (NumGroup = 1))
    GROUP BY group_id;
                
--Non-Solo students usernames, who contributed each time 
DROP VIEW IF EXISTS NonSolo;
CREATE VIEW NonSolo AS
    SELECT username FROM 
    ((SELECT username FROM AllStudents) 
        EXCEPT 
    (SELECT DISTINCT username FROM SoloS 
        JOIN Membership ON SoloS.group_id = Membership.group_id)) T1;
        
--Find averages for these students
--get all the groups that each user has worked in
DROP VIEW IF EXISTS AllRGroupIDs CASCADE;
CREATE VIEW AllRGroupIDs AS
    SELECT T1.group_id, T2.username, T3.assignment_id 
    FROM Membership T1 
        INNER JOIN NonSolo T2 
            ON T1.username = T2.username
        INNER JOIN AssignmentGroup T3 
            ON T3.group_id = T1.group_id;
--find what all assignments are out of
DROP VIEW IF EXISTS TtlOutOf CASCADE;
CREATE VIEW TtlOutOf AS
    SELECT assignment_id, SUM(out_of) AS OutOf 
    FROM RubricItem
    GROUP BY assignment_id;        
        
--Merge with the Results Table
DROP VIEW IF EXISTS GIDandResult CASCADE;
CREATE VIEW GIDandResult AS
    SELECT T1.group_id, 
        T1.username, 
        (T2.mark/T3.OutOf)*100 AS Percentage, T1.assignment_id 
        FROM AllRGroupIDs T1 
            INNER JOIN Result T2 ON T1.group_id = T2.group_id
            INNER JOIN TtlOutOf T3 ON T3.assignment_id = T1.assignment_id;
            
--use this view to create two views, solo assignments and group assignments
DROP VIEW IF EXISTS SoloAssign CASCADE;
CREATE VIEW SoloAssign AS
    SELECT T1.group_id, 
        T1.username, 
        T1.Percentage, T1.assignment_id FROM GIDandResult T1, Assignment T2
    WHERE T1.assignment_id = T2.assignment_id
        AND T2.group_max < 2;
        
DROP VIEW IF EXISTS GroupAssign CASCADE;
CREATE VIEW GroupAssign AS
    SELECT T1.group_id, 
        T1.username, 
        T1.Percentage, T1.assignment_id FROM GIDandResult T1, Assignment T2
    WHERE T1.assignment_id = T2.assignment_id
        AND T2.group_max > 1;

--find the averages for each username and put them all together
DROP VIEW IF EXISTS FinalTable CASCADE;
CREATE VIEW FinalTable AS
    SELECT T1.username, 
        AVG(T2.Percentage) AS group_average, 
        AVG(T3.Percentage) AS solo_average 
    FROM GIDandResult T1
        LEFT JOIN GroupAssign T2 ON T1.username = T2.username
        LEFT JOIN SoloAssign T3 ON T1.username = T3.username
    GROUP BY T1.username
    ORDER BY T1.username;
    
-- Final answer.
INSERT INTO q8 SELECT * FROM FinalTable; 
