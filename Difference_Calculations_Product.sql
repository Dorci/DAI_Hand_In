--retrieving newly added rows
SELECT *
FROM AdventureWorks2017.Production.Product
WHERE productID IN (SELECT productID
                    FROM AdventureWorks2017.Production.Product
                      EXCEPT
                    SELECT product_id
                    FROM StagingDatabase.staging.stage_dim_product)

--retrieving deleted rows
SELECT *
FROM StagingDatabase.staging.stage_dim_product
WHERE product_id IN (SELECT product_id
                     FROM StagingDatabase.staging.stage_dim_product
                       EXCEPT
                     SELECT productID
                     FROM AdventureWorks2017.Production.Product)

-- retrieving only changed rows not newly added
SELECT ProductID,Name
      FROM AdventureWorks2017.Production.Product
        EXCEPT
      SELECT product_id,name
      FROM StagingDatabase.staging.stage_dim_product
  EXCEPT (
       SELECT ProductID,Name
       FROM AdventureWorks2017.Production.Product
       WHERE productID IN (SELECT productID
                           FROM AdventureWorks2017.Production.Product
                             EXCEPT
                           SELECT product_id
                           FROM StagingDatabase.staging.stage_dim_product)
     )