-- Getting soft

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q2;

-- You must not change this table definition.
CREATE TABLE q2 (
        ta_name varchar(100),
        average_mark_all_assignments real,
        mark_change_first_last real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS gradedAss CASCADE;
DROP VIEW IF EXISTS TAList CASCADE;
DROP VIEW IF EXISTS MarkedALL CASCADE;
DROP VIEW IF EXISTS partialTAList CASCADE;
DROP VIEW IF EXISTS MarkedTenOrMore CASCADE;
DROP VIEW IF EXISTS FilteredTAList CASCADE;
DROP VIEW IF EXISTS markOutOf CASCADE;
DROP VIEW IF EXISTS markPerGroup CASCADE;
DROP VIEW IF EXISTS gradePerGroupOnAss CASCADE;
DROP VIEW IF EXISTS avgPerAss CASCADE;
DROP VIEW IF EXISTS avgPerAssOrdered CASCADE;
DROP VIEW IF EXISTS AssOrder CASCADE;
DROP VIEW IF EXISTS TAwithFluctuate CASCADE;
DROP VIEW IF EXISTS TAwithIncrAvg CASCADE;
DROP VIEW IF EXISTS A1 CASCADE;
DROP VIEW IF EXISTS firstAss CASCADE;
DROP VIEW IF EXISTS lastAss CASCADE;
DROP VIEW IF EXISTS firstLast CASCADE;
DROP VIEW IF EXISTS simpleTAList CASCADE;
DROP VIEW IF EXISTS nameAvg CASCADE;
DROP VIEW IF EXISTS GettingSoft CASCADE;




-- Define views for your intermediate steps here.


--Find all assignments that have been graded
CREATE VIEW gradedAss AS (SELECT assignment_id AS AID, Result.group_id AS GID
FROM Result JOIN AssignmentGroup ON Result.group_id = AssignmentGroup.group_id);

--Find username and name of TAs who have marked at least one assignment
CREATE VIEW TAList AS (SELECT AID, Grader.group_id AS GID,
Grader.username AS username, (firstname||' '||surname) AS ta_name
FROM MarkusUser JOIN Grader ON MarkusUser.username = Grader.username
JOIN gradedAss ON Grader.group_id = gradedAss.GID
WHERE type = 'TA');

----Find TA who marked all assignments AND marked at least 10 groups for each assignment
--Find TAs who have marked all assignments
CREATE VIEW MarkedALL AS (SELECT username
FROM TAList GROUP BY username
HAVING (count(DISTINCT AID) >= (SELECT count(DISTINCT AID) FROM gradedAss)));

--Filter TAs who satisfies partial condition from TAList table
CREATE VIEW partialTAList AS (SELECT * FROM TAList NATURAL JOIN MarkedALL);

--Find TAs who have makred at least 10 or more groups per assignments
CREATE VIEW MarkedTenOrMore AS (SELECT username
FROM partialTAList GROUP BY username, AID 
HAVING count(distinct GID) >= 10);

--Filter TAList one more time
CREATE VIEW FilteredTAList AS (SELECT * FROM partialTAList NATURAL JOIN MarkedTenOrMore);

----Find each TA's average marks for each assignment
--Find the total out-of mark for each assignment
CREATE VIEW markOutOf AS (SELECT assignment_id AS AID, sum(out_of*weight)
 AS out_of FROM RubricItem GROUP BY assignment_id);

--Find weighted mark for each group and the grader (TA)
CREATE VIEW markPerGroup AS (SELECT username, Result.group_id AS GID,AID,mark
FROM Result JOIN FilteredTAList ON Result.group_id = FilteredTAList.GID 
GROUP BY username, AID, Result.group_id);

--Determine group marks in percentage
CREATE VIEW gradePerGroupOnAss AS (SELECT username, markOutOf.AID as AID, GID,
(mark/out_of)*100 AS mark_percent
FROM markOutOf JOIN markPerGroup ON markOutOf.AID = markPerGroup.AID);

--Find the average marks for each assignment the TAs have given out
CREATE VIEW avgPerAss AS (SELECT username, AID, avg(mark_percent) AS avg_per_ass
FROM gradePerGroupOnAss GROUP BY username, AID);

---- Find TAs with increasing average from assignment to assignment
--Find Assignment due dates (timestamp)
CREATE VIEW AssOrder AS (SELECT assignment_id AS AID, due_date FROM Assignment);

--Combine with the avgPerAss table to figure out which assignment comes first
CREATE VIEW avgPerAssOrdered AS (SELECT * FROM avgPerAss NATURAL JOIN AssOrder);

--Finally, check if TA's average mark per assignment increased over time
CREATE VIEW TAwithFluctuate AS (SELECT username FROM avgPerAssOrdered A1 
WHERE A1.due_date > SOME (SELECT A2.due_date FROM avgPerAssOrdered A2) 
AND A1.avg_per_ass <= SOME (SELECT A3.avg_per_ass FROM avgPerAssOrdered A3 
WHERE A3.due_date < A1.due_date));

--Filter out TAs that have fluctuating average over time
CREATE VIEW TAwithIncrAvg AS ((SELECT username FROM FilteredTAList) 
EXCEPT (SELECT * FROM TAwithFluctuate));

----Find the first and last assignment avg marks of satisfying TAs
--Create base table for convenience
CREATE VIEW A1 AS (SELECT * FROM avgPerAssOrdered NATURAL JOIN TAwithIncrAvg);

--First assignment avg
CREATE VIEW firstAss AS (SELECT username, avg_per_ass AS first_ass
FROM A1 WHERE A1.due_date <= ALL (SELECT due_date FROM A1));

--Last assignment avg
CREATE VIEW lastAss AS (SELECT username, avg_per_ass AS last_ass
FROM A1 WHERE A1.due_date >= ALL (SELECT due_date FROM A1));

--*Semi-Result 1: Find mark_change_first_last
CREATE VIEW firstLast AS (SELECT username, (last_ass-first_ass) 
AS mark_change_first_last
FROM firstAss NATURAL JOIN lastAss);

--Simplify FilteredTAList with username and ta_name
CREATE VIEW simpleTAList AS (SELECT distinct username, ta_name 
FROM FilteredTAList NATURAL JOIN TAwithIncrAvg);

--*Semi-Result 2: JOIN the final TA list A1 with filtered TA List and aggregate results
CREATE VIEW nameAvg AS (SELECT username, ta_name, avg(avg_per_ass) AS average_mark_all_assignments
FROM A1 NATURAL JOIN simpleTAList GROUP BY username, ta_name);

--Final result: combine the semi-result tables above to include all required attributes
CREATE VIEW GettingSoft AS (SELECT ta_name, average_mark_all_assignments,
mark_change_first_last FROM firstLast NATURAL JOIN nameAvg); 

-- Final answer.
--Join with assignment table to get all possible assignment_id
INSERT INTO q2 (SELECT * FROM GettingSoft);

