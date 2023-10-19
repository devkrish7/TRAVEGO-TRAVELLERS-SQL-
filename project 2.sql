use film_rental;

-- 1.	What is the total revenue generated from all rentals in the database?
SELECT 
    SUM(amount)
FROM
    payment;

-- 2.	How many rentals were made in each month_name?
with cte1 as(select rental_date,monthname(rental_date) as rental_month from rental)
select rental_month,count(rental_date) from cte1 group by rental_month;

-- 3.	What is the rental rate of the film with the longest title in the database? 
SELECT 
    title, CHAR_LENGTH(title) AS ch_lr, rental_rate
FROM
    film
ORDER BY ch_lr DESC
LIMIT 1;

-- 4.	What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")? 
SELECT 
    rental_date
FROM
    rental
WHERE
    rental_date >= '2005-05-05 22:04:30'
        AND rental_date <= (SELECT 
            DATE_ADD('2005-05-05 22:04:30',
                    INTERVAL 30 DAY)
        );

with cte1 as (select r.rental_date,f.rental_rate from rental r  join inventory i using(inventory_id) join film f using (film_id)
 where rental_date >= "2005-05-05 22:04:30" and rental_date <=(select date_add("2005-05-05 22:04:30" ,interval 30 day)))
 select avg(rental_rate) from cte1;
 
 -- 5.	What is the most popular category of films in terms of the number of rentals? 
SELECT 
    c.name, COUNT(rental_date)
FROM
    rental
        JOIN
    inventory USING (inventory_id)
        JOIN
    film f USING (film_id)
        JOIN
    film_category fc ON f.film_id = fc.film_id
        JOIN
    category c USING (category_id)
GROUP BY c.name;

-- 6.	Find the longest movie duration from the list of films that have not been rented by any customer. 
SELECT 
    *
FROM
    film;

SELECT 
    title, length, rental_date
FROM
    film f
        JOIN
    inventory i USING (film_id)
        LEFT JOIN
    rental r USING (inventory_id)
WHERE
    rental_date IS NULL;

-- 7.	What is the average rental rate for films, broken down by category? 
SELECT 
    c.name, AVG(rental_rate)
FROM
    rental
        JOIN
    inventory USING (inventory_id)
        JOIN
    film f USING (film_id)
        JOIN
    film_category fc ON f.film_id = fc.film_id
        JOIN
    category c USING (category_id)
GROUP BY c.name;

-- 8.	What is the total revenue generated from rentals for each actor in the database?
SELECT 
    first_name, last_name, SUM(amount) AS revenue
FROM
    payment
        JOIN
    rental USING (rental_id)
        JOIN
    inventory USING (inventory_id)
        JOIN
    film f USING (film_id)
        JOIN
    film_actor USING (film_id)
        JOIN
    actor USING (actor_id)
GROUP BY first_name , last_name;

-- 9.	Show all the actresses who worked in a film having a "Wrestler" in the description. 
SELECT 
    first_name, last_name
FROM
    actor
        JOIN
    film_actor USING (actor_id)
        JOIN
    film USING (film_id)
WHERE
    description LIKE '%Wrestler%';

-- 10.	Which customers have rented the same film more than once? 
SELECT 
    c.customer_id,
    f.film_id,
    f.title,
    COUNT(c.customer_id) AS cust_id_count
FROM
    customer c
        JOIN
    rental r ON c.customer_id = r.customer_id
        JOIN
    inventory i ON r.inventory_id = i.inventory_id
        JOIN
    film f ON i.film_id = f.film_id
GROUP BY c.customer_id , f.film_id
HAVING cust_id_count > 1;
 
-- 11.	How many films in the comedy category have a rental rate higher than the average rental rate? 
SELECT 
    title, rental_rate
FROM
    film
        JOIN
    film_category USING (film_id)
        JOIN
    category USING (category_id)
WHERE
    name IN ('Comedy')
        AND rental_rate > (SELECT 
            AVG(rental_rate)
        FROM
            film);
 
 -- 12.	Which films have been rented the most by customers living in each city? 
 WITH RankRentals AS (SELECT c.city,f.title AS film_title,COUNT(*) AS rental_count,ROW_NUMBER() OVER (PARTITION BY c.city ORDER BY COUNT(*) DESC) AS ranking
  FROM rental r
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city c ON a.city_id = c.city_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
  GROUP BY
    c.city, f.title
)
SELECT city,film_title,rental_count FROM RankRentals WHERE ranking = 1;

-- 13.	What is the total amount spent by customers whose rental payments exceed $200?
with cte1 as (select distinct c.customer_id,c.first_name,c.last_name,sum(amount) over(partition by customer_id) as rental_payment from payment p join customer c using(customer_id))
select customer_id,first_name,last_name, rental_payment from cte1 where rental_payment > 200;	

-- 14.	Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] 
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_NAME = 'rental'
        AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 15.	Create a View for the total revenue generated by each staff member, broken down by store city with the country name?
select distinct staff_id,first_name,last_name,sum(amount)over(partition by staff_id),city,country from payment join staff using(staff_id) join  
address using(address_id) join city using(city_id) join country using(country_id);



-- 16.	Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,
--   no_of_rental_days, the amount paid by the customer along with the percentage of customer spending. 
SELECT 
    c.customer_id,
    rental_date AS visiting_date,
    first_name AS customer_name,
    title,
    rental_duration,
    amount AS paid_amount,
    amount * 100 / (SELECT 
            SUM(amount)
        FROM
            payment) AS pct
FROM
    rental
        JOIN
    inventory USING (inventory_id)
        JOIN
    film USING (film_id)
        JOIN
    customer c USING (customer_id)
        JOIN
    payment USING (rental_id);
 
 
-- 17.	Display the customers who paid 50% of their total rental costs within one day. 
SELECT 
    c.customer_id,
    f.film_id,
    (f.rental_rate * f.rental_duration) AS rental_cost,
    p.amount,
    (p.amount / (f.rental_rate * f.rental_duration)) * 100 AS pct_paid
FROM
    film f
        JOIN
    inventory i USING (film_id)
        JOIN
    rental r USING (inventory_id)
        JOIN
    customer c USING (customer_id)
        JOIN
    payment p USING (rental_id)
WHERE
    (p.amount / (f.rental_rate * f.rental_duration)) > 0.5
        AND payment_date < DATE_ADD(r.rental_date, INTERVAL 1 DAY);
 
 




