CREATE PROCEDURE CalculateExchangeRateB
AS
BEGIN
    DECLARE @CurrencyPair VARCHAR(6);
    DECLARE @CurrentRate FLOAT;
    DECLARE @YesterdayRate FLOAT;
    DECLARE @ChangePercent FLOAT;
    DECLARE @CurrentTime BIGINT;
    DECLARE @ThirtySecondsAgo BIGINT;

    -- Get current time in milliseconds
    SET @CurrentTime = DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', GETUTCDATE());
    
    -- Calculate time 30 seconds ago
    SET @ThirtySecondsAgo = @CurrentTime - 30000;

    -- Cursor to loop through each currency pair with recent activity
    DECLARE currency_cursor CURSOR FOR
    SELECT DISTINCT ccy_couple
    FROM mytable
    WHERE event_time >= @ThirtySecondsAgo; -- Active within the last 30 seconds

    OPEN currency_cursor;
    FETCH NEXT FROM currency_cursor INTO @CurrencyPair;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get latest rate (not zero) for the current currency pair within the last 30 seconds
        SELECT TOP 1 @CurrentRate = rate
        FROM mytable
        WHERE ccy_couple = @CurrencyPair
        AND rate <> 0
        AND event_time >= @ThirtySecondsAgo -- Active within the last 30 seconds
        ORDER BY event_time DESC;

        -- Set yesterday's rate for the current currency pair
        SET @YesterdayRate = CASE @CurrencyPair
            WHEN 'EURUSD' THEN 1.0500
            WHEN 'NZDUSD' THEN 0.6660
            WHEN 'AUDUSD' THEN 0.6950
            WHEN 'EURGBP' THEN 0.8260
            WHEN 'GBPUSD' THEN 1.3000
            ELSE NULL -- Default value if yesterday's rate is not defined for the currency pair
        END;

        -- Calculate percentage change
        IF @YesterdayRate IS NOT NULL AND @CurrentRate IS NOT NULL
        BEGIN
            SET @ChangePercent = ((@CurrentRate - @YesterdayRate) / @YesterdayRate) * 100;
        END
        ELSE
        BEGIN
            SET @ChangePercent = NULL; -- No rate available for yesterday or current rate is zero
        END

        -- Print result with "/" between currencies
        IF @CurrentRate IS NOT NULL
        BEGIN
            DECLARE @FormattedCurrencyPair VARCHAR(20);
            SET @FormattedCurrencyPair = REPLACE(@CurrencyPair, 'USD', '/USD');
            PRINT '"' + @FormattedCurrencyPair + '", ' + CONVERT(VARCHAR(20), @CurrentRate) + ', "' + COALESCE(CONVERT(VARCHAR(20), @ChangePercent), 'N/A') + '%"';
        END
        ELSE
        BEGIN
            PRINT 'No active rate (not zero) for ' + @CurrencyPair;
        END

        FETCH NEXT FROM currency_cursor INTO @CurrencyPair;
    END

    CLOSE currency_cursor;
    DEALLOCATE currency_cursor;
END;
