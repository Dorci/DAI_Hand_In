-- ***********************************************
-- ************ CREATING STAGE TABLES ************
-- ***********************************************
--This statement creates staging dimension table stage_dim_customer with attributes and assigned primary key as customer_id
CREATE TABLE staging.stage_dim_customer
(
    dimension_customer_id INT NOT NULL IDENTITY,
    customer_id           INT NOT NULL,
    title                 varchar(10),
    first_name            varchar(50),
    middle_name           varchar(50),
    last_name             varchar(50),
    valid_from            DATETIME,
    valid_to              DATETIME,
    PRIMARY KEY (dimension_customer_id)
);
--This statement creates staging dimension table stage_dim_product with attributes and assigned primary key as dimension_product_id
CREATE TABLE staging.stage_dim_product
(
    dimension_product_id INT NOT NULL IDENTITY,
    product_id           INT,
    name                 varchar(50),
    valid_from           DATETIME,
    valid_to             DATETIME,
    PRIMARY KEY (dimension_product_id)
);
--This statement creates staging dimension table stage_dim_date with attributes and assigned primary key as dimension_date_id
CREATE TABLE staging.stage_dim_date
(
    dimension_date_id INT      NOT NULL IDENTITY,
    month_name        varchar(10),
    day_name          varchar(10),
    date              DATETIME NOT NULL,
    PRIMARY KEY (dimension_date_id)
);

-- **********************************************************
-- ************ INSERTING DATA INTO STAGE TABLES ************
-- **********************************************************

-- _______________________ CUSTOMER _______________________

--This statement inserts attribute values into staging dimension table stage_dim_customer
INSERT INTO staging.stage_dim_customer(customer_id, title, first_name, middle_name, last_name)
SELECT CustomerID, Title, FirstName, MiddleName, LastName
FROM AdventureWorks2017.Sales.Customer
         JOIN AdventureWorks2017.Person.Person ON Customer.PersonID = Person.BusinessEntityID;

--This statement removes null values in the title attribute in stage_dim_customer table by replacing with 'N/A' 
UPDATE staging.stage_dim_customer
SET title='N/A'
WHERE title IS NULL;

--This statement removes null values in the middle_name attribute in stage_dim_customer table by replacing with 'N/A' 
UPDATE staging.stage_dim_customer
SET middle_name='N/A'
WHERE middle_name IS NULL;

-- Create new date for valid_from attribute. It will be the date when it was added to data warehouse
UPDATE staging.stage_dim_customer
SET valid_from=GETDATE()
WHERE valid_from IS NULL;

-- This statement replaces all NULL values with date 31.12.9999
UPDATE staging.stage_dim_customer
SET valid_to='9999-12-31'
WHERE valid_to IS NULL;


-- _______________________ PRODUCT _______________________

--This statement inserts attribute values into staging dimension table stage_dim_product
INSERT INTO staging.stage_dim_product(product_id, name, valid_from, valid_to)
SELECT ProductID, Name, SellStartDate, SellEndDate
from AdventureWorks2017.Production.Product;

--This statement removes null values in the name attribute in stage_dim_product table by replacing with 'N/A' 
UPDATE staging.stage_dim_product
SET name='N/A'
WHERE name IS NULL;

-- This statement replaces all NULL values with date 31.12.9999
UPDATE staging.stage_dim_product
SET valid_to='9999-12-31'
WHERE valid_to IS NULL;


-- _______________________ DATE _______________________

--This statement inserts attribute values unto staging dimension table stage_dim_date
DECLARE @StartDate DATETIME = '2011-05-31'
DECLARE @EndDate DATETIME = '2014-06-30'

WHILE @StartDate <= @EndDate
    BEGIN
        INSERT INTO staging.stage_dim_date (date,
                                            day_name,
                                            month_name)
        SELECT @StartDate,
               DATENAME(weekday, @StartDate),
               DATENAME(month, @StartDate)

        SET @StartDate = DATEADD(dd, 1, @StartDate)
    END

-- **********************************************************
-- ************ INSERTING DATA INTO FACT TABLES ************
-- **********************************************************

--This statement creates staging fact table stage_f_sales with attributes and assigned primary key as sales_id
CREATE TABLE staging.stage_f_sales
(
    sales_id             INT      NOT NULL IDENTITY,
    customer_id          INT      NULL,
    product_id           INT      NULL,
    date_id              INT      NULL,
    business_customer_id INT      NULL,
    business_product_id  INT      NULL,
    business_order_date  DATETIME NULL,
    quantity             INT      NULL,
    line_total           FLOAT    NULL,
    PRIMARY KEY (sales_id)
);

--This statement inserts attribute values into staging fact table stage_f_sales
INSERT INTO staging.stage_f_sales(business_customer_id, business_product_id, business_order_date, quantity, line_total)
    (SELECT C.CustomerID, P.ProductID, OrderDate, SOD.OrderQty, SOD.LineTotal
     FROM AdventureWorks2017.Sales.SalesOrderHeader SOH
              JOIN AdventureWorks2017.Sales.SalesOrderDetail SOD on SOH.SalesOrderID = SOD.SalesOrderID
              JOIN AdventureWorks2017.Sales.Customer C on SOH.CustomerID = C.CustomerID
              JOIN AdventureWorks2017.Production.Product P on SOD.ProductID = P.ProductID
     WHERE OnlineOrderFlag = 1);

--This statement extracts the customer_id from staging dimension table stage_dim_customer and assigns it to the customer_id attribute in stage_f_sales table when the value is null
UPDATE staging.stage_f_sales
SET customer_id = (SELECT dimension_customer_id
                   FROM staging.stage_dim_customer AS dim_C_id
                   WHERE dim_C_id.customer_id = business_customer_id)
WHERE customer_id IS NULL;

--This statement extracts the product_id from staging dimension table stage_dim_product and assigns it to the product_id attribute in stage_f_sales table when the value is null
UPDATE staging.stage_f_sales
SET product_id = (SELECT dimension_product_id
                  FROM staging.stage_dim_product AS dim_P_id
                  WHERE dim_P_id.product_id = business_product_id)
WHERE product_id IS NULL;

--This statement extracts the date_id from staging dimension table stage_dim_date and assigns it to the date_id attribute in stage_f_sales table when the value is null
UPDATE staging.stage_f_sales
SET date_id = (SELECT dimension_date_id
               FROM staging.stage_dim_date AS dim_D_id
               WHERE dim_D_id.date = business_order_date)
WHERE date_id IS NULL;
