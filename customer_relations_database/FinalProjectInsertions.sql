use group14finalproject;

insert into company(idCompany, Name, Address, City, State, ZipCode, PhoneNumber, Contact, Locations)
values(01,'Customer Connect','5809 Dove Creek','Plano','TX',75093, 9002490,'Zan',1);
 
insert into customers(idCompany,idCustomers,FirstName,LastName)
values(01,01,"Shaheer","Ali");

insert into customers(idCompany,idCustomers,FirstName,LastName)
values(01,02,"Kayhan","Saeed");

insert into customers(idCompany,idCustomers,FirstName,LastName)
values(01,03,"Nassim","Sohaee");

insert into Products(idCompany,idProducts,Name,Price,Quantity)
values (1, 001, 'Test', 50, 10);

insert into Sales (idCompany, idSales, idCustomer, idProducts, Price, Quantity)
values (1, 01, 01, 001, 50, 1);

insert into Sales (idCompany, idSales, idCustomer, idProducts, Price, Quantity)
values (1, 02, 02, 001, 50, 2);

insert into Sales (idCompany, idSales, idCustomer, idProducts, Price, Quantity)
values (1, 03, 01, 001, 50, 2);

insert into points(idCustomer,idSales,Points)
values(01,01,1500);

insert into points(idCustomer,idSales,Points)
values(02,02,1000);

insert into points(idCustomer,idSales,Points)
values(01,03,500);

insert into surveys(idCompany,idSurveys,Name,StartDate,EndDate)
values (01,10,'Survey 1','2017-04-13','2017-05-13');

insert into surveys(idCompany,idSurveys,Name,StartDate,EndDate)
values (01,11,'Survey 2','2017-04-13','2017-05-13');

insert into surveys(idCompany,idSurveys,Name,StartDate,EndDate)
values (01,12,'Survey 3','2017-04-13','2017-05-13');

insert into Surveys_has_Customers(idSurveys,idCustomers,idCompany)
values (10,01,01);

insert into Surveys_has_Customers(idSurveys,idCustomers,idCompany)
values (10,02,01);

drop schema group14finalproject;