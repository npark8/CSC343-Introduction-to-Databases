-- High coverage
--NEED TO BE TESTED
SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q7;

-- You must not change this table definition.
CREATE TABLE q7 (
	ta varchar(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
--combine Grader with AssignmentGroup table
DROP VIEW IF EXISTS AGandG CASCADE;
CREATE VIEW AGandG AS
    SELECT AssignmentGroup.group_id, 
        AssignmentGroup.assignment_id, 
        Grader.username 
        FROM AssignmentGroup INNER JOIN Grader 
            ON AssignmentGroup.group_id = Grader.group_id;
    
--combine Assignment table with AGandG (for all possible assignments)
DROP VIEW IF EXISTS AandG CASCADE;
CREATE VIEW AandG AS
    SELECT T1.assignment_id,
            T2.group_id,
            T2.username
            FROM Assignment T1 LEFT JOIN AGandG T2
                ON T1.assignment_id = T2.assignment_id;

--Counts # of groups per assignment that grader graded, filter to atleast 1/A 
DROP VIEW IF EXISTS GraderCount CASCADE;
CREATE VIEW GraderCount AS
    SELECT username AS ta, 
    COUNT(DISTINCT assignment_id) AS ACount 
    FROM AandG
    GROUP BY ta
    HAVING COUNT(DISTINCT assignment_id) = (SELECT COUNT(assignment_id) FROM Assignment);
    
--Combine Membership with AGandG
DROP VIEW IF EXISTS MandAG CASCADE;
CREATE VIEW MandAG AS
    SELECT Membership.group_id, 
        Membership.username AS member, 
        AGandG.assignment_id,
        AGandG.username AS ta 
    FROM Membership INNER JOIN AGandG 
        ON Membership.group_id = AGandG.group_id;
        
--count # of students that each TA has taught, filter to all
DROP VIEW IF EXISTS StudentCount CASCADE;
CREATE VIEW StudentCount AS
    SELECT ta, COUNT(DISTINCT member) AS SCount FROM MandAG
    GROUP BY ta
    HAVING COUNT(DISTINCT member) = (SELECT COUNT(DISTINCT member) FROM MandAG);

--Intersect the two lists of TAs
DROP VIEW IF EXISTS FinalAns CASCADE;
CREATE VIEW FinalAns As
    ((SELECT ta FROM GraderCount) INTERSECT (SELECT ta FROM StudentCount));

-- Final answer.
INSERT INTO q7 
    Select * from FinalAns;
	-- put a final query here so that its results will go into the table.
	