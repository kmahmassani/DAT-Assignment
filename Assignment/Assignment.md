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
 OperBikeID INT NOT NULL,
 BikeType BikeType NOT NULL,
 Capacity INT,
 PRIMARY KEY (OperCode, OperBikeID)
);

CREATE TABLE DOCKS (
 ID INT PRIMARY KEY,
 OperCode INT NOT NULL REFERENCES Operators(Code),
 Country VARCHAR(100) NOT NULL,
 City VARCHAR(100) NOT NULL,
 Latitude DOUBLE PRECISION NOT NULL,
 Longitude DOUBLE PRECISION NOT NULL,
 HasElectric BOOL NOT NULL
);

-- Journeys references Docks table twice, once for start dock and another time for end dock
-- Primary key is chosen because logically the same bike can only start one trip at a time
CREATE TABLE Journeys (
 BikeOperCode INT NOT NULL,
 BikeOperBikeID INT NOT NULL,
 StartDock INT NOT NULL REFERENCES Docks(ID),
 StartTime TIMESTAMP NOT NULL,
 DestDock INT REFERENCES Docks(ID),
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

### a)
π<sub>OperCode,OperBikeID,BikeType,Capacity</sub>(Bikes ⋈ π<sub>OperCode</sub>(σ<sub>name~'Santander Cycles London'</sub>(Operators)))

### b)
