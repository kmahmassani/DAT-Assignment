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