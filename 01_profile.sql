USE UberRides;
GO

-- 1. How do dates and times look as text?
SELECT TOP 5 [Date], [Time], Booking_ID, Customer_ID
FROM dbo.raw_ride_bookings;

-- 2. Booking statuses and how many of each
SELECT Booking_Status, COUNT(*) AS Rides
FROM dbo.raw_ride_bookings
GROUP BY Booking_Status
ORDER BY Rides DESC;

-- 3. Are booking IDs unique?
SELECT
    COUNT(*)                   AS TotalRows,
    COUNT(DISTINCT Booking_ID) AS UniqueBookingIDs
FROM dbo.raw_ride_bookings;

-- 4. How many cells say the word 'null' in key columns?
SELECT
    SUM(CASE WHEN Booking_Value  = 'null' THEN 1 ELSE 0 END) AS BookingValue_null,
    SUM(CASE WHEN Ride_Distance  = 'null' THEN 1 ELSE 0 END) AS RideDistance_null,
    SUM(CASE WHEN Driver_Ratings = 'null' THEN 1 ELSE 0 END) AS DriverRatings_null,
    SUM(CASE WHEN Payment_Method = 'null' THEN 1 ELSE 0 END) AS PaymentMethod_null,
    SUM(CASE WHEN Avg_VTAT       = 'null' THEN 1 ELSE 0 END) AS AvgVTAT_null
FROM dbo.raw_ride_bookings;

-- 5. Vehicle types and payment methods
SELECT Vehicle_Type, COUNT(*) AS Rides
FROM dbo.raw_ride_bookings
GROUP BY Vehicle_Type
ORDER BY Rides DESC;

SELECT Payment_Method, COUNT(*) AS Rides
FROM dbo.raw_ride_bookings
GROUP BY Payment_Method
ORDER BY Rides DESC;

-- 6. Are the repeated IDs the same ride twice, or different rides?
WITH RepeatedIDs AS (
    SELECT Booking_ID
    FROM dbo.raw_ride_bookings
    GROUP BY Booking_ID
    HAVING COUNT(*) > 1
)
SELECT TOP 20
    r.Booking_ID, r.[Date], r.[Time], r.Customer_ID,
    r.Booking_Status, r.Vehicle_Type, r.Booking_Value
FROM dbo.raw_ride_bookings AS r
INNER JOIN RepeatedIDs AS d
    ON r.Booking_ID = d.Booking_ID
ORDER BY r.Booking_ID, r.[Date];

-- 7. How many rows are exact copies of another row? (Result: none)
SELECT SUM(Copies - 1) AS ExactDuplicateRows
FROM (
    SELECT COUNT(*) AS Copies
    FROM dbo.raw_ride_bookings
    GROUP BY [Date], [Time], Booking_ID, Customer_ID, Booking_Status,
             Vehicle_Type, Pickup_Location, Drop_Location, Booking_Value
    HAVING COUNT(*) > 1
) AS x;
