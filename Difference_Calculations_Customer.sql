--retrieving newly added rows
SELECT *
FROM AdventureWorks2017.Sales.Customer
WHERE CustomerID IN (SELECT CustomerID
                    FROM AdventureWorks2017.Sales.Customer
                      EXCEPT
                    SELECT customer_id
                    FROM StagingDatabase.staging.stage_dim_customer)

--retrieving deleted rows
SELECT *
FROM StagingDatabase.staging.stage_dim_customer
WHERE customer_id IN (SELECT customer_id
                     FROM StagingDatabase.staging.stage_dim_product
                       EXCEPT
                     SELECT CustomerID
                     FROM AdventureWorks2017.Sales.Customer)
-- retrieving only changed rows not newly added
SELECT CustomerID
      FROM AdventureWorks2017.Sales.Customer
        EXCEPT
      SELECT customer_id
      FROM StagingDatabase.staging.stage_dim_customer
  EXCEPT (
       SELECT CustomerID
       FROM AdventureWorks2017.Sales.Customer
       WHERE CustomerID IN (SELECT CustomerID
                           FROM AdventureWorks2017.Sales.Customer
                             EXCEPT
                           SELECT customer_id
                           FROM StagingDatabase.staging.stage_dim_customer)
    )