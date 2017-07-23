use CustomerRewards;

-- Q1: Retrieve the names of all products in inventory
select name 
from products;

-- Q2: Retrieve total amount of each sale on record
select price*quantity as total_amount
from sales;

-- Q3: Find the Company ID for the Customer Connect company
select idcompany 
from company
where 'Customer Connect' = name;

-- Q4: Retrieve all information on the company for whom Zan is listed as the contact
select *
from company
where contact = 'Zan';

-- Q5: Return names of all Customer Connect shoppers
select firstname, lastname
from customers as c, company as co
where c.idcompany=co.idcompany and co.name='Customer Connect';

-- Q6: Find out which customers have points
select distinct idcustomer
from points
where points > 0;  

-- Q7: Find out how many points each customer has
select
    t1.firstname,
    t1.lastname,
    t2.points
from 
	(customers as t1 inner join points as t2 on t1.idcustomers=t2.idcustomer);

-- Q8: Retrieve information on which rewards have been sent to which customers
select
	c.idcompany,
	c.firstname,
	c.lastname,
    r.idRewardsCatalog	
from
 (customers c left join rewards r on c.idCustomers = r.idCustomers);

-- Q9: Find the total number of points earned by each customer
select
	idcustomer,
    SUM(points) AS lifetimePoints
from
	points
group by idcustomer;

-- Q10: Find the customers that have earned more than 1000 points and order them by Customer ID
select
	idcustomer,
    SUM(points) AS lifetimePoints
from
	points
group by idcustomer
having lifetimePoints > 1000;

-- Q11: Retrieve the first and last name of each customer that has recieved "Survey 1"
select c.lastname, c.firstname
from customers as c, surveys_has_customers as s
where c.idcustomers=s.idcustomers and s.idsurveys in (select idsurveys
						      from surveys as s1
						      where s1.Name = 'Survey 1');
                                               
drop schema group14finalproject;
