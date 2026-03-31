



CREATE DATABASE PROJECT1 
USE  PROJECT1

--CREATING TABLES--
GO

CREATE TABLE date_event(
date_id INT PRIMARY KEY,
full_date DATETIME,
Year INT,
Month INT,
Day INT
)

CREATE TABLE Flare_Class(
class_id INT IDENTITY(1,1) PRIMARY KEY,
class_name VARCHAR (255),
min_intensity FLOAT,
max_intensity FLOAT

)

CREATE TABLE Continents(
continent_id INT IDENTITY(1,1) PRIMARY KEY,
continents_name VARCHAR (255),
min_latitude FLOAT,
max_latitude FLOAT,
min_longitude FLOAT,
max_longitude FLOAT,

)

CREATE TABLE Flares(
flare_id INT IDENTITY(1,1) PRIMARY KEY,
event_date DATETIME,
solar_flare_class VARCHAR(255),
flare_intensity FLOAT,
geomagnetic_index_Kp INT,
solar_wind_speed FLOAT,
solar_wind_density FLOAT,
flare_duration_minutes INT,
date_id INT ,
class_id INT

CONSTRAINT fk_flares_Date FOREIGN KEY (date_id) REFERENCES date_event(date_id),
CONSTRAINT fk_flares_class FOREIGN KEY (class_id) REFERENCES Flare_Class(class_id)

)

CREATE TABLE EQ(
event_id INT IDENTITY(1,1) PRIMARY KEY,
event_time DATETIME,
Place VARCHAR(255),
Latitude FLOAT,
Longitude FLOAT,
Depth FLOAT,
Mag FLOAT,
dmin FLOAT,
date_id INT,
continent_id INT

CONSTRAINT fk_EQ_Date FOREIGN KEY (date_id) REFERENCES date_event(date_id),
CONSTRAINT fk_EQ_Continent FOREIGN KEY (continent_id) REFERENCES Continents(continent_id)
)

GO
-- FILLING DATE_EVENT TABLE -- 
-- CTE THAT FILLING PK COLUMN WITH DAYS IN YEAR (365 DAYS) --
WITH dates AS (
SELECT CAST('2022-01-01' AS DATETIME) AS full_date
UNION ALL
SELECT DATEADD(DAY,1,full_date) FROM dates
WHERE full_date < '2022-12-31'
)
INSERT INTO date_event (date_id,full_date,Year,Month,Day)
SELECT YEAR(full_date)*10000+MONTH(full_date)*100+DAY(full_date) AS date_id,
full_date,
YEAR(full_date),
MONTH(full_date),
DAY(full_date)
FROM dates
OPTION (MAXRECURSION 0) -- DISABLING DEFAULT STAT(100) OF MAXRECURSION

-- FILLING Flare_Class TABLE --

INSERT INTO Flare_Class (class_name,min_intensity,max_intensity)
VALUES 
('C',0.1,30),
('M',31.1,65),
('X',66.1,130)

-- FILLING Continents TABLE -- 

INSERT INTO Continents (continents_name,min_latitude,max_latitude,min_longitude,max_longitude) 
VALUES
('Africa',-35,37,-18,52),
('Europa',35,72,-25,60),
('Asia',1,77,26,180),
('North America',7,83,-168,-52),
('South America',-56,13,-82,-34),
('Australia & Oceania',-50,0,110,180),
('Antarctica',-90,-60,-180,180),
('Other/Ocean',-90,90,-180,180)


-- FILLING FLARES TABLE -- 

INSERT INTO Flares (event_date,solar_flare_class,flare_intensity,geomagnetic_index_Kp,solar_wind_speed,solar_wind_density,flare_duration_minutes)
SELECT event_date,solar_flare_class,flare_intensity,geomagnetic_index_Kp,solar_wind_speed,solar_wind_density,flare_duration_minutes
FROM flares_ext

-- UPDATING FK COLOMNS--  

UPDATE Flares SET date_id = YEAR(event_date)*10000+MONTH(event_date)*100+DAY(event_date) 
UPDATE Flares SET class_id = CASE  solar_flare_class  WHEN 'C' THEN 1 WHEN 'M' THEN 2 WHEN 'X' THEN 3 END

-- FILLING EQ TABLE --

INSERT INTO EQ (event_time,Place,Latitude,Longitude,Depth,Mag,dmin) 
SELECT event_time,Place,Latitude,Longitude,Depth,Mag,dmin FROM EQ2022_ext

-- UPDATING FK COLOMNS-- 

UPDATE EQ SET date_id = YEAR(event_time)*10000+MONTH(event_time)*100+DAY(event_time) 
UPDATE EQ SET continent_id = 
CASE
WHEN (Latitude BETWEEN -40 AND 40) AND (Longitude BETWEEN -30 AND 60) THEN 1 
WHEN (Latitude BETWEEN 30 AND 75) AND (Longitude BETWEEN -35 AND 70) THEN 2 
WHEN (Latitude BETWEEN -15 AND 85) AND (Longitude BETWEEN 25 AND 190) THEN 3 
WHEN (Latitude BETWEEN 5 AND 85) AND (Longitude BETWEEN -180 AND -30) THEN 4 
WHEN (Latitude BETWEEN -60 AND 20) AND (Longitude BETWEEN -95 AND -30) THEN 5 
WHEN (Latitude BETWEEN -55 AND 10) AND (Longitude BETWEEN 90 AND 190) THEN 6 
WHEN (Latitude BETWEEN -90 AND -90) AND (Longitude BETWEEN -180 AND 180) THEN 7
WHEN (Latitude BETWEEN -90 AND 90) AND (Longitude BETWEEN -180 AND 180) THEN 8
END

/*
SELECT * 
FROM Flare_Class
SELECT *
FROM Flares
SELECT *
FROM EQ
SELECT *
FROM date_event
SELECT *
FROM Continents

TRUNCATE TABLE Flares
 
DROP TABLE Flares
DROP TABLE EQ
DROP TABLE Continents
DROP TABLE date_event
DROP TABLE Flare_Class

*/



--EVENTS PER DATE--

SELECT de.full_date,COUNT(DISTINCT E.event_id) AS EQCNT,COUNT(DISTINCT F.flare_id) AS FlareCNT
FROM date_event DE LEFT JOIN EQ E ON DE.date_id=E.date_id
LEFT JOIN Flares F ON DE.date_id=F.date_id
GROUP BY de.full_date

-- EQ per Continets--


SELECT tab.continents_name,SUM(TAB.EQCNT) AS EQ_CNT
FROM
(SELECT continents_name,COUNT(DISTINCT E.event_id) AS EQCNT
FROM date_event DE LEFT JOIN EQ E ON DE.date_id=E.date_id
RIGHT JOIN Continents C ON E.continent_id=C.continent_id
GROUP BY continents_name) tab
GROUP BY tab.continents_name



-- EQ per Quarters--

SELECT T.QQ, SUM(t.EQCNT) AS EQ_CNT
FROM
(SELECT de.full_date,COUNT(DISTINCT E.event_id) AS EQCNT,DATEPART(QQ,de.full_date) AS QQ
FROM date_event DE LEFT JOIN EQ E ON DE.date_id=E.date_id
LEFT JOIN Flares F ON DE.date_id=F.date_id
LEFT JOIN Continents C ON E.continent_id=C.continent_id
GROUP BY de.full_date
) AS T
GROUP BY T.QQ



