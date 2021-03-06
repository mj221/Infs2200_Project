SET LINE 200;
-- Task 1 --
--Q1--
SELECT CONSTRAINT_NAME, TABLE_NAME FROM USER_CONSTRAINTS WHERE TABLE_NAME IN ('FILM_CATEGORY', 'CATEGORY', 'FILM', 'FILM_ACTOR', 'LANGUAGE', 'ACTOR');

--Q2--
ALTER TABLE CATEGORY ADD CONSTRAINT PK_CATEGORYID PRIMARY KEY (CATEGORY_ID);
ALTER TABLE LANGUAGE ADD CONSTRAINT PK_LANGUAGEID PRIMARY KEY (LANGUAGE_ID);
ALTER TABLE FILM ADD CONSTRAINT UN_DESCRIPTION UNIQUE (DESCRIPTION);
ALTER TABLE ACTOR ADD CONSTRAINT CK_FNAME CHECK (FIRST_NAME IS NOT NULL);
ALTER TABLE ACTOR ADD CONSTRAINT CK_LNAME CHECK (LAST_NAME IS NOT NULL);
ALTER TABLE CATEGORY ADD CONSTRAINT CK_CATNAME CHECK (NAME IS NOT NULL);
ALTER TABLE LANGUAGE ADD CONSTRAINT CK_LANNAME CHECK (NAME IS NOT NULL);
ALTER TABLE FILM ADD CONSTRAINT CK_TITLE CHECK (TITLE IS NOT NULL);
ALTER TABLE FILM ADD CONSTRAINT CK_RELEASEYR CHECK (RELEASE_YEAR <= 2020);
ALTER TABLE FILM ADD CONSTRAINT CK_RATING CHECK (RATING IN ('G', 'PG', 'PG-13', 'R', 'NC-17'));
ALTER TABLE FILM ADD CONSTRAINT CK_SPLFEATURES CHECK (SPECIAL_FEATURES = NULL OR SPECIAL_FEATURES IN ('Trailers', 'Commentaries', 'Deleted Scenes', 'Behind the Scenes'));
ALTER TABLE FILM ADD CONSTRAINT FK_LANGUAGEID FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (LANGUAGE_ID);
ALTER TABLE FILM ADD CONSTRAINT FK_ORLANGUAGEID FOREIGN KEY (ORIGINAL_LANGUAGE_ID) REFERENCES LANGUAGE (LANGUAGE_ID);
ALTER TABLE FILM_ACTOR ADD CONSTRAINT FK_ACTORID FOREIGN KEY (ACTOR_ID) REFERENCES ACTOR (ACTOR_ID);
ALTER TABLE FILM_CATEGORY ADD CONSTRAINT FK_CATEGORYID FOREIGN KEY (CATEGORY_ID) REFERENCES CATEGORY (CATEGORY_ID);
ALTER TABLE FILM_CATEGORY ADD CONSTRAINT FK_FILMID2 FOREIGN KEY (FILM_ID) REFERENCES FILM (FILM_ID);


-- Task 2 --
--Q1--
CREATE SEQUENCE "FILM_ID_SEQ" MINVALUE 20010 MAXVALUE 99999999990 INCREMENT BY 10 START WITH 20010;

--Q2--
CREATE OR REPLACE TRIGGER "BI_FILM_ID"
BEFORE INSERT ON "FILM"
FOR EACH ROW 
BEGIN
    SELECT "FILM_ID_SEQ".NEXTVAL INTO :NEW.FILM_ID FROM DUAL;
END;
/

--Q3--
CREATE OR REPLACE TRIGGER "BI_FILM_DESP"
BEFORE INSERT ON "FILM"
FOR EACH ROW
DECLARE
    og_lang VARCHAR(20);
    lang VARCHAR(20);
    temp_seq INTEGER;
BEGIN
IF (:NEW.ORIGINAL_LANGUAGE_ID IS NOT NULL AND :NEW.LANGUAGE_ID IS NOT NULL AND :NEW.RATING IS NOT NULL)
    THEN
        SELECT NAME INTO og_lang FROM LANGUAGE WHERE :NEW.ORIGINAL_LANGUAGE_ID = LANGUAGE.LANGUAGE_ID;
        SELECT NAME INTO lang FROM LANGUAGE WHERE :NEW.LANGUAGE_ID = LANGUAGE.LANGUAGE_ID;
        SELECT count(*) INTO temp_seq from FILM WHERE RATING = :NEW.RATING;
        :NEW.DESCRIPTION := CONCAT (:NEW.DESCRIPTION, CONCAT(:NEW.RATING, CONCAT('-', CONCAT(temp_seq + 1, ': '))));
        :NEW.DESCRIPTION := CONCAT (:NEW.DESCRIPTION, CONCAT('Originally in ', CONCAT(og_lang, '. ')));
        :NEW.DESCRIPTION := CONCAT (:NEW.DESCRIPTION, CONCAT('Re-released in ', lang));
    END IF;
