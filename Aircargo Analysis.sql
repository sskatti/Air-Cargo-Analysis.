create database aircargo;
use aircargo;
CREATE TABLE  customer (
  customer_id int not null,
  first_name varchar(100) NOT NULL,
  last_name varchar(100) DEFAULT NULL,
  date_of_birth date NOT NULL,
  gender varchar(1) NOT NULL,
  PRIMARY KEY (customer_id),
  CONSTRAINT Gender_check CHECK ((gender in ('M','F','O')))
  );
CREATE TABLE pof (
  customer_id int NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  route_id int NOT NULL,
  depart varchar(3) NOT NULL,
  arrival varchar(3) NOT NULL,
  seat_num varchar(10) DEFAULT NULL,
  class_id varchar(100) DEFAULT NULL,
  travel_date date DEFAULT NULL,
  flight_num int NOT NULL,
KEY customer (customer_id),
KEY routes (route_id),
CONSTRAINT pof_ibfk_1 FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
CONSTRAINT pof_ibfk_2 FOREIGN KEY (route_id) REFERENCES routes (route_id) 
);
CREATE TABLE routes (
  route_id int NOT NULL,
  flight_num int NOT NULL,
  origin_airport varchar(3) NOT NULL,
  destination_airport varchar(100) NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  distance_miles int NOT NULL,
  PRIMARY KEY (route_id),
  CONSTRAINT Flight_number_check CHECK ((substr(flight_num,1,2) = 11)),
  CONSTRAINT routes_chk_1 CHECK ((distance_miles > 0))
);
CREATE TABLE ticket_details (
  p_date date NOT NULL,
  customer_id int NOT NULL,
  aircraft_id varchar(100) NOT NULL,
  class_id varchar(100) DEFAULT NULL,
  no_of_tickets int DEFAULT NULL,
  a_code varchar(3) DEFAULT NULL,
  Price_per_ticket int DEFAULT NULL,
  brand varchar(100) DEFAULT NULL,
  KEY customer_id (customer_id),
  CONSTRAINT ticket_details_ibfk_1 FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

-- Displaying passengers who have travelled in routes 01 to 25. Take data  from the passengers_on_flights table.

select * from pof
where route_id between 1 and 25
order by route_id;


-- Identifying the number of passengers and total revenue generated in each class of airline and finding total revenue generated so far.

select if(grouping (class_id), 'Total', class_id) as Class, 
count(*) as Total_Passengers, sum(no_of_tickets*price_per_ticket) as Total_Revenue
from ticket_details
group by class_id with rollup
order by Total_Revenue;

-- Finding the  full name of the customer by extracting the first name and last name from the customer table.

select concat(first_name," ",last_name) as full_name
from customer
order by first_name;

-- Querying data of customers who have booked at least a ticket and total tickets booked by them.

select customer_id , concat(first_name, ' ' , last_name) as Name, count(no_of_tickets) as Total_Tickets_booked
from customer 
join ticket_details  using (customer_id)
group by customer_id, Name
order by Total_tickets_booked desc;

-- Checking details of customers who have booked tickets in Emirates airline

select customer_id, first_name, last_name
from customer 
join ticket_details  using (customer_id)
where brand = 'Emirates' 
order by customer_id;

-- Fetching details of the customers who are in Economy plus class on flight

select customer_id, first_name,last_name,class_id
from customer
join pof using (customer_id)
having class_id = "Economy Plus";

-- Fetching the query to check if revenue crossed 1000 t

select if(sum(no_of_tickets*price_per_ticket) > 1000, 'Revenue Crossed 1000', 'Revenue less than 1000') as Revenue_Status
from ticket_details;

-- Creating a new user and granting access to perform on database

CREATE USER 'Addy'@'localhost' IDENTIFIED BY 'Asdfg123*';
GRANT ALL PRIVILEGES ON aircargo.* TO 'Addy'@'localhost';

-- Fetching max ticket price for each class

with cte as (
select class_id, max(price_per_ticket) as Maximum_price, 
dense_rank () over (partition by class_id) as dense
from ticket_details
group by class_id)
select class_id, Maximum_price from cte where dense = 1;

-- extracting the passengers whose route ID is 4 

select customer_id, route_id
from aircargo.pof
where route_id=4;

-- For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.

select * from pof
where route_id=4;

-- calculating the total price of all tickets booked by a customer across different aircraft IDs using rollup function.

select COALESCE(aircraft_id, 'All Aircrafts')as aircraft_id,sum(no_of_tickets*price_per_ticket)as Total_Revenue
from ticket_details
group by aircraft_id with rollup;

--  creating a view with only business class customers along with the brand of airlines.

drop view if exists business_class;
create view  business_class as select first_name, last_name, brand
from ticket_details
join customer using (customer_id)
where class_id ="Bussiness";
select * from business_class;

--  creating a stored procedure to get the details of all passengers flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist.

select * from customer where customer_id in (select distinct customer_id from pof where route_id in (1,5));
DROP PROCEDURE `aircargonew`.`check_route`;
delimiter //
create procedure check_route(in rid varchar(255))
begin
   declare TableNotFound condition for 1146;
   declare exit handler for TableNotFound
			select 'Please check if table customer/route id are created  one/both are missing ' Message;
    set @query = concat('select * from customer where customer_id in (select distinct customer_id from pof where route_id in (',rid,'));');
    prepare sql_query from @query;
    execute sql_query;
end//
delimiter ;
call check_route("1,5");

-- creating a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.--

drop procedure if exists distance;
delimiter //
create procedure distance( in miles int)
begin
select * from routes
where distance_miles >miles
order by distance_miles;
end//
delimiter ;
call distance(2000);

-- creating Stored procesure for different range of miles covered.

select flight_num, distance_miles, case
                            when distance_miles between 0 and 2000 then "SDT"
                            when distance_miles between 2001 and 6500 then "IDT"
                            else "LDT"
					end distance_category from routes;
                    
delimiter //
create function group_dist(dist int)
returns varchar(10)
deterministic
begin
  declare dist_cat char(3);
  if dist between 0 and 2000 then
     set dist_cat ='SDT';
  elseif dist between 2001 and 6500 then
    set dist_cat ='IDT';
  elseif dist > 6500 then
   set dist_cat ='LDT';
 end if;
 return(dist_cat);
end //
create procedure group_dist_proc()
begin
   select flight_num, distance_miles, group_dist(distance_miles) as distance_category from routes;
end //
delimiter ;
call group_dist_proc();

-- complimentary Services

select p_date,customer_id, class_id, case
                                 when class_id in ('Bussiness','Economy Plus') then "Yes"
                                 else "No"
						   end as complimentary_service from ticket_details;
delimiter //
create function check_comp_serv(cls varchar(15))
returns char(3)
deterministic
begin
    declare comp_ser char(3);
    if cls in ('Bussiness', 'Economy Plus') then
        set comp_ser = 'Yes';
	else 
	   set comp_ser ='No';
	end if;
    return(comp_ser);
end //

create procedure check_comp_serv_proc()
begin
   select p_date,customer_id,class_id,check_comp_serv(class_id) as complimentary_service from ticket_details;
end //
delimiter ;
call check_comp_serv_proc();

 -- Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.



DROP PROCEDURE `aircargonew`.`cust_lname_scott`;
select * from customer where last_name ='Scott' limit 1;
delimiter //
create procedure cust_lname_scott()
begin
   declare c_id int;
   declare f_name varchar(20);
   declare l_name varchar(20);
   declare dob date;
   declare gen char(1);
   
   declare cust_rec cursor
   for
   select * from customer where last_name = 'Scott';
   create table if not exists cursor_table(
										c_id int,
										f_name varchar(20),
										l_name varchar(20),
										dob date,
										gen char(1)
									);
   open cust_rec;
   fetch cust_rec into c_id, f_name, l_name, dob, gen ;
   insert into cursor_table(c_id, f_name, l_name, dob, gen) values(c_id, f_name, l_name, dob, gen);
   close cust_rec;
   select * from cursor_table;
end //
delimiter ;
call cust_lname_scott();













 
   
