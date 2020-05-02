-- ******************************************************************************************
-- ************************************* NEW PRODUCTS ***************************************
-- ******************************************************************************************

-- Create temporary table to store added products so we can handle valid_to attribute
CREATE TABLE StagingDatabase.staging.stage_dim_product_added
(
    dimension_product_id INT NOT NULL IDENTITY,
    product_id           INT,
    name                 varchar(50),
    valid_from           DATETIME,
    valid_to             DATETIME,
    PRIMARY KEY (dimension_product_id)
);

-- Search and insert newly added product into staging added product table
INSERT INTO StagingDatabase.staging.stage_dim_product_added (product_id, name, valid_from, valid_to)
SELECT ProductID, Name, SellStartDate, SellEndDate
FROM AdventureWorks2017.Production.Product
WHERE productID IN (SELECT productID
                    FROM AdventureWorks2017.Production.Product
                        EXCEPT
                    SELECT product_id
                    FROM AdventureWorks_DW.star_schema.d_product);

-- Replace all NULL values with date 31.12.9999
UPDATE StagingDatabase.staging.stage_dim_product_added
SET valid_to='9999-12-31'
WHERE valid_to IS NULL;

-- Load newly added and modified rows into the Data Warehouse
INSERT INTO AdventureWorks_DW.star_schema.d_product
SELECT *
FROM StagingDatabase.staging.stage_dim_product_added;

-- **********************************************************************************************
-- ************************************* DELETED PRODUCTS ***************************************
-- **********************************************************************************************

-- Retrieve and update data warehouse, set valid_to attribute to yesterdays date for deleted
-- products.
UPDATE AdventureWorks_DW.star_schema.d_product
SET valid_to = DATEADD(dd, -1, GETDATE())
WHERE product_id in (
    SELECT product_id
    FROM AdventureWorks_DW.star_schema.d_product
    WHERE product_id IN (SELECT product_id
                         FROM AdventureWorks_DW.star_schema.d_product
                             EXCEPT
                         SELECT productID
                         FROM AdventureWorks2017.Production.Product)
)

-- **********************************************************************************************
-- ************************************* UPDATED PRODUCTS ***************************************
-- **********************************************************************************************

-- Create temporary table to store updated products so we can handle valid_to attribute and
-- deleting old products
CREATE TABLE StagingDatabase.staging.stage_dim_product_changed
(
    dimension_product_id INT NOT NULL IDENTITY,
    product_id           INT,
    name                 varchar(50),
    valid_from           DATETIME,
    valid_to             DATETIME,
    PRIMARY KEY (dimension_product_id)
);

-- Inserting updated rows into the temporary table to handle changes
INSERT INTO StagingDatabase.staging.stage_dim_product_changed
    (product_id, name, valid_from) (SELECT ProductID, Name, SellStartDate
                                    FROM AdventureWorks2017.Production.Product
                                        EXCEPT
                                    SELECT product_id, name, valid_from
                                    FROM StagingDatabase.staging.stage_dim_product
                                        EXCEPT (
                                             SELECT ProductID, Name, SellStartDate
                                             FROM AdventureWorks2017.Production.Product
                                             WHERE productID IN
                                                   (SELECT productID
                                                    FROM AdventureWorks2017.Production.Product
                                                        EXCEPT
                                                    SELECT product_id
                                                    FROM StagingDatabase.staging.stage_dim_product)
                                         ));

-- Update valid_to attribute to '9999-12-31'
UPDATE StagingDatabase.staging.stage_dim_product_changed
SET valid_to = '9999-12-31'
WHERE valid_to IS NULL;

-- Alter changed rows in Data Warehouse
UPDATE AdventureWorks_DW.star_schema.d_product
SET valid_to = DATEADD(dd, -1, GETDATE())
WHERE product_id in (SELECT product_id FROM StagingDatabase.staging.stage_dim_product_changed);

-- Insert new product to Data Warehouse
INSERT INTO AdventureWorks_DW.star_schema.d_product
SELECT *
FROM StagingDatabase.staging.stage_dim_product_changed;