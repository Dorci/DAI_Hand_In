--retrieving newly added rows
SELECT *
FROM AdventureWorks2017.Sales.Customer
WHERE CustomerID IN (SELECT CustomerID
                    FROM AdventureWorks2017.Sales.Customer
                      EXCEPT
                    SELECT CustomerID
                    FROM StagingDatabase.staging.stage_dim_customer)