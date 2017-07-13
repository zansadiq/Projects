use group14finalproject;

-- Q1: Retrieve the names of all products in inventory
select name 
from products;

-- Q2: Retrieve total amount of each sale on record
select price*quantity as total_amount
from sales;

-- Q3: Find the Company ID for the Customer Connect company
select idCompany 
from Company
where 'Customer Connect' = name;

-- Q4: Retrieve all information on the company for whom Zan is listed as the contact
select *
from company
where contact = 'Zan';

-- Q5: Return names of all Customer Connect shoppers
select FirstName, LastName
from Customers as C, Company as Co
where c.idCompany=co.idcompany and co.name='Customer Connect';

-- Q6: Find out which customers have points
select distinct idCustomer
from Points
where Points > 0;  

-- Q7: Find out how many points each customer has
select
    t1.FirstName,
    t1.LastName,
    t2.Points
from 
	(Customers as t1 inner join Points as t2 on t1.idCustomers=t2.idCustomer);

-- Q8: Retrieve information on which rewards have been sent to which customers
select
	c.idCompany,
	c.FirstName,
	c.LastName,
    r.idRewardsCatalog	
from
 (customers c left join rewards r on c.idCustomers = r.idCustomers);

-- Q9: Find the total number of points earned by each customer
select
	idCustomer,
    SUM(points) AS lifetimePoints
from
	Points
group by idCustomer;

-- Q10: Find the customers that have earned more than 1000 points and order them by Customer ID
select
	idCustomer,
    SUM(points) AS lifetimePoints
from
	Points
group by idCustomer
having lifetimePoints > 1000;

-- Q11: Retrieve the first and last name of each customer that has recieved "Survey 1"
select c.LastName, c.FirstName
from Customers as c, Surveys_has_Customers as s
where c.idCustomers=s.idCustomers and s.idSurveys in (select idSurveys
													  from Surveys as s1
													  where s1.Name = 'Survey 1');
                                               
drop schema group14finalproject;