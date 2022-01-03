create database Laboratory
go
	use Laboratory
	go
create table G_GERMS
(ID int  identity PRIMARY KEY,
NAME VARCHAR (20)	NOT NULL UNIQUE,
SHORT_DESC VARCHAR (50),
ID_DATE DATE	NOT NULL,
MEDICINE_ID	INT,
MEDICINE_DATE	DATE)
go
create table G_MEDICINE
(ID	NUMERIC identity PRIMARY KEY,
NAME VARCHAR(20)	NOT NULL UNIQUE)
go
create table G_TEST
(GERM_ID int foreign key references G_GERMS(ID),
MEDICIN_ID	NUMERIC foreign key references G_MEDICINE(ID),
TEST_DATE	DATE,
REACTION_TYPE	VARCHAR (10),
constraint REACTION_TYPE check (REACTION_TYPE='dead'or REACTION_TYPE='dying'or
REACTION_TYPE ='alive') )
go
create table G_ARCHIVE(
GERM_NAME	VARCHAR (20) ,
GERM_ID	NUMERIC(3)  ,
TEST_DATE	DATETIME,
MEDICINE_NAME	VARCHAR (20),
REACTION_TYPE	VARCHAR (10))
go
create table G_EXCEPTION_TABLE
(MESSAGE	VARCHAR (300),
MessageDate	Datetime)
                     ---------------------------
go
insert into G_GERMS values('PASTI'  ,null,       '01-01-1997' ,1,null);
insert into G_GERMS values('KA',	'VERY SLIM', '04-22-1997' ,1,null);
insert into G_GERMS values('YOCUS',	'VERY OLD',	 '01-30-1998' ,null,null);
insert into G_GERMS values('KARUS',  null,       '02-05-1999' ,null,null);
insert into G_GERMS values('BAKTUS'	,null,	     '05-18-1999' ,null,null);
                     ------------------------
insert into G_MEDICINE values('UNTI');
insert into G_MEDICINE values('ACAMOL');
insert into G_MEDICINE values('PENITZILIN'); 
insert into G_MEDICINE values('ASPARIN');
                     -------------------------
insert into G_TEST values(1,1, '02-01-1997','dying');
insert into G_TEST values(2,1, '06-22-1997','dead');
insert into G_TEST values(3,4, '01-30-1999','alive');
insert into G_TEST values(4,2, '07-18-1999','dying');
insert into G_TEST values(4,3, '08-18-1999','dying');

