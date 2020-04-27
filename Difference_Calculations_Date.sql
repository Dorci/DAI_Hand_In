DECLARE @StartDate DATETIME = (SELECT MAX(date) FROM StagingDatabase.staging.stage_dim_date)
DECLARE @EndDate DATETIME = GETDATE()

WHILE @StartDate <= @EndDate
    BEGIN
        INSERT INTO StagingDatabase.staging.stage_dim_date (date,
                                            day_name,
                                            month_name)
        SELECT @StartDate,
               DATENAME(weekday, @StartDate),
               DATENAME(month, @StartDate)

        SET @StartDate = DATEADD(dd, 1, @StartDate)
    END