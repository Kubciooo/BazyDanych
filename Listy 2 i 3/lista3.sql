
USE Hobby;
/*
1.

 CREATE INDEX index_osoba ON osoba(imiê) tutaj ju¿ by³, z automatu mssql robi clustered index(czyli posortowana lista) przy dodawaniu klucza g³ównego 
 CREATE INDEX index_osoba2 ON osoba(dataUrodzenia) 
 CREATE CLUSTERED INDEX index_sport ON sport(nazwa, id) 
 CREATE INDEX index_inne ON inne(nazwa,id) 
 CREATE INDEX index_hobby ON hobby(osoba,id,typ)
 
 2.
	SELECT plec FROM osoba WHERE imiê LIKE 'A%' 
	
	SELECT id, nazwa FROM sport WHERE typ LIKE 'dru¿ynowy' tutaj jest u¿ywany index 

	SELECT s1.nazwa, s2.nazwa FROM sport s1 JOIN sport s2 ON s1.lokacja=s2.lokacja WHERE s1.id < s2.id AND s1.typ='indywidualny' AND s2.typ='indywidualny' 

	SELECT imiê, nazwisko FROM osoba WHERE dataUrodzenia < '2000-01-01'

	SELECT top 1 id, COUNT(*) as liczba FROM hobby GROUP BY id order BY liczba desc

	SELECT TOP 1 imiê FROM osoba JOIN zwierzak ON zwierzak.ownerID=osoba.id WHERE zwierzak.type='dog' ORDER BY dataUrodzenia asc


3.

CREATE TABLE zawody(
id INT PRIMARY KEY,
nazwa VARCHAR(255),
pensja_min INT,
pensja_max INT, 
); 
GO
CREATE TABLE praca(
id_zawodu INT, 
id_osoby INT,
zarobek INT
);
GO
DECLARE @id INT = 0;
DECLARE @min INT
WHILE @id < 10
BEGIN
	SET @min = (ROUND(5000 * RAND() + 100,0))
	INSERT INTO zawody(id,nazwa,pensja_min,pensja_max) VALUES (@id, LEFT(CONVERT(varchar(255), NEWID()),6), @min, @min+(ROUND(3000 * RAND() + 1250,0)))
	SET @id = @id+1;
END

GO 
DELETE FROM praca;
GO
DECLARE kursor CURSOR FOR SELECT id FROM osoba;
OPEN kursor
DECLARE @id_osoby INT
DECLARE @id_zawodu INT
DECLARE @hajs INT
FETCH NEXT FROM kursor INTO @id_osoby 
WHILE(@@FETCH_STATUS = 0)
BEGIN 
	SET @id_zawodu = (SELECT FLOOR(RAND()*(9-1+1))); 
	SET @hajs = (SELECT FLOOR(RAND()*(pensja_max-pensja_min+1)+pensja_min) FROM zawody WHERE id=@id_zawodu);
	INSERT INTO praca(id_zawodu,id_osoby,zarobek) VALUES(@id_zawodu, @id_osoby, @hajs)
FETCH NEXT FROM kursor INTO @id_osoby; 
END
CLOSE kursor
DEALLOCATE kursor;

zad.4
DROP PROC ad4;
GO
CREATE PROC ad4 @agg varchar(20), @kol varchar(25)
AS
BEGIN
	DECLARE @P1 int; 
	DECLARE @test nvarchar(255)
	IF(@kol='dataUrodzenia' AND @agg IN('AVG','STD, VAR_POP'))
	BEGIN
		SET @test = 'SELECT '+@agg+'(DATEDIFF (yy, dataUrodzenia, GETDATE()))' + ' FROM osoba';
		EXEC sp_prepare @P1 output,N'', @test
		EXEC sp_execute @P1;
		EXEC sp_unprepare @P1; 
	END

	ELSE IF(@agg IN ('COUNT', 'GROUP_CONCAT', 'MIN', 'MAX', 'AVG', 'STD', 'VAR_POP') AND
       @kol IN ('id', 'imiê', 'nazwisko', 'dataUrodzenia', 'plec'))
	BEGIN 
		SET @test  = 'SELECT '+@agg+ '('+@kol+')' + ' FROM osoba';
		EXEC sp_prepare @P1 output,N'', @test
		EXEC sp_execute @P1;
		EXEC sp_unprepare @P1; 
	END
	ELSE RAISERROR('Wrong parameters', 16, 1)
END
GO
EXEC ad4 'MINA', 'dataUrodzenia'



zad.5 
DROP TABLE has³a;
GO
CREATE TABLE has³a(
id_osoby INT PRIMARY KEY,
has³o nvarchar(250)
)

GO
CREATE TRIGGER ad5 ON has³a INSTEAD OF INSERT
AS
BEGIN
	DECLARE @id_osoby INT = (SELECT TOP 1 id_osoby FROM inserted)
	DECLARE @has³o nvarchar(20) = (SELECT TOP 1 has³o FROM inserted)
	DECLARE @HashThis nvarchar(20) = CONVERT(nvarchar(20), @has³o)
	DECLARE @Hashed nvarchar(250) = (SELECT HASHBYTES('MD5',@HashThis))
	INSERT INTO has³a(id_osoby, has³o) VALUES(@id_osoby, @Hashed)
END

INSERT INTO has³a(id_osoby, has³o) VALUES(2, 'xd')

GO
DROP PROC zad5
GO
CREATE PROC zad5 @id INT, @has³o varchar(20), @data DATE OUTPUT
AS
BEGIN
	DECLARE @HashThis nvarchar(20) = CONVERT(nvarchar(20), @has³o)
	DECLARE @Hashed nvarchar(250) = (SELECT HASHBYTES('MD5',@HashThis))
	DECLARE @Poprawne nvarchar(250) = (SELECT TOP 1 has³o FROM has³a WHERE id_osoby = @id)
	DECLARE @Pid INT = (SELECT TOP 1 id FROM osoba WHERE id=@id)
	IF(@Poprawne IS NOT NULL AND @Pid IS NOT NULL)
	BEGIN
		IF(@Hashed = @Poprawne) 
		BEGIN
					PRINT @Pid
			SET @data = (SELECT dataUrodzenia FROM osoba WHERE id=@id) 
			RETURN; 
		END
		ELSE 
		BEGIN
			SET @data = DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 7200), '1980-01-01')
		END
	END
	ELSE
	BEGIN
			PRINT N'Nie ma takiej osoby!'
			RETURN 0;
	END
END
DECLARE @test DATE; 
EXEC zad5 
@id=2,
@has³o='xdd',
@data = @test OUTPUT
SELECT @test AS 'data urodzenia'


zad. 7

USE Hobby;
CREATE FUNCTION dwumian(@nn INT, @kk int) 
RETURNS INT
AS
BEGIN
	DECLARE @wynik INT
	;WITH  help(n,k,v) AS
	(
		SELECT @nn-@kk, 0, 1
		UNION ALL
		SELECT n+1 AS n, k+1 as k,  (v*(n+1) ) / (k+1) as v
		FROM help WHERE n < @nn
	)
	 SELECT @wynik =  (SELECT v FROM help WHERE k = @kk)
	 RETURN @wynik
END


DECLARE @P1 int;  
EXEC sp_prepare @P1 output,N'@id int, @typ VARCHAR(255)',
	N'SELECT DISTINCT nazwa FROM polaczoneHobby WHERE id IN (SELECT id FROM hobby WHERE hobby.typ=@typ AND hobby.osoba=@id) AND kategoria IN (SELECT typ FROM hobby WHERE hobby.typ=@typ AND hobby.osoba=@id)'
EXEC sp_execute @P1, '1','sport';
EXEC sp_unprepare @P1;  




zad. 8

CREATE PROC transakcja @zawod varchar(255)  
AS
BEGIN
	DECLARE @max INT = (SELECT pensja_max FROM zawody WHERE nazwa=@zawod) 
	BEGIN TRANSACTION dodatek
	UPDATE praca SET zarobek = zarobek*1.1 WHERE id_zawodu = (SELECT id FROM zawody WHERE nazwa=@zawod)
	IF(@max < (SELECT MAX(zarobek) FROM praca WHERE id_zawodu = (SELECT id FROM zawody WHERE nazwa=@zawod)))
	BEGIN
		PRINT 'XD'
		ROLLBACK TRANSACTION dodatek
	END
	ELSE 
	BEGIN
		PRINT 'da³o radê!' 
		COMMIT TRANSACTION dodatek 
	END
END 

INSERT INTO zawody(id,nazwa,pensja_min, pensja_max) VALUES (10,'test',0,10000); 
INSERT INTO praca(id_zawodu,id_osoby,zarobek) VALUES(10, 5, 1000);
EXEC transakcja 'test';
SELECT zarobek FROM praca WHERE id_zawodu = 10;

*/