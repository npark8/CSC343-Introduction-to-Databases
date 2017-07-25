-- Solo superior

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q3;

-- You must not change this table definition.
CREATE TABLE q3 (
        assignment_id integer,
        description varchar(100),
        num_solo integer,
        average_solo real,
        num_collaborators integer,
        average_collaborators real,
        average_students_per_submission real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS AIDGID CASCADE;
DROP VIEW IF EXISTS numstudpergroup CASCADE;
DROP VIEW IF EXISTS sologid CASCADE;
DROP VIEW IF EXISTS groupgid CASCADE;
DROP VIEW IF EXISTS markoutof CASCADE;
DROP VIEW IF EXISTS soloweight CASCADE;
DROP VIEW IF EXISTS groupweight CASCADE;
DROP VIEW IF EXISTS solopercent CASCADE;
DROP VIEW IF EXISTS grouppercent CASCADE;
DROP VIEW IF EXISTS unfilteredresult CASCADE;
DROP VIEW IF EXISTS totalgroup CASCADE;
DROP VIEW IF EXISTS markpergroup CASCADE;
DROP VIEW IF EXISTS rawResult CASCADE;
DROP VIEW IF EXISTS totalSolo CASCADE;
DROP VIEW IF EXISTS totalGrouper CASCADE;
DROP VIEW IF EXISTS assDescription CASCADE;
DROP VIEW IF EXISTS solosuperior CASCADE;




-- Define views for your intermediate steps here.

--Create base table that includes every group_id and assignment_id
CREATE VIEW AIDGID AS (SELECT Assignment.assignment_id AS AID, group_id AS GID
FROM Assignment JOIN AssignmentGroup
ON Assignment.assignment_id = AssignmentGroup.assignment_id);

--Find every group_id and associated number of students in each group
CREATE VIEW NumStudPerGroup AS (SELECT group_id, count(username) AS numStudent
FROM Membership GROUP by group_id);

----Separate group_id into solo and group for assignments----
--Get group_id of solo student
CREATE VIEW soloGID AS (SELECT AID, group_id AS soloGID, numStudent
FROM AIDGID JOIN NumStudPerGroup ON AIDGID.GID = NumStudPerGroup.group_id
WHERE numStudent = 1);

--Get group_id of students who worked in groups
CREATE VIEW groupGID AS (SELECT AID, group_id AS groupGID, numStudent
FROM AIDGID JOIN NumStudPerGroup ON AIDGID.GID = NumStudPerGroup.group_id
WHERE numStudent > 1);

----Find average grade for solo students for each assignment----
--Find total out-of mark for each assignment
CREATE VIEW markOutOf AS (SELECT assignment_id, sum(out_of*weight) AS out_of
FROM RubricItem GROUP BY assignment_id);

--Find weighted mark for all assignments
CREATE VIEW markPerGroup AS (SELECT group_id, sum(grade*weight) AS weightedMark
FROM RubricItem JOIN Grade ON RubricItem.rubric_id = Grade.rubric_id
GROUP BY group_id);

--Filter weighted mark for solo students
CREATE VIEW soloWeight AS (SELECT AID, soloGID, weightedMark
FROM markPerGroup JOIN soloGID on soloGID.soloGID = markPerGroup.group_id);

--Filter weighted mark for students in group
CREATE VIEW groupWeight AS (SELECT AID, groupGID, weightedMark
FROM markPerGroup JOIN groupGID on groupGID.groupGID = markPerGroup.group_id);

--Find percentage mark for solo students
CREATE VIEW soloPercent AS (SELECT soloWeight.AID AS AID, soloGID,(weightedMark/out_of)*100 AS percentMark
FROM (markOutOf JOIN soloWeight ON markOutOf.assignment_id = soloWeight.AID));

--Find percentage mark for students in group
CREATE VIEW groupPercent AS (SELECT groupWeight.AID AS AID, groupGID,(weightedMark/out_of)*100 AS percentMark
FROM (markOutOf JOIN groupWeight ON markOutOf.assignment_id = groupWeight.AID));


--Semi-Result 1: Find average mark attributes
CREATE VIEW avgMarks AS (SELECT Assignment.assignment_id AS assignment_id, avg(soloPercent.percentMark) AS average_solo, avg(groupPercent.percentMark) AS average_collaborators
FROM groupPercent FULL JOIN soloPercent ON groupPercent.AID = soloPercent.AID
FULL JOIN Assignment ON Assignment.assignment_id = soloPercent.AID
GROUP BY Assignment.assignment_id);



----Find total number of solo and groupers declared per assignment
--for solo students
CREATE VIEW totalSolo AS (SELECT AID, sum(soloGID.numStudent) AS num_solo
FROM soloGID GROUP BY AID);

--for grouper
CREATE VIEW totalGrouper AS (SELECT AID, sum(groupGID.numStudent) AS num_collaborators
FROM groupGID GROUP BY AID);

--Find the total number of groups declared for each assignment
CREATE VIEW totalGroup AS (SELECT assignment_id AS AID, count(distinct group_id) AS totNumGroup FROM Membership NATURAL JOIN AssignmentGroup GROUP BY assignment_id);


--Semi-Result 2: Join the tables above, get number of students attributes per assignment
CREATE VIEW numStudAttributes AS (SELECT AID AS assignment_id,
COALESCE(sum(num_solo),0) AS num_solo, COALESCE(sum(num_collaborators),0) AS num_collaborators,
sum(COALESCE(num_solo,0) + COALESCE(num_collaborators,0))/avg(totNumGroup) AS average_students_per_submission
FROM (totalSolo NATURAL FULL JOIN totalGrouper) NATURAL FULL JOIN totalGroup GROUP BY AID);

--Semi-Result 3: Find description per assignment
CREATE VIEW assDescription AS (SELECT assignment_id, description
FROM Assignment);

--Join all semi-result tables to combine all attributes specified on handout
CREATE VIEW SoloSuperior AS (SELECT assDescription.assignment_id AS assignment_id, description, COALESCE(num_solo,0) AS num_solo, average_solo, COALESCE(num_collaborators,0) AS num_collaborators, average_collaborators,
average_students_per_submission
FROM assDescription FULL JOIN numStudAttributes ON assDescription.assignment_id = numStudAttributes.assignment_id
FULL JOIN avgMarks ON assDescription.assignment_id = avgMarks.assignment_id);


-- Final answer.
-- put a final query here so that its results will go into the table.

INSERT INTO q3 (SELECT * FROM SoloSuperior);


