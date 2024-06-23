CREATE TABLE TypUbezpieczenia (
    IDTypu INT PRIMARY KEY IDENTITY(1,1),
    NazwaTypu NVARCHAR(100) NOT NULL,
    Opis NVARCHAR(MAX),
    ZakresPokrycia NVARCHAR(MAX)
);
GO

CREATE TABLE TowarzystwoUbezpieczeniowe (
    IDTowarzystwa INT PRIMARY KEY IDENTITY(1,1),
    Nazwa NVARCHAR(200) NOT NULL,
    Adres NVARCHAR(300)
);
GO

CREATE TABLE AgentUbezpieczeniowy (
    IDAgenta INT PRIMARY KEY IDENTITY(1,1),
    Imie NVARCHAR(100) NOT NULL,
    Nazwisko NVARCHAR(100) NOT NULL,
    NumerTelefonu NVARCHAR(15),
    AdresEmail NVARCHAR(100)
);
GO

CREATE TABLE Ubezpieczony (
    IDUbezpieczonego INT PRIMARY KEY IDENTITY(1,1),
    Imie NVARCHAR(100) NOT NULL,
    Nazwisko NVARCHAR(100) NOT NULL,
    Adres NVARCHAR(300),
    NumerTelefonu NVARCHAR(15),
    AdresEmail NVARCHAR(100)
);
GO

CREATE TABLE Polisa (
    IDPolisy INT PRIMARY KEY IDENTITY(1,1),
    NumerPolisy NVARCHAR(50) NOT NULL,
    DataRozpoczecia DATE NOT NULL,
    DataZakonczenia DATE NOT NULL,
    SumaPlatnosci DECIMAL(18,2) DEFAULT 0;,
    TypUbezpieczeniaID INT,
    IDUbezpieczonego INT,
    IDAgenta INT,
    IDTowarzystwa INT,
    FOREIGN KEY (TypUbezpieczeniaID) REFERENCES TypUbezpieczenia(IDTypu),
    FOREIGN KEY (IDUbezpieczonego) REFERENCES Ubezpieczony(IDUbezpieczonego),
    FOREIGN KEY (IDAgenta) REFERENCES AgentUbezpieczeniowy(IDAgenta),
    FOREIGN KEY (IDTowarzystwa) REFERENCES TowarzystwoUbezpieczeniowe(IDTowarzystwa)
);
GO

CREATE TABLE Platnosc (
    IDPlatnosci INT PRIMARY KEY IDENTITY(1,1),
    IDPolisy INT,
    Kwota DECIMAL(18,2) NOT NULL,
    DataPlatnosci DATE NOT NULL,
    FOREIGN KEY (IDPolisy) REFERENCES Polisa(IDPolisy)
);
GO

INSERT INTO TypUbezpieczenia (NazwaTypu, Opis, ZakresPokrycia) VALUES
('Zdrowotne', 'Ubezpieczenie zdrowotne', 'Opieka medyczna, szpitalna, leki'),
('Samochodowe', 'Ubezpieczenie samochodowe', 'Ochrona pojazdu, OC, AC'),
('Mieszkalne', 'Ubezpieczenie mieszkalne', 'Ochrona mienia, pożar, zalanie');
GO

INSERT INTO TowarzystwoUbezpieczeniowe (Nazwa, Adres) VALUES
('PZU', 'Warszawa, ul. Towarowa 1'),
('Allianz', 'Kraków, ul. Kazimierza Wielkiego 2'),
('Warta', 'Gdańsk, ul. Długa 3');
GO

INSERT INTO AgentUbezpieczeniowy (Imie, Nazwisko, NumerTelefonu, AdresEmail) VALUES
('Jan', 'Kowalski', '123456789', 'jan.kowalski@przyklad.pl'),
('Anna', 'Nowak', '987654321', 'anna.nowak@przyklad.pl'),
('Piotr', 'Wiśniewski', '564738291', 'piotr.wisniewski@przyklad.pl');
GO

INSERT INTO Ubezpieczony (Imie, Nazwisko, Adres, NumerTelefonu, AdresEmail) VALUES
('Adam', 'Mickiewicz', 'Poznań, ul. Kwiatowa 4', '555666777', 'adam.mickiewicz@przyklad.pl'),
('Maria', 'Curie', 'Warszawa, ul. Radiowa 5', '444555666', 'maria.curie@przyklad.pl'),
('Henryk', 'Sienkiewicz', 'Kraków, ul. Literacka 6', '333444555', 'henryk.sienkiewicz@przyklad.pl');
GO

