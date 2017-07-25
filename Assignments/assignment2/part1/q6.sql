-- Steady work
SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q6;

-- You must not change this table definition.
CREATE TABLE q6 (
	group_id integer,
	first_file varchar(25),
	first_time timestamp,
	first_submitter varchar(25),
	last_file varchar(25),
	last_time timestamp, 
	last_submitter varchar(25),
	elapsed_time interval
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS OrderedA1 CASCADE;
--create a table with submissions, group info, assignment name = 'A1' in order
CREATE VIEW OrderedA1 AS
    SELECT T1.group_id, T1.submission_id, T1.username,
        T1.file_name, T1.submission_date, T3.description
    FROM (Submissions T1
        INNER JOIN AssignmentGroup T2
            ON T1.group_id = T2.group_id
        INNER JOIN Assignment T3
            ON T2.assignment_id = T3.assignment_id)
    WHERE T3.description = 'A1'
    ORDER BY T1.group_id, T1.submission_date;
--Pull out the min and the max of each group submission by timestamp
DROP VIEW IF EXISTS firstFiles CASCADE;
CREATE VIEW firstFiles AS
    SELECT T1.group_id,
        T1.submission_date as first_time,
        T1.file_name as first_file,
        T1.username as first_submitter
        FROM (SELECT group_id, min(submission_date) AS first_time
                 FROM OrderedA1 GROUP BY group_id ORDER BY group_id) T2
        JOIN OrderedA1 T1 ON T1.submission_date = T2.first_time;

DROP VIEW IF EXISTS lastFiles CASCADE;
CREATE VIEW lastFiles AS
    SELECT T1.group_id,
        T1.submission_date as last_time,
        T1.file_name as last_file,
        T1.username as last_submitter
        FROM (SELECT group_id, max(submission_date) AS last_time
                 FROM OrderedA1 GROUP BY group_id ORDER BY group_id) T2
        JOIN OrderedA1 T1 ON T1.submission_date = T2.last_time;

--merge the two together
DROP VIEW IF EXISTS finalFiles CASCADE;
CREATE VIEW finalFiles AS
    SELECT T1.group_id, T1.first_file, T1.first_time, T1.first_submitter,
            T2.last_file, T2.last_time, T2.last_submitter,
            (T2.last_time - T1.first_time) AS elapsed_time
            FROM firstFiles T1 JOIN lastFiles T2 ON T1.group_id = T2.group_id;
            
-- Final answer.
INSERT INTO q6 SELECT * FROM finalFiles;
	-- put a final query here so that its results will go into the table.
	