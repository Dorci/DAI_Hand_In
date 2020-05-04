
--This statement creates fact table f_sales with attributes, primary key is assigned to sales_id and foreign keys customer_id, product_id
CREATE TABLE AdventureWorks_DW.star_schema.f_sales
(
    sales_id    INT NOT NULL,
    customer_id INT NOT NULL,
    product_id  INT NOT NULL,
    date_id     INT NOT NULL,
    quantity    INT NOT NULL,
    line_total  INT NOT NULL,
    PRIMARY KEY (sales_id),
    FOREIGN KEY (customer_id) REFERENCES AdventureWorks_DW.star_schema.d_customer (dimension_customer_id),
    FOREIGN KEY (product_id) REFERENCES AdventureWorks_DW.star_schema.d_product (dimension_product_id),
    FOREIGN KEY (date_id) REFERENCES AdventureWorks_DW.star_schema.d_date (dimension_date_id)
);

--This statement inserts attribute vales into dimension d_product table
INSERT INTO AdventureWorks_DW.star_schema.d_product
SELECT *
FROM StagingDatabase.staging.stage_dim_product;

--This statement inserts attribute vales into dimension d_customer table
INSERT INTO AdventureWorks_DW.star_schema.d_customer
SELECT *
FROM StagingDatabase.staging.stage_dim_customer;
--This statement inserts attribute vales into dimension d_date table
INSERT INTO AdventureWorks_DW.star_schema.d_date
SELECT *
FROM StagingDatabase.staging.stage_dim_date;

--This statement inserts attribute vales into fact f_sales table
INSERT INTO AdventureWorks_DW.star_schema.f_sales(sales_id, customer_id, product_id, date_id, quantity, line_total) (SELECT sales_id, customer_id, product_id, date_id, quantity, line_total
                                                                                                                     FROM StagingDatabase.staging.stage_f_sales);

-- This statement returns Top seller products
SELECT FS.product_id, name, COUNT(*) as COUNT
FROM AdventureWorks_DW.star_schema.f_sales AS FS
         JOIN AdventureWorks_DW.star_schema.d_product ON FS.product_id = d_product.dimension_product_id
GROUP BY FS.product_id, name
ORDER BY COUNT DESC;
