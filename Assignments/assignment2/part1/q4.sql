-- Grader report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q4;

-- You must not change this table definition.
CREATE TABLE q4 (
        assignment_id integer,
        username varchar(25),
        num_marked integer,
        num_not_marked integer,
        min_mark real,
        max_mark real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)


DROP VIEW IF EXISTS GraderTA  CASCADE;
DROP VIEW IF EXISTS Marked CASCADE;
DROP VIEW IF EXISTS markOutOf CASCADE;
DROP VIEW IF EXISTS totalMark CASCADE;
DROP VIEW IF EXISTS percentageMark CASCADE;
DROP VIEW IF EXISTS numMarked CASCADE;
DROP VIEW IF EXISTS numNotMarkedMaxMin CASCADE;



-- Define views for your intermediate steps here.
--Make sure the grader was TA, add assignment_id attribute
CREATE VIEW GraderTA AS (SELECT Grader.username AS username, Grader.group_id AS GID, assignment_id AS AID
FROM Grader LEFT JOIN MarkusUser ON Grader.username = MarkusUser.username
JOIN AssignmentGroup ON Grader.group_id = AssignmentGroup.group_id
WHERE type = 'TA');

--Get the groups that have been marked by a TA for each assignment
CREATE VIEW Marked AS (SELECT GraderTA.username AS username, Result.group_id
AS GID, AID FROM GraderTA JOIN Result ON GraderTA.GID = Result.group_id);

----Find the marks by a TA for each group per assignment
--Find total out-of mark for each assignment
CREATE VIEW markOutOf AS (SELECT assignment_id AS AID, sum(out_of*weight) AS out_of
FROM RubricItem GROUP BY assignment_id);

--Find weighted mark for all assignments
CREATE VIEW totalMark AS (SELECT GID,AID,mark
FROM Result JOIN Marked ON Result.group_id = Marked.GID);

--Determine group marks in percentage for each assignment
CREATE VIEW percentageMark AS (SELECT markOutOf.AID as AID, GID,(mark/out_of)*100 AS mark_percent
FROM markOutOf JOIN totalMark ON markOutOf.AID = totalMark.AID);

--Find num_marked by a TA for each assignment
CREATE VIEW numMarked AS (SELECT AID AS assignment_id,username, count(GID)
AS num_marked FROM Marked GROUP BY username, AID);

--Find num_not_marked by the same TA for each assignment, and the max and min marks
CREATE VIEW numNotMarkedMaxMin AS (SELECT AID AS assignment_id, username, count(*)-count(mark_percent) AS num_not_marked, min(mark_percent)
AS min_mark, max(mark_percent) AS max_mark
FROM (Marked NATURAL RIGHT JOIN GraderTA) NATURAL FULL JOIN percentageMark
GROUP BY AID, username);

-- Final answer.
INSERT INTO q4(SELECT assignment_id, username, COALESCE(num_marked,0), num_not_marked, min_mark, 
max_mark FROM numMarked NATURAL FULL JOIN numNotMarkedMaxMin);