END;
/

-- Task 3 --
--Q1--
SELECT TITLE, LENGTH 
FROM FILM F, FILM_CATEGORY CF, CATEGORY C
WHERE F.LENGTH = (SELECT MIN(LENGTH) FROM FILM) 
AND (F.FILM_ID = CF.FILM_ID AND CF.CATEGORY_ID = C.CATEGORY_ID)
AND C.NAME = 'Action';

--Q2--
CREATE VIEW MIN_ACTION_ACTORS AS
SELECT DISTINCT A.ACTOR_ID, A.FIRST_NAME, A.LAST_NAME
FROM FILM_ACTOR FA, ACTOR A
WHERE FA.FILM_ID IN (SELECT F.FILM_ID 
    FROM FILM F, FILM_CATEGORY CF, CATEGORY C
    WHERE F.LENGTH = (SELECT MIN(LENGTH) FROM FILM) 
    AND (F.FILM_ID = CF.FILM_ID AND CF.CATEGORY_ID = C.CATEGORY_ID)
    AND C.NAME = 'Action')
    AND A.ACTOR_ID = FA.ACTOR_ID;

--Q3--
CREATE VIEW V_ACTION_ACTORS_2012 AS
SELECT DISTINCT A.ACTOR_ID, A.FIRST_NAME, A.LAST_NAME
FROM FILM_ACTOR FA, ACTOR A
WHERE FA.FILM_ID IN (SELECT F.FILM_ID 
    FROM FILM F, FILM_CATEGORY CF, CATEGORY C
    WHERE F.RELEASE_YEAR = '2012' 
    AND (F.FILM_ID = CF.FILM_ID AND CF.CATEGORY_ID = C.CATEGORY_ID)
    AND C.NAME = 'Action')
    AND A.ACTOR_ID = FA.ACTOR_ID;

--Q4--
CREATE MATERIALIZED VIEW MV_ACTION_ACTORS_2012
BUILD IMMEDIATE AS
SELECT DISTINCT A.ACTOR_ID, A.FIRST_NAME, A.LAST_NAME
FROM FILM_ACTOR FA, ACTOR A
WHERE FA.FILM_ID IN (SELECT F.FILM_ID 
    FROM FILM F, FILM_CATEGORY CF, CATEGORY C
    WHERE F.RELEASE_YEAR = '2012' 
    AND (F.FILM_ID = CF.FILM_ID AND CF.CATEGORY_ID = C.CATEGORY_ID)
    AND C.NAME = 'Action')
    AND A.ACTOR_ID = FA.ACTOR_ID;

--Q5--
SET TIMING ON;
SELECT * FROM V_ACTION_ACTORS_2012;
SELECT * FROM MV_ACTION_ACTORS_2012;

EXPLAIN PLAN FOR SELECT * FROM V_ACTION_ACTORS_2012;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR SELECT * FROM MV_ACTION_ACTORS_2012;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

-- Task 4 --
--Q1--
SELECT * 
FROM FILM 
WHERE INSTR(DESCRIPTION, 'boat') > 0
ORDER BY TITLE ASC
FETCH NEXT 100 ROWS ONLY;

--Q2--
CREATE INDEX IDX_BOAT ON FILM (INSTR(DESCRIPTION, ???Boat???));

--Q3--
EXPLAIN PLAN FOR
SELECT * 
FROM FILM 
WHERE INSTR(DESCRIPTION, 'Boat') > 0
ORDER BY TITLE ASC
FETCH NEXT 100 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

--Q4--
SELECT COUNT(*)
FROM FILM
WHERE FILM.FILM_ID IN (SELECT F.FILM_ID
    FROM FILM F, FILM I
    WHERE F.RELEASE_YEAR = I.RELEASE_YEAR
    AND F.RATING = I.RATING
    AND F.SPECIAL_FEATURES = I.SPECIAL_FEATURES
    GROUP BY F.FILM_ID
    HAVING COUNT(*) >= 40); 

-- Task 5 --
--Q1--
ANALYZE INDEX PK_FILMID VALIDATE STRUCTURE;
SELECT HEIGHT, LF_BLKS, BLOCKS FROM INDEX_STATS;

--Q2--
EXPLAIN PLAN FOR SELECT /*+RULE*/* FROM FILM WHERE FILM_ID > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

--Q3--
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

--Q4--
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID > 19990;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

--Q5--
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID = 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);







