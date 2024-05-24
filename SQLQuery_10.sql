CREATE PROCEDURE CalculateExchangeRateAndChange4
AS
BEGIN
    DECLARE @CurrencyPair VARCHAR(6);
    DECLARE @CurrentRate FLOAT;
    DECLARE @YesterdayRate FLOAT;
    DECLARE @ChangePercent FLOAT;

    -- Cursor to loop through each currency pair
    DECLARE currency_cursor CURSOR FOR
    SELECT DISTINCT ccy_couple
    FROM mytable;

    OPEN currency_cursor;
    FETCH NEXT FROM currency_cursor INTO @CurrencyPair;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get current rate within the last 30 seconds for the current currency pair
        SELECT TOP 1 @CurrentRate = rate
        FROM mytable
        WHERE ccy_couple = @CurrencyPair
        AND rate <> 0
        ORDER BY event_time DESC;

        -- If the current rate is 0, fetch the next available rate
        IF @CurrentRate IS NULL
        BEGIN
            SELECT TOP 1 @CurrentRate = rate
            FROM mytable
            WHERE ccy_couple = @CurrencyPair
            ORDER BY event_time DESC;
        END

        -- Get yesterday's rate for the current currency pair
        SET @YesterdayRate = 1.10; -- Assuming yesterday's rate is 1.10 for all currency pairs

        -- Calculate percentage change
        IF @YesterdayRate IS NOT NULL
        BEGIN
            IF @CurrentRate IS NOT NULL
            BEGIN
                SET @ChangePercent = ((@CurrentRate - @YesterdayRate) / @YesterdayRate) * 100;
            END
            ELSE
            BEGIN
                SET @ChangePercent = -100; -- Rate was active yesterday but not within last 30 seconds
            END
        END
        ELSE
        BEGIN
            SET @ChangePercent = NULL; -- No rate available for yesterday
        END

        -- Print result
        IF @CurrentRate IS NOT NULL
        BEGIN
            PRINT '"' + @CurrencyPair + '", ' + CONVERT(VARCHAR(20), @CurrentRate) + ', "' + COALESCE(CONVERT(VARCHAR(20), @ChangePercent), 'N/A') + '%"';
        END
        ELSE
        BEGIN
            PRINT 'No active rate for ' + @CurrencyPair;
        END

        FETCH NEXT FROM currency_cursor INTO @CurrencyPair;
    END

    CLOSE currency_cursor;
    DEALLOCATE currency_cursor;
END;
