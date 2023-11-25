-- task 1
-- Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT model,
       string_agg(fare_conditions || '(' || seat_no::text || ')', ', ') as fare_conditions
FROM (SELECT model -> 'en' as model, fare_conditions, count(*) as seat_no
      FROM bookings.aircrafts_data as ad
               JOIN bookings.seats as s ON s.aircraft_code = ad.aircraft_code
      GROUP BY model, fare_conditions
      ORDER BY fare_conditions) as subquery
GROUP BY model
ORDER BY model;

-- task2
-- Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT model -> 'en' AS aircraft_model, COUNT(seat_no) AS total_seats
FROM bookings.aircrafts_data
         JOIN bookings.seats ON aircrafts_data.aircraft_code = seats.aircraft_code
GROUP BY aircraft_model
ORDER BY total_seats DESC
LIMIT 3;

--task3
-- Найти все рейсы, которые задерживались более 2 часов
SELECT flight_id
FROM bookings.flights
WHERE actual_departure > scheduled_departure + interval '2 hours';

--task 4
-- Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT t.passenger_name, t.contact_data
FROM bookings.tickets as t
         JOIN bookings.ticket_flights as tf ON tf.ticket_no = t.ticket_no
WHERE fare_conditions = 'Business'
ORDER BY t.ticket_no DESC
LIMIT 10;

-- task 5
-- Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT DISTINCT f.flight_no
FROM bookings.tickets as t
         JOIN bookings.ticket_flights as tf ON tf.ticket_no = t.ticket_no
         JOIN bookings.flights as f ON f.flight_id = tf.flight_id
WHERE tf.fare_conditions <> 'Business'
GROUP BY f.flight_no;

-- task 6
-- Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT a.airport_name -> 'ru' as airport_name, a.city -> 'ru' as city
FROM bookings.airports_data a
         JOIN bookings.flights f ON a.airport_code = f.departure_airport
WHERE f.status = 'Delayed'
ORDER BY city;

-- task 7
-- Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT a.airport_name -> 'en' as airport_name, COUNT(f.flight_id) AS flight_count
FROM bookings.airports_data a
         JOIN bookings.flights f ON a.airport_code = f.departure_airport
GROUP BY airport_name
ORDER BY flight_count DESC;

-- task 8
-- Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT flight_no
FROM bookings.flights as f
WHERE scheduled_arrival <> actual_arrival
  AND actual_arrival IS NOT NULL
GROUP BY f.flight_no;

-- task 9
-- Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT ad.aircraft_code, ad.model -> 'ru' as model, s.seat_no
FROM bookings.aircrafts_data ad
         JOIN bookings.seats s ON ad.aircraft_code = s.aircraft_code
WHERE ad.model -> 'ru' = '"Аэробус A321-200"'
  AND s.fare_conditions != 'Economy'
ORDER BY s.seat_no;
-- + в одну строку  все места
SELECT ad.aircraft_code, ad.model -> 'ru' as model, string_agg(s.seat_no, ', ') as non_economy_seats
FROM bookings.aircrafts_data ad
         JOIN bookings.seats s ON ad.aircraft_code = s.aircraft_code
WHERE ad.model -> 'ru' = '"Аэробус A321-200"'
  AND s.fare_conditions != 'Economy'
GROUP BY ad.aircraft_code, ad.model
ORDER BY ad.aircraft_code;

-- task 10
-- Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airport_code, airport_name, city
FROM bookings.airports_data
WHERE city IN (SELECT city
               FROM bookings.airports_data
               GROUP BY city
               HAVING COUNT(*) > 1)
ORDER BY city, airport_code;

-- task 11
-- Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT t.passenger_id, t.passenger_name, SUM(b.total_amount) AS total_booking_cost
FROM bookings.tickets t
         JOIN bookings.bookings b ON t.book_ref = b.book_ref
GROUP BY t.passenger_id, t.passenger_name
HAVING SUM(b.total_amount) > (SELECT AVG(total_amount) FROM bookings.bookings);

-- ??
-- task 12
-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT f.flight_no
FROM bookings.flights as f
         JOIN bookings.airports_data ad on ad.airport_code = f.arrival_airport
WHERE departure_airport IN (SELECT airport_code FROM bookings.airports_data WHERE city -> 'ru' = '"Екатеринбург"')
  AND arrival_airport IN (SELECT airport_code FROM bookings.airports_data WHERE city -> 'ru' = '"Москва"')
  AND status IN ('On Time', 'Delayed', 'Scheduled')
  AND scheduled_departure > bookings.now()
ORDER BY scheduled_departure
LIMIT 1;

-- task 13
-- Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT (SELECT MIN(ticket_no) FROM bookings.boarding_passes) AS cheapest_ticket,
       (SELECT MAX(ticket_no) FROM bookings.boarding_passes) AS most_expensive_ticket;

-- task 14
-- Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE Customers
(
    id        SERIAL PRIMARY KEY,
    firstName VARCHAR(60) NOT NULL
        CONSTRAINT check_name
            CHECK (char_length((firstName)::text) >= 2),
    lastName  VARCHAR(55) NOT NULL,
    CONSTRAINT check_description
        CHECK (char_length((lastName)::text) >= 1),
    email     VARCHAR(100) UNIQUE,
    phone     VARCHAR(20) CHECK (phone ~ '^\+?[0-9\-\(\)]{7,20}$')
);

-- task 15
-- Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE Orders
(
    id         SERIAL PRIMARY KEY,
    customerId INTEGER NOT NULL,
    quantity   INTEGER NOT NULL,
    CONSTRAINT fk_customer
        FOREIGN KEY (customerId)
            REFERENCES Customers (id)
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT positive_quantity
        CHECK (quantity > 0)
);

-- task 16
-- Написать 5 insert в эти таблицы
INSERT INTO Customers (firstName, lastName, email, phone)
VALUES ('Иван', 'Иванов', 'ivan@mail.ru', '+1234567890'),
       ('Петр', 'Петров', 'petr@mail.ru', '+1987654321'),
       ('Мария', 'Сидорова', 'maria@mail.ru', '+1765432987'),
       ('Елена', 'Козлова', 'elena@mail.ru', '+1654329876'),
       ('Алексей', 'Николаев', 'alex@mail.ru', '+1888888888');

INSERT INTO Orders (customerId, quantity)
VALUES (1, 3),
       (2, 5),
       (3, 2),
       (4, 4),
       (5, 1);

-- task 17
-- Удалить таблицы
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;
