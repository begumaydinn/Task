CREATE PROCEDURE CalculateExchangeRate
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
        -- Get latest rate (not zero) for the current currency pair
        SELECT TOP 1 @CurrentRate = rate
        FROM mytable
        WHERE ccy_couple = @CurrencyPair
        AND rate <> 0
        ORDER BY event_time DESC;

        -- Set yesterday's rate for the current currency pair
        IF @CurrencyPair = 'EURUSD'
            SET @YesterdayRate = 1.0500;
        ELSE IF @CurrencyPair = 'NZDUSD'
            SET @YesterdayRate = 0.6660;
        ELSE IF @CurrencyPair = 'AUDUSD'
            SET @YesterdayRate = 0.6950;
        ELSE IF @CurrencyPair = 'EURGBP'
            SET @YesterdayRate = 0.8260;
        ELSE IF @CurrencyPair = 'GBPUSD'
            SET @YesterdayRate = 1.3000;
        ELSE
            SET @YesterdayRate = NULL; -- Default value if yesterday's rate is not defined for the currency pair

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
