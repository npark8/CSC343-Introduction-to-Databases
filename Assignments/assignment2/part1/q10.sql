-- A1 report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q10;

-- You must not change this table definition.
CREATE TABLE q10 (
	group_id integer,
	mark real,
	compared_to_average real,
	status varchar(5)
);
--total out of mark
DROP VIEW IF EXISTS TtlOutOf CASCADE;
CREATE VIEW TtlOutOf AS
    SELECT SUM(out_of) AS OutOf 
    FROM (SELECT rubric_id, T2.assignment_id, out_of 
        FROM RubricItem T1 
        JOIN Assignment T2 ON T1.assignment_id = T2.assignment_id
        WHERE T2.description = 'A1') Tbl;

--Get the groups that did A1 and compute percentage
DROP VIEW IF EXISTS A1Groups CASCADE;
CREATE VIEW A1Groups AS
    SELECT T1.group_id, (T3.mark/Tbl2.OutOf)*100 AS grade  
    FROM AssignmentGroup T1 
        JOIN Assignment T2 ON T1.assignment_id = T2.assignment_id
        LEFT JOIN Result T3 ON T1.group_id = T3.group_id, TtlOutOf Tbl2
    WHERE T2.description = 'A1'
    ORDER BY T1.group_id;
    
--figure out average for the assignment
DROP VIEW IF EXISTS TtlAvg CASCADE;
CREATE VIEW TtlAvg AS
    SELECT avg(grade) AS Average FROM A1Groups;
    
DROP VIEW IF EXISTS A1GDiffS CASCADE;
CREATE VIEW A1GDiffS AS
    SELECT T1.group_id, T1.grade AS mark,
            (T1.grade - T2.Average) AS compared_to_average
    FROM A1Groups T1, TtlAvg T2;
            
--Final Result
INSERT INTO q10 
(SELECT group_id, 
        mark,
        compared_to_average,
        CASE WHEN compared_to_average = 0 THEN 'at'
            WHEN compared_to_average > 0 THEN 'above'
            WHEN compared_to_average < 0 THEN 'below'
        END AS status
 FROM A1GDiffS); 
 