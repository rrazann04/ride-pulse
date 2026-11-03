USE UberRides;
GO

CREATE VIEW dbo.v_rides_clean AS
SELECT
    -- Our own unique number for each ride (Booking IDs repeat)
    ROW_NUMBER() OVER (
        ORDER BY TRY_CONVERT(date, [Date]), TRY_CONVERT(time(0), [Time]), Booking_ID
    ) AS RideKey,

    -- IDs without the extra quote marks
    REPLACE(Booking_ID, '"', '')  AS BookingID,
    REPLACE(Customer_ID, '"', '') AS CustomerID,

    -- Date and time as real types, plus the hour
    TRY_CONVERT(date, [Date])                    AS RideDate,
    TRY_CONVERT(time(0), [Time])                 AS RideTime,
    DATEPART(hour, TRY_CONVERT(time(0), [Time])) AS RideHour,

    -- Categories
    TRIM(Booking_Status)  AS BookingStatus,
    TRIM(Vehicle_Type)    AS VehicleType,
    TRIM(Pickup_Location) AS PickupLocation,
    TRIM(Drop_Location)   AS DropLocation,
    NULLIF(TRIM(Payment_Method), 'null') AS PaymentMethod,

    -- Wait times in minutes ('null' text becomes a real NULL)
    TRY_CONVERT(decimal(6,1), NULLIF(TRIM(Avg_VTAT), 'null')) AS AvgVTAT,
    TRY_CONVERT(decimal(6,1), NULLIF(TRIM(Avg_CTAT), 'null')) AS AvgCTAT,

    -- Cancellations and incomplete rides: 1/0 flags plus the reason
    CASE WHEN NULLIF(TRIM(Cancelled_Rides_by_Customer), 'null') IS NOT NULL THEN 1 ELSE 0 END AS CustomerCancelFlag,
    NULLIF(TRIM(Reason_for_cancelling_by_Customer), 'null') AS CustomerCancelReason,

    CASE WHEN NULLIF(TRIM(Cancelled_Rides_by_Driver), 'null') IS NOT NULL THEN 1 ELSE 0 END AS DriverCancelFlag,
    NULLIF(TRIM(Driver_Cancellation_Reason), 'null') AS DriverCancelReason,

    CASE WHEN NULLIF(TRIM(Incomplete_Rides), 'null') IS NOT NULL THEN 1 ELSE 0 END AS IncompleteFlag,
    NULLIF(TRIM(Incomplete_Rides_Reason), 'null') AS IncompleteReason,

    CASE WHEN TRIM(Booking_Status) = 'Completed' THEN 1 ELSE 0 END AS CompletedFlag,

    -- Money, distance and ratings as numbers
    TRY_CONVERT(decimal(10,2), NULLIF(TRIM(Booking_Value), 'null'))   AS BookingValue,
    TRY_CONVERT(decimal(8,2),  NULLIF(TRIM(Ride_Distance), 'null'))   AS RideDistanceKm,
    TRY_CONVERT(decimal(3,1),  NULLIF(TRIM(Driver_Ratings), 'null'))  AS DriverRating,
    TRY_CONVERT(decimal(3,1),  NULLIF(TRIM(Customer_Rating), 'null')) AS CustomerRating

FROM dbo.raw_ride_bookings;
GO

-- A. Same number of rows as raw (150000) and unique RideKeys
SELECT COUNT(*) AS CleanRows, COUNT(DISTINCT RideKey) AS UniqueRideKeys
FROM dbo.v_rides_clean;

-- B. Real values lost in conversion (all 0)
SELECT
    SUM(CASE WHEN c.RideDate IS NULL THEN 1 ELSE 0 END) AS BadDates,
    SUM(CASE WHEN c.RideTime IS NULL THEN 1 ELSE 0 END) AS BadTimes,
    SUM(CASE WHEN c.BookingValue IS NULL AND r.Booking_Value <> 'null' THEN 1 ELSE 0 END) AS BadValues,
    SUM(CASE WHEN c.RideDistanceKm IS NULL AND r.Ride_Distance <> 'null' THEN 1 ELSE 0 END) AS BadDistances,
    SUM(CASE WHEN c.DriverRating IS NULL AND r.Driver_Ratings <> 'null' THEN 1 ELSE 0 END) AS BadRatings
FROM dbo.v_rides_clean AS c
INNER JOIN (
    SELECT *, ROW_NUMBER() OVER (
        ORDER BY TRY_CONVERT(date, [Date]), TRY_CONVERT(time(0), [Time]), Booking_ID
    ) AS RideKey
    FROM dbo.raw_ride_bookings
) AS r
    ON c.RideKey = r.RideKey;

-- C. Do the flags agree with the status?
SELECT
    BookingStatus,
    COUNT(*)                AS Rides,
    SUM(CustomerCancelFlag) AS CustomerCancelFlags,
    SUM(DriverCancelFlag)   AS DriverCancelFlags,
    SUM(IncompleteFlag)     AS IncompleteFlags
FROM dbo.v_rides_clean
GROUP BY BookingStatus
ORDER BY Rides DESC;
