-- Distributions

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q1;

-- You must not change this table definition.
CREATE TABLE q1 (
        assignment_id integer,
        average_mark_percent real,
        num_80_100 integer,
        num_60_79 integer,
        num_50_59 integer,
        num_0_49 integer
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS markoutof CASCADE;
DROP VIEW IF EXISTS markpergroup CASCADE;
DROP VIEW IF EXISTS aidmatch CASCADE;
DROP VIEW IF EXISTS percentagepergroup CASCADE;

-- Define views for your intermediate steps here.

--Find total out-of mark for each assignment
CREATE VIEW markOutOf AS (SELECT assignment_id, sum(out_of*weight)
 AS out_of FROM RubricItem GROUP BY assignment_id);

--Find the weighted marks for each group
CREATE VIEW markPerGroup AS (SELECT group_id, sum(grade*weight) AS weightedMark
FROM RubricItem JOIN Grade ON RubricItem.rubric_id = Grade.rubric_id
GROUP BY group_id);

--Determine the matching assignment where the group has been marked on
CREATE VIEW aIdMatch AS (SELECT markPerGroup.group_id, assignment_id, weightedMark
FROM AssignmentGroup JOIN  markPerGroup
ON AssignmentGroup.group_id = markPerGroup.group_id
);

--Determine group marks in percentage for each assignment
CREATE VIEW percentagePerGroup AS (SELECT markOutOf.assignment_id as assignment_id,
group_id,(weightedMark/out_of)*100 AS mark_percent
FROM markOutOf JOIN aIdMatch ON markOutOf.assignment_id = aIdMatch.assignment_id);


-- Final answer.
-- put a final query here so that its results will go into the table.

--Join with assignment table to get all possible assignment_id
INSERT INTO q1 (SELECT Assignment.assignment_id AS assignment_id, avg(mark_percent) AS average_mark_percent,
COALESCE( COUNT(CASE WHEN (mark_percent>=80 AND mark_percent <=100) THEN 1 END),0) AS num_80_100,
COALESCE( COUNT(CASE WHEN (mark_percent>=60 AND mark_percent <80)  THEN 1 END),0) AS num_60_79,
COALESCE( COUNT(CASE WHEN (mark_percent>=50 AND mark_percent <60) THEN 1 END),0) AS num_50_59,
COALESCE( COUNT(CASE WHEN (mark_percent>=0 AND mark_percent <50) THEN 1 END),0) AS num_0_49
FROM percentagePerGroup FULL JOIN Assignment ON percentagePerGroup.assignment_id = Assignment.assignment_id
GROUP BY Assignment.assignment_id);
