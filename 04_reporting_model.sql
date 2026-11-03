USE UberRides;
GO

/* ---------- 1. Fact table: one row per booking ---------- */

SELECT *
INTO dbo.FactRides
FROM dbo.v_rides_clean;

ALTER TABLE dbo.FactRides
ALTER COLUMN RideKey bigint NOT NULL;

ALTER TABLE dbo.FactRides
ADD CONSTRAINT PK_FactRides PRIMARY KEY (RideKey);

CREATE INDEX IX_FactRides_Date ON dbo.FactRides (RideDate);
GO


/* ---------- 2. Date table: every day of 2024 ---------- */

CREATE TABLE dbo.DimDate (
    DateKey      date         NOT NULL PRIMARY KEY,
    [Year]       int          NOT NULL,
    MonthNumber  int          NOT NULL,
    MonthName    nvarchar(20) NOT NULL,
    MonthShort   nchar(3)     NOT NULL,
    DayOfWeekNum int          NOT NULL,   -- 1 = Monday
    DayName      nvarchar(20) NOT NULL,
    IsWeekend    bit          NOT NULL
);

WITH Calendar AS (
    SELECT CAST('2024-01-01' AS date) AS d
    UNION ALL
    SELECT DATEADD(day, 1, d) FROM Calendar WHERE d < '2024-12-31'
)
INSERT INTO dbo.DimDate
SELECT
    d,
    YEAR(d),
    MONTH(d),
    DATENAME(month, d),
    LEFT(DATENAME(month, d), 3),
    ((DATEPART(weekday, d) + @@DATEFIRST - 2) % 7) + 1,
    DATENAME(weekday, d),
    CASE WHEN ((DATEPART(weekday, d) + @@DATEFIRST - 2) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END
FROM Calendar
OPTION (MAXRECURSION 400);
GO


/* ---------- 3. Link them ---------- */

ALTER TABLE dbo.FactRides
ADD CONSTRAINT FK_FactRides_Date
    FOREIGN KEY (RideDate) REFERENCES dbo.DimDate (DateKey);
GO


/* ---------- 4. Checks ---------- */

-- 150000 and 366 (2024 is a leap year)
SELECT
    (SELECT COUNT(*) FROM dbo.FactRides) AS FactRows,
    (SELECT COUNT(*) FROM dbo.DimDate)   AS CalendarDays;

-- 0: every ride has a matching date
SELECT COUNT(*) AS RidesWithoutDate
FROM dbo.FactRides AS f
LEFT JOIN dbo.DimDate AS d ON f.RideDate = d.DateKey
WHERE d.DateKey IS NULL;
