/*
1.
CREATE DATABASE Hobby;
USE Hobby;
CREATE USER Pawel01 WITH PASSWORD='101052';
GRANT INSERT, SELECT, UPDATE TO Pawel01 

2.
USE Hobby;
CREATE TABLE osoba(
   id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
   imiê VARCHAR(20) NOT NULL,
   dataUrodzenia date NOT NULL CHECK( (DATEDIFF (yy, dataUrodzenia, GETDATE())) >= 18  ),
   plec CHAR(1) NOT NULL,      
);
CREATE TABLE sport(
   id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
   nazwa VARCHAR(20) NOT NULL,
   typ VARCHAR(20) NOT NULL CHECK(typ in ('indywidualny', 'dru¿ynowy', 'mieszany')) DEFAULT 'dru¿ynowy',
   lokacja VARCHAR(20),      
);

CREATE TABLE nauka(
   id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
   nazwa VARCHAR(20) NOT NULL,
   lokacja VARCHAR(20),      
);

CREATE TABLE inne(
   id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
   nazwa VARCHAR(20) NOT NULL,
   lokacja VARCHAR(20),
   towarzysze BIT NOT NULL DEFAULT 1,
);

CREATE TABLE hobby(	
   id INT IDENTITY(1,1) NOT NULL,
   osoba INT NOT NULL,
   typ VARCHAR(10) NOT NULL CHECK(typ IN('sport', 'nauka', 'inne')),  
   PRIMARY KEY (id, osoba, typ)
);

3.
USE Hobby;
SELECT * INTO zwierzak FROM menagerie.dbo.pet
INSERT INTO osoba(imiê, dataUrodzenia, plec)
SELECT Owner,
DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 7200), '1980-01-01'),
CHOOSE(FLOOR(RAND()*4)+1,'m','f', 'm', 'f')
FROM (SELECT DISTINCT Owner FROM menagerie.dbo.pet) as t2;

4.
USE Hobby;
ALTER TABLE osoba ADD nazwisko VARCHAR(50);

ALTER TABLE zwierzak ADD ownerID INT;

UPDATE zwierzak
SET zwierzak.ownerID = osoba.id
FROM zwierzak JOIN osoba ON zwierzak.Owner = osoba.imiê 

ALTER TABLE zwierzak DROP COLUMN owner;

5.
USE Hobby;
ALTER TABLE zwierzak ADD FOREIGN KEY (ownerID) REFERENCES osoba(id); 
ALTER TABLE hobby ADD FOREIGN KEY (osoba) REFERENCES osoba(id); 

6.
USE Hobby;
DBCC CHECKIDENT(inne, RESEED, 7000);

7.
CREATE PROC generuj @name VARCHAR(25), @num INT
AS
BEGIN
	DECLARE @counter INT = 0;
	DECLARE @zajecie VARCHAR(20)
	DECLARE @zajecieID INT = 0;
	DECLARE @osobaID INT = 0;
	WHILE @counter<@num
	BEGIN
				SET @zajecie = 'sport'
				IF @name='osoba'
				BEGIN
				INSERT INTO osoba(imiê,dataUrodzenia,plec,nazwisko)  VALUES ( LEFT(CONVERT(varchar(255), NEWID()),6), DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 7200), '1980-01-01'), CHOOSE( ABS(CHECKSUM(NEWID()) % 2) + 1,'m','f', 'm'),LEFT(CONVERT(varchar(255), NEWID()),6) );
				END
			ELSE IF @name='sport' 
			BEGIN
				INSERT INTO sport(nazwa, typ, lokacja) VALUES ( LEFT(CONVERT(varchar(255), NEWID()),6),  CHOOSE( ABS(CHECKSUM(NEWID()) % 3) + 1,'indywidualny', 'dru¿ynowy', 'mieszany', 'indywidualny'), LEFT(CONVERT(varchar(255), NEWID()),6)); 
			END
			ELSE IF @name='nauka' 
			BEGIN
				INSERT INTO nauka(nazwa, lokacja) VALUES ( LEFT(CONVERT(varchar(255), NEWID()),6), LEFT(CONVERT(varchar(255), NEWID()),6));
			END
			ELSE IF @name='inne' 
			BEGIN
				INSERT INTO inne(nazwa, lokacja, towarzysze)  VALUES ( LEFT(CONVERT(varchar(255), NEWID()),6), LEFT(CONVERT(varchar(255), NEWID()),6),  CHOOSE( ABS(CHECKSUM(NEWID()) % 2) + 1, 1, 0, 1) );
			END
			ELSE IF @name='hobby' 
			BEGIN
				SET @zajecie = (SELECT  CHOOSE( ABS(CHECKSUM(NEWID()) % 3) + 1, 'sport', 'nauka', 'inne'));
				SET @osobaID = (SELECT TOP 1 id FROM osoba ORDER BY NEWID());
				IF @zajecie='sport'
				BEGIN
					SET @zajecieID = (SELECT TOP 1 id FROM sport ORDER BY NEWID());
				END
				ELSE IF @zajecie='nauka' 
				BEGIN
					SET @zajecieID = (SELECT TOP 1 id FROM nauka ORDER BY NEWID());
				END
				ELSE IF @zajecie='inne' 
				BEGIN
					SET @zajecieID = (SELECT TOP 1 id FROM inne ORDER BY NEWID());
				END
			END
				INSERT INTO hobby(id, osoba, typ) VALUES (@zajecieID,@osobaID,@zajecie);	
				SET @counter = @counter + 1;
	END
END
GO
	EXEC generuj 'osoba',1000
	EXEC generuj 'sport', 300;
	EXEC generuj 'nauka', 300
	EXEC generuj 'inne',550;
	EXEC generuj 'hobby', 1300;

	8. 
CREATE VIEW polaczoneHobby AS 
(
	(SELECT id, nazwa, 'sport' AS kategoria FROM sport)
	UNION (SELECT id, nazwa, 'nauka' AS kategoria FROM nauka)
	UNION (SELECT id, nazwa, 'inne' AS kategoria FROM inne)
);

DECLARE @P1 int;  
EXEC sp_prepare @P1 output,N'@id int, @typ VARCHAR(255)',
	N'SELECT DISTINCT nazwa FROM polaczoneHobby WHERE id IN (SELECT id FROM hobby WHERE hobby.typ=@typ AND hobby.osoba=@id) AND kategoria IN (SELECT typ FROM hobby WHERE hobby.typ=@typ AND hobby.osoba=@id)'
EXEC sp_execute @P1, '1','sport';
EXEC sp_unprepare @P1;  

9.

CREATE PROC pokazHobby @userID INT 
AS
BEGIN
SELECT DISTINCT nazwa FROM polaczoneHobby WHERE (id) IN (SELECT id FROM hobby WHERE hobby.osoba=@userID) AND kategoria IN (SELECT typ FROM hobby WHERE hobby.osoba=@userID)
END
EXEC pokazHobby 1

10.

CREATE PROC pokazHobby2 @userID INT 
AS
BEGIN
(SELECT DISTINCT nazwa FROM polaczoneHobby WHERE (id) IN (SELECT id FROM hobby WHERE hobby.osoba=@userID) AND kategoria IN (SELECT typ FROM hobby WHERE hobby.osoba=@userID))
UNION (SELECT DISTINCT type as nazwa FROM zwierzak WHERE ownerID = @userID);
END
GO
EXEC pokazHobby2 1

16.

CREATE VIEW zad16 AS(
SELECT typ, count(*) AS liczba_osob FROM hobby
GROUP BY typ);



18.

CREATE VIEW ad18
AS
(SELECT osoba, count(*) AS hob FROM hobby GROUP BY osoba)

DROP PROC zad18;
GO
CREATE PROCEDURE zad18 (@name VARCHAR(255) OUTPUT, @age INT OUTPUT)
AS
BEGIN

SELECT @name =  (SELECT top 1  imiê FROM osoba
WHERE imiê = (SELECT top 1 imiê FROM osoba JOIN ad18 ON ad18.osoba = osoba.id order by hob desc))

SELECT @age = (SELECT top 1  DATEDIFF(yy, dataUrodzenia, GETDATE()) as wiek FROM osoba
WHERE imiê = (SELECT top 1 imiê FROM osoba JOIN ad18 ON ad18.osoba = osoba.id order by hob desc))
END
GO
DECLARE @nazwa VARCHAR(255), @wiek INT; 
exec zad18 
@name = @nazwa OUTPUT,
@age = @wiek OUTPUT;




17. 
CREATE FUNCTION dbo.countHobbies(@id INT)
RETURNS INT 
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @licz INT
	SET @licz = (SELECT hob FROM ad18 WHERE osoba=@id);
	RETURN(@licz)
END
GO

CREATE FUNCTION dbo.countPets(@id INT)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @licz INT = (SELECT COUNT(*) FROM zwierzak WHERE ownerID=@id)
	RETURN(@licz)
END

CREATE VIEW zadanie17 AS 
SELECT imiê, nazwisko, dbo.countHobbies(id) AS Liczba_Hobby, dbo.countPets(id) AS Liczba_zwierz¹t FROM osoba ORDER BY Liczba_Hobby desc



12.
CREATE TRIGGER zad12 ON sport AFTER DELETE 
AS
BEGIN
	DELETE FROM Hobby WHERE id=(SELECT id FROM deleted) AND typ='sport';
END

13.
CREATE TRIGGER zad13 ON nauka AFTER DELETE
AS
BEGIN
	DELETE FROM Hobby WHERE id=(SELECT id FROM deleted) AND typ='nauka';
END



14. 
CREATE TRIGGER zad14 ON osoba INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM Hobby WHERE osoba=(SELECT id FROM deleted);
	UPDATE zwierzak SET ownerID = (SELECT TOP 1 id FROM osoba WHERE id!=(SELECT id FROM deleted) ORDER BY RAND()) WHERE ownerID=(SELECT id FROM deleted)
	DELETE FROM osoba WHERE id=(SELECT id FROM deleted)
END


11.
DROP TRIGGER zad11;
GO
CREATE TRIGGER zad11 ON hobby INSTEAD OF INSERT
AS
BEGIN
	DECLARE @check INT = (SELECT COUNT(*) FROM osoba JOIN inserted ON osoba.id=inserted.osoba WHERE osoba.id=inserted.osoba)
	DECLARE @check2 INT = (SELECT COUNT(*) FROM sport JOIN inserted ON sport.id=inserted.id WHERE sport.id=inserted.id)
	DECLARE @check3 INT = (SELECT COUNT(*) FROM inne JOIN inserted ON inne.id=inserted.id WHERE inne.id=inserted.id)
	DECLARE @check4 INT = (SELECT COUNT(*) FROM nauka JOIN inserted ON nauka.id=inserted.id WHERE nauka.id=inserted.id)
		DECLARE @id INT = (SELECT id FROM inserted); 
		DECLARE @osoba INT = (SELECT osoba FROM inserted)
		DECLARE @typ VARCHAR(10) = (SELECT typ FROM inserted)
	IF(@check = 0)
	BEGIN
		SET IDENTITY_INSERT osoba ON
		INSERT INTO osoba(id,imiê,dataUrodzenia,plec,nazwisko) VALUES(@osoba,LEFT(CONVERT(varchar(255), NEWID()),6), DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 7200), '1980-01-01'), CHOOSE( ABS(CHECKSUM(NEWID()) % 2) + 1,'m','f', 'm'),LEFT(CONVERT(varchar(255), NEWID()),6) );
	END
		SET IDENTITY_INSERT osoba OFF
	IF(@typ='nauka' AND @check4 = 0)
	BEGIN
	SET IDENTITY_INSERT nauka ON
		INSERT INTO nauka(id,nazwa,lokacja) VALUES(@id, LEFT(CONVERT(varchar(255), NEWID()),6), LEFT(CONVERT(varchar(255), NEWID()),6));
	END
	ELSE IF @typ='sport' AND @check2 = 0
			BEGIN
				SET IDENTITY_INSERT sport ON
				INSERT INTO sport(id,nazwa,typ,lokacja) VALUES (@id, LEFT(CONVERT(varchar(255), NEWID()),6),  CHOOSE( ABS(CHECKSUM(NEWID()) % 3) + 1,'indywidualny', 'dru¿ynowy', 'mieszany', 'indywidualny'), LEFT(CONVERT(varchar(255), NEWID()),6)); 
			END
	ELSE IF @typ='inne' AND @check3 = 0
			BEGIN
				SET IDENTITY_INSERT inne ON
				INSERT INTO inne(id,nazwa,lokacja,towarzysze) VALUES(@id, LEFT(CONVERT(varchar(255), NEWID()),6), LEFT(CONVERT(varchar(255), NEWID()),6),  CHOOSE( ABS(CHECKSUM(NEWID()) % 2) + 1, 1, 0, 1) );
			END

	INSERT INTO hobby(osoba,typ) VALUES(@osoba,@typ);
END
GO
INSERT INTO hobby(osoba,typ) VALUES(444,'sport')
*/