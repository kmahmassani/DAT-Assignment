## Question 1:

### a)

![ER Diagram](relationships.real.large.png)

```sql
--Operators table contains all the operator codes, along with their names.  Names are unique for each operator
CREATE TABLE Operators (
	Code INT PRIMARY KEY,
	Name VARCHAR(100) UNIQUE
);

-- BikeType allows us to constrain the type of bikes allowed to either Manual or Electric
CREATE TYPE BikeType AS ENUM (
	'Manual',
	'Electric'
);

-- The Bikes table references the Operators table for Operator Codes, primary key is a combination of OperCode 
-- and OperBikeID, Capacity may be null to allow for manual bikes
CREATE TABLE Bikes (
	OperCode INT NOT NULL REFERENCES Operators(Code),
	OperBikeID VARCHAR(100) NOT NULL,
	BikeType BikeType NOT NULL,
	Capacity INT,
	PRIMARY KEY (OperCode, OperBikeID)
);

CREATE TABLE Citys (
	ID INT GENERATED ALWAYS AS IDENTITY,
	Country VARCHAR(100) NOT NULL,
	City VARCHAR(100) NOT NULL,
	PRIMARY KEY (ID),
	UNIQUE (Country, City)
);

CREATE TABLE DOCKS (
	ID VARCHAR(100) PRIMARY KEY,
	OperCode INT NOT NULL REFERENCES Operators(Code),
	CityID INT NOT NULL REFERENCES Citys(ID),
	Latitude DOUBLE PRECISION NOT NULL,
	Longitude DOUBLE PRECISION NOT NULL,
	HasElectric BOOL NOT NULL
);

-- Journeys references Docks table twice, once for start dock and another time for end dock
-- Primary key is chosen because logically the same bike can only start one trip at a time
CREATE TABLE Journeys (
	BikeOperCode INT NOT NULL,
	BikeOperBikeID VARCHAR(100) NOT NULL,
	StartDock VARCHAR(100) NOT NULL REFERENCES Docks(ID),	
	StartTime TIMESTAMP NOT NULL,
	DestDock VARCHAR(100) REFERENCES Docks(ID), 
	EndTime TIMESTAMP,	
	-- Assumed that we would want to allow nulls for destination dock and end time, 
	-- so that we can have info for journeys that have started but not finished yet
	PRIMARY KEY (BikeOperCode, BikeOperBikeID, StartTime),
	FOREIGN KEY (BikeOperCode, BikeOperBikeID) REFERENCES Bikes (OperCode, OperBikeID)
);
```

### b)

### TODO

### c)

#### C1: All docks with lat > 90

```{ (id) | ∃o,co,ci,latitude,l,h Docks(id,o,co,ci,latitude,l,h) ∧ latitude > 90 }```

 ```sql
--Make sure latitude is not larger than 90
ALTER TABLE Docks ADD CONSTRAINT LAT_CHECK CHECK (latitude <= 90);
```

#### C2: All Journeys with start time after end time

```{ (bO,bId,sD,startTime,dD,endTime) | Journeys(bO,bId,sD,startTime,dD,endTime) ∧ startTime > endTime }```

 ```sql
--Make sure start time is not after end time
ALTER TABLE Journeys ADD CONSTRAINT START_CHECK CHECK (starttime <= endtime);
```

#### C3: Manual Bikes with Capacity

```{ (oC, oB, "Manual", cap) | Bikes(oC, oB, "Manual", cap) ∧ cap > 0 }```

 ```sql
--Make sure that manual bikes have no capacity
ALTER TABLE Bikes ADD CONSTRAINT CAP_CHECK CHECK (NOT (biketype = 'Manual' AND (capacity is not NULL OR capacity > 0)))
```

#### C4: All electric bikes that end journeys at non-electric docks

```{ (oCode, oBike, "Electric", c) | Bikes(oCode, oBike, "Electric", c) ∧ Journeys(oCode, oBike, sd, st, destDoc, et) ∧ Docks(destDoc, oc, c1, c2, l, l1, false)}```

We cannot create an SQL Constraint statement to stop electric bikes from docking at non-electric docks, because a constraint condition can only refer to columns in the current row, and the required journey and dock info are in other tables.

## Question 2:

### a) All bikes with Operator "Santander Cycles London"

π<sub>OperCode,OperBikeID,BikeType,Capacity</sub>(Bikes ⋈ π<sub>OperCode</sub>(σ<sub>name~'Santander Cycles London'</sub>(Operators)))

### b) All bikes with Journeys ending at "UK-Oxford-536" or "UK-Oxford-435"

```{ (oCode, oBike, t, c) | Bikes(oCode, oBike, t, c) ∧ (Journeys(oCode, oBike, sd, st, "UK-Oxford-536", et) ∨ Journeys(oCode, oBike, sd1, st1, "UK-Oxford-435", et1)) ) }```

### c) All bikes which have never travelled to "UK-London-116"

```{ (oCode, oBike, t, c) | Bikes(oCode, oBike, t, c) ∧ ¬Journeys(oCode, oBike, sd, st, "UK-London-116", et) }```

### d) All bikes which started at the same dock on 2 consecutive days

```{ (oCode, oBike, t, c) | Bikes(oCode, oBike, t, c) ∧ Journeys(oCode, oBike, sd, st, ed, et) ∧ Journeys(oCode, oBike, sd, st + 1, ed1, et1)}```

### e) All docks where at least two bikes started from

````{ (dockId, oCode, c, la, lo, ele) | Docks(dockId, oCode, c, la, lo, ele) ∧ Journeys(oCode1, oBike1, dockId, st, ed, et) ∧ Journeys(oCode2, oBike2, dockId, st2, ed2, et2) ∧ ((oCode1 ≠ oCode2) ∨ (oBike1 ≠ oBike2)) }````

### f) Top 10 busiest docks

We cannot express this relation as there is no operator to count (or other aggregate functions) the number of journeys ending at each dock.

### g) Docks reached from "UK-London-231" by Santandar bike "4928302"

We cannot express this relation as there is no upper bound to the number of journeys.  If there was an upper bound such as *n*, we could just join up to *n* times on the Journeys relation.

## Question 3:

### a) All bikes with Operator "Santander Cycles London"

 ```sql
 SELECT *
FROM BIKES b 
INNER JOIN OPERATORS o on b.opercode = o.code
WHERE o.name = 'Santander Cycles London'
```

### b) All bikes with Journeys ending at "UK-Oxford-536" or "UK-Oxford-435"

 ```sql
SELECT *
FROM BIKES b 
INNER JOIN Journeys j on b.opercode = j.bikeopercode AND b.operbikeid = j.bikeoperbikeid
INNER JOIN Docks d on j.destdock = d.id
WHERE d.id in ('UK-Oxford-536','UK-Oxford-435')
```

### c) All bikes which have never travelled to "UK-London-116"

 ```sql
SELECT *
FROM BIKES b 
WHERE NOT EXISTS 
                (SELECT 1 
                 FROM Journeys j
                 INNER JOIN Docks d on j.destdock = d.id
                 WHERE b.opercode = j.bikeopercode AND b.operbikeid = j.bikeoperbikeid
                 AND d.id = 'UK-London-116')
```

### d) All bikes which started at the same dock on 2 consecutive days

 ```sql

```