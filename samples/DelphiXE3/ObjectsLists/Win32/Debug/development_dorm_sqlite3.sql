DROP TABLE IF EXISTS PEOPLE;
CREATE TABLE PEOPLE(  ID INTEGER primary key, FIRST_NAME VARCHAR(50), LAST_NAME VARCHAR(50), AGE INTEGER);
DROP TABLE IF EXISTS LAPTOPS;
CREATE TABLE LAPTOPS(  ID INTEGER primary key, MODEL VARCHAR(50), RAM INTEGER, NR_OF_CORES INTEGER, ID_PERSON INTEGER);
DROP TABLE IF EXISTS BUTTONS;
CREATE TABLE BUTTONS(  ID INTEGER primary key, NAME VARCHAR(50), CAPTION VARCHAR(50), POSITION_TOP INTEGER, POSITION_LEFT INTEGER, SIZE_WIDTH INTEGER, SIZE_HEIGHT INTEGER);
