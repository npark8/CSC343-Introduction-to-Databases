DROP SCHEMA IF EXISTS a3part1 CASCADE;
CREATE SCHEMA a3part1;
SET search_path TO a3part1;

-- The possible values of a what attributes in Skill and ReqSkill tables
CREATE TYPE skill AS ENUM ('SQL', 'Scheme', 'Python','R','LaTeX');

-- The possible values of level and importance attributes in ReqSkill table
CREATE DOMAIN standing AS smallint
  DEFAULT 1
  CHECK (VALUE = 1 OR VALUE = 2 OR VALUE = 3 OR VALUE = 4 OR VALUE = 5);

------------------creating tables based on posting.dtd------------------

-- Position(pID) and position descriptor in words
CREATE TABLE Position (
  pID integer PRIMARY KEY,
  position TEXT NOT NULL
);

-- Questions(qID) associated with each posting(pID)
CREATE TABLE Questions (
  qID integer UNIQUE NOT NULL,
  pID integer NOT NULL REFERENCES Position(pID),
  question TEXT NOT NULL,
  PRIMARY KEY (pID,qID)
);

-- Level and importance of required skills (what) for a position (pID)
CREATE TABLE ReqSkill (
  pID integer REFERENCES Position(pID),
  what skill NOT NULL,
  level standing NOT NULL,
  importance standing NOT NULL,
  PRIMARY KEY (pID, what)
);

-------------------creating tables based on interviews.dtd-----------------

-- Add base table for referencing rID
-- Resume(rID)
CREATE TABLE Resume (
  rID integer PRIMARY KEY
);

-- An interviewer's ID(sID), first and last names
CREATE TABLE Interviewer (
  sID integer PRIMARY KEY,
  forename varchar(100) NOT NULL,
  lastname varchar(100) NOT NULL
);

-- An interviewer's ID(sID) and title
CREATE TABLE InterviewerTitle (
  sID integer NOT NULL REFERENCES Interviewer(sID),
  title varchar(100) NOT NULL,
  PRIMARY KEY (sID, title)
);

-- An interviewer's ID, optional honorific(s)
CREATE TABLE InterviewerHonorific (
  sID integer NOT NULL REFERENCES Interviewer(sID),
  honorific varchar(100) NOT NULL,
  PRIMARY KEY (sID, honorific)
);

-- An interview's date, time, location, interviewer(sID),
-- interviewee(rID) and applied position (pID)
-- Since foreign key reference cannot be made to partial list of primary key,
-- (rID,pID) is redundantly redeclared as unique to avoid syntax error for
-- allowing foreign key references by other tables
CREATE TABLE Interview (
  sID integer NOT NULL REFERENCES Interviewer(sID),
  rID integer NOT NULL REFERENCES Resume(rID),
  pID integer NOT NULL REFERENCES Position(pID),
  date date NOT NULL,
  time time NOT NULL,
  location TEXT NOT NULL,
  PRIMARY KEY (rID,pID,sID),
  UNIQUE (rID,pID)
);

-- Assessment on an interview. Each criteria is evaluated from 0 to 100.
-- interviewee(rID), position(pID), questions(qID), techProficiency,
-- communication, enthusiasm, and collegiability
CREATE TABLE Assessment (
  rID integer NOT NULL,
  pID integer NOT NULL,
  qID integer NOT NULL REFERENCES Questions(qID),
  techProficiency integer NOT NULL,
  communication integer NOT NULL,
  enthusiasm integer NOT NULL,
  CHECK (techProficiency >= 0 AND techProficiency <= 100),
  CHECK (communication >= 0 AND communication <= 100),
  CHECK (enthusiasm >= 0 AND enthusiasm <= 100),
  PRIMARY KEY (rID,pID),
  FOREIGN KEY (rID,pID) REFERENCES Interview (rID,pID)
);

-- Assessment on collegiability for an interview
-- interviewee(rID), position(pID) and collegiability [0,100]
CREATE TABLE AssessCollegiability (
  rID integer NOT NULL,
  pID integer NOT NULL,
  collegiability integer NOT NULL,
  CHECK (collegiability >= 0 AND collegiability <= 100),
  PRIMARY KEY (rID,pID,collegiability),
  FOREIGN KEY (rID,pID) REFERENCES Interview (rID,pID)
);

-- Assessment on answer(s) for an interview.
-- interviewee(rID), position(pID), answers(qID) and answer [0,100]
CREATE TABLE AssessAnswers (
  rID integer NOT NULL,
  pID integer NOT NULL,
  qID integer NOT NULL REFERENCES Questions(qID),
  answer integer CHECK (answer >= 0 AND answer <= 100),
  PRIMARY KEY (rID,pID,qID),
  FOREIGN KEY (rID,pID) REFERENCES Interview (rID,pID)
);


----------------------creating tables for resume.dtd----------------------