INSERT INTO Polisa (NumerPolisy, DataRozpoczecia, DataZakonczenia, SumaPlatnosci, TypUbezpieczeniaID, IDUbezpieczonego, IDAgenta, IDTowarzystwa) VALUES
('PZ123456', '2024-01-01', '2024-12-31', 0, 1, 1, 1, 1),
('PZ654321', '2024-02-01', '2025-01-31', 0, 2, 2, 2, 2),
('PZ987654', '2024-03-01', '2025-02-28', 0, 3, 3, 3, 3);
GO

INSERT INTO Platnosc (IDPolisy, Kwota, DataPlatnosci) VALUES
(1, 1200.00, '2024-01-01'),
(2, 800.00, '2024-02-01'),
(3, 600.00, '2024-03-01');
GO

CREATE TRIGGER Trg_AfterInsertPolisa
ON Polisa
AFTER INSERT
AS
BEGIN
    DECLARE @NumerPolisy NVARCHAR(50),
            @IDUbezpieczonego INT,
            @Imie NVARCHAR(100),
            @Nazwisko NVARCHAR(100);

    SELECT @NumerPolisy = NumerPolisy, @IDUbezpieczonego = IDUbezpieczonego
    FROM INSERTED;

    SELECT @Imie = Imie, @Nazwisko = Nazwisko
    FROM Ubezpieczony
    WHERE IDUbezpieczonego = @IDUbezpieczonego;

    PRINT N'Nowa polisa została dodana: ' + @NumerPolisy + N' dla ubezpieczonego ' + @Imie + ' ' + @Nazwisko;
END;
GO

CREATE TRIGGER Trg_AfterUpdatePlatnosc
ON Platnosc
AFTER UPDATE, INSERT
AS
BEGIN
    DECLARE @IDPolisy INT,
            @SumaPlatnosci DECIMAL(18,2);

    DECLARE cursor_Platnosci CURSOR FOR
    SELECT DISTINCT IDPolisy
    FROM INSERTED;

    OPEN cursor_Platnosci;

    FETCH NEXT FROM cursor_Platnosci INTO @IDPolisy;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @SumaPlatnosci = SUM(Kwota)
        FROM Platnosc
        WHERE IDPolisy = @IDPolisy;

        UPDATE Polisa
        SET SumaPlatnosci = @SumaPlatnosci
        WHERE IDPolisy = @IDPolisy;

        FETCH NEXT FROM cursor_Platnosci INTO @IDPolisy;
    END;

    CLOSE cursor_Platnosci;
    DEALLOCATE cursor_Platnosci;
END;
GO

CREATE PROCEDURE DodajPolise
    @NumerPolisy NVARCHAR(50),
    @DataRozpoczecia DATE,
    @DataZakonczenia DATE,
    @TypUbezpieczeniaID INT,
    @IDUbezpieczonego INT,
    @IDAgenta INT,
    @IDTowarzystwa INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Polisa WHERE NumerPolisy = @NumerPolisy)
    BEGIN
        PRINT N'Polisa o numerze ' + @NumerPolisy + N' już istnieje.';
        RETURN;
    END

    INSERT INTO Polisa (NumerPolisy, DataRozpoczecia, DataZakonczenia, SumaPlatnosci, TypUbezpieczeniaID, IDUbezpieczonego, IDAgenta, IDTowarzystwa)
    VALUES (@NumerPolisy, @DataRozpoczecia, @DataZakonczenia, 0, @TypUbezpieczeniaID, @IDUbezpieczonego, @IDAgenta, @IDTowarzystwa);
END;
GO

CREATE PROCEDURE DodajPlatnosc
    @IDPolisy INT,
    @Kwota DECIMAL(18,2),
    @DataPlatnosci DATE
AS
BEGIN
    DECLARE @DataZakonczenia DATE;

    SELECT @DataZakonczenia = DataZakonczenia
    FROM Polisa
    WHERE IDPolisy = @IDPolisy;

    IF @DataPlatnosci > @DataZakonczenia
    BEGIN
        PRINT N'Płatność nie może być zrealizowana po zakończeniu polisy.';
        RETURN;
    END

    INSERT INTO Platnosc (IDPolisy, Kwota, DataPlatnosci)
    VALUES (@IDPolisy, @Kwota, @DataPlatnosci);
END;
GO

-- Dodawanie nowej polisy
EXEC DodajPolise 
    @NumerPolisy = 'PZ445566',
    @DataRozpoczecia = '2024-07-01',
    @DataZakonczenia = '2025-06-30',
    @TypUbezpieczeniaID = 2,
    @IDUbezpieczonego = 2,
    @IDAgenta = 2,
    @IDTowarzystwa = 2;
GO

-- Dodawanie nowej płatności
EXEC DodajPlatnosc 
    @IDPolisy = 2,
    @Kwota = 2000.00,
    @DataPlatnosci = '2024-07-01';
GO