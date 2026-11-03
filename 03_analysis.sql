USE UberRides;
GO

-- 1. Overall performance
SELECT
    COUNT(*)                                           AS TotalBookings,
    SUM(CompletedFlag)                                 AS CompletedRides,
    ROUND(100.0 * SUM(CompletedFlag) / COUNT(*), 1)    AS CompletionRatePct,
    SUM(BookingValue)                                  AS TotalRevenue,
    ROUND(AVG(BookingValue), 0)                        AS AvgFare,
    ROUND(AVG(RideDistanceKm), 1)                      AS AvgDistanceKm,
    ROUND(AVG(DriverRating), 2)                        AS AvgDriverRating,
    ROUND(AVG(CustomerRating), 2)                      AS AvgCustomerRating
FROM dbo.v_rides_clean;

-- 2. Which vehicle types lose the most bookings?
SELECT
    VehicleType,
    COUNT(*)                                                AS Bookings,
    ROUND(100.0 * SUM(CompletedFlag) / COUNT(*), 1)         AS CompletionRatePct,
    ROUND(100.0 * SUM(DriverCancelFlag) / COUNT(*), 1)      AS DriverCancelPct,
    ROUND(100.0 * SUM(CustomerCancelFlag) / COUNT(*), 1)    AS CustomerCancelPct,
    SUM(BookingValue)                                       AS Revenue
FROM dbo.v_rides_clean
GROUP BY VehicleType
ORDER BY Bookings DESC;

-- 3. Busiest hours, and how often bookings fail at each hour
SELECT
    RideHour,
    COUNT(*)                                                     AS Bookings,
    ROUND(100.0 * (COUNT(*) - SUM(CompletedFlag)) / COUNT(*), 1) AS NotCompletedPct
FROM dbo.v_rides_clean
GROUP BY RideHour
ORDER BY RideHour;

-- 4. Why do rides get cancelled?
SELECT 'Driver' AS CancelledBy, DriverCancelReason AS Reason, COUNT(*) AS Rides
FROM dbo.v_rides_clean
WHERE DriverCancelFlag = 1
GROUP BY DriverCancelReason

UNION ALL

SELECT 'Customer', CustomerCancelReason, COUNT(*)
FROM dbo.v_rides_clean
WHERE CustomerCancelFlag = 1
GROUP BY CustomerCancelReason

ORDER BY CancelledBy, Rides DESC;

-- 5. Monthly trend
SELECT
    DATEFROMPARTS(YEAR(RideDate), MONTH(RideDate), 1)   AS RideMonth,
    COUNT(*)                                            AS Bookings,
    SUM(CompletedFlag)                                  AS CompletedRides,
    SUM(BookingValue)                                   AS Revenue
FROM dbo.v_rides_clean
GROUP BY DATEFROMPARTS(YEAR(RideDate), MONTH(RideDate), 1)
ORDER BY RideMonth;