-- The possible values of a degreeLevel type
CREATE TYPE degreeLevel AS ENUM ('certificate','undergraduate','professional'
                                ,'masters','doctoral');

-- All Resume(rID) must have skill (skillID) and identification (info) sections
-- All attributes are served as ID in referencing tables
--CREATE TABLE Resume (
--  rID integer PRIMARY KEY,
--  skillID integer NOT NULL REFERENCES Skills(skillID),
--  info integer NOT NULL REFERENCES ID(info)
--);

-- Resume(rID) that optionally has summary section
CREATE TABLE ResumeSummary (
  rID integer PRIMARY KEY REFERENCES Resume(rID),
  summary TEXT NOT NULL
);

-- Resume(rID) that optionally has education section
-- Multiple educations can be present per resume
-- All education section must indicate degree name, level,
-- institution and start, end periods (timestamps)
CREATE TABLE ResumeEducation (
  rID integer REFERENCES Resume(rID),
  degreeName varchar(150) NOT NULL,
  level degreeLevel NOT NULL,
  institution TEXT NOT NULL,
  startDate timestamp NOT NULL,
  endDate timestamp NOT NULL,
  PRIMARY KEY (rID, degreeName)
);

-- For each degree, specify major(s)
CREATE TABLE degreeMajor (
  rID integer NOT NULL,
  degreeName varchar(150) NOT NULL,
  major TEXT NOT NULL,
  PRIMARY KEY (rID, degreeName),
  FOREIGN KEY (rID, degreeName) REFERENCES ResumeEducation (rID, degreeName)
);

-- For each degree, specify optional minor(s)
CREATE TABLE degreeMinor (
  rID integer NOT NULL,
  degreeName varchar(150) NOT NULL,
  minor TEXT NOT NULL,
  PRIMARY KEY (rID, degreeName),
  FOREIGN KEY (rID, degreeName) REFERENCES ResumeEducation (rID, degreeName)
);

-- For each degree, specify optional honours status (boolean)
CREATE TABLE degreeHonours (
  rID integer NOT NULL,
  degreeName varchar(150) NOT NULL,
  honours boolean DEFAULT FALSE,
  PRIMARY KEY (rID, degreeName),
  FOREIGN KEY (rID, degreeName) REFERENCES ResumeEducation (rID, degreeName)
);

-- Resume(rID) that optionally has experience section
-- Multiple experience can be present per resume
-- All experience section must indicate title of position (title),
-- location, and working period with start and end dates (timestamps)
-- (rID,title) is redundantly declared as unique to allow foreign key reference
CREATE TABLE ResumeExperience (
  rID integer NOT NULL REFERENCES Resume(rID),
  title varchar(150) NOT NULL,
  location TEXT NOT NULL,
  startDate timestamp NOT NULL,
  endDate timestamp NOT NULL,
  PRIMARY KEY (rID,title,location),
  UNIQUE (rID,title)
);

-- For each position, optional detailed description can be followed
CREATE TABLE ExperienceDescription (
  rID integer NOT NULL,
  title varchar(150) NOT NULL,
  description TEXT NOT NULL,
  PRIMARY KEY (rID,title),
  FOREIGN KEY (rID,title) REFERENCES ResumeExperience (rID,title)
);

-- Skills (what) associated with each Resume(rID),
-- Multiple skills can be present per resume
-- indicates type of skills (what) and level of the skill (level)
CREATE TABLE Skills (
  rID integer REFERENCES Resume(rID),
  what skill NOT NULL,
  level standing NOT NULL,
  PRIMARY KEY (rID, what)
);

-- Identification (info) associated with each Resume(rID),
-- The following info must be present in each Resume:
-- first and last names, DOB, citizenship, address, telephone, email
CREATE TABLE ID (
  rID integer REFERENCES Resume(rID),
  info integer UNIQUE NOT NULL,
  firstname varchar(150) NOT NULL,
  lastname varchar(150) NOT NULL,
  DOB timestamp NOT NULL,
  citizenship varchar(150) NOT NULL,
  address TEXT NOT NULL,
  telephone TEXT NOT NULL,
  email TEXT NOT NULL,
  PRIMARY KEY (rID, info)
);

-- For each applicant, specify honorific(s)
CREATE TABLE NameHonorific (
  rID integer NOT NULL,
  info integer NOT NULL,
  honorific varchar(100) NOT NULL,
  PRIMARY KEY (rID, info),
  FOREIGN KEY (rID, info) REFERENCES ID (rID, info)
);

-- For each applicant, specify optional title(s)
CREATE TABLE NameTitle (
  rID integer NOT NULL,
  info integer NOT NULL,
  title TEXT NOT NULL,
  PRIMARY KEY (rID, info),
  FOREIGN KEY (rID, info) REFERENCES ID (rID, info)
);
