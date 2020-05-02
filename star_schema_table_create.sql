--This statement creates dimension table d_customer with attributes and primary key is assigned to dimension_customer_id
CREATE TABLE star_schema.d_customer
(
    dimension_customer_id INT         NOT NULL,
    customer_id           INT         NOT NULL,
    title                 varchar(10) NOT NULL,
    first_name            varchar(50) NOT NULL,
    middle_name           varchar(50) NOT NULL,
    last_name             varchar(50) NOT NULL,
    valid_from            DATETIME    NOT NULL,
    valid_to              DATETIME    NOT NULL,
    PRIMARY KEY (dimension_customer_id)
);
--This statement creates dimension table d_product with attributes and primary key is assigned to dimension_product_id
CREATE TABLE star_schema.d_product
(
    dimension_product_id INT         NOT NULL,
    product_id           INT         NOT NULL,
    name                 varchar(50) NOT NULL,
    valid_from           DATETIME    NOT NULL,
    valid_to             DATETIME    NOT NULL,
    PRIMARY KEY (dimension_product_id)
);
--This statement creates dimension table d_date with attributes and primary key is assigned to dimension_date_id
CREATE TABLE star_schema.d_date
(
    dimension_date_id INT         NOT NULL,
    month_name        varchar(10) NOT NULL,
    day_name          varchar(10) NOT NULL,
    date              date        NOT NULL,
    PRIMARY KEY (dimension_date_id)
);
--This statement creates fact table f_sales with attributes, primary key is assigned to sales_id and foreign keys customer_id, product_id
CREATE TABLE star_schema.f_sales
(
    sales_id    INT  NOT NULL,
    customer_id INT  NOT NULL,
    product_id  INT  NOT NULL,
    date_id     INT  NOT NULL,
    quantity    INT  NOT NULL,
    line_total  INT NOT NULL,
    PRIMARY KEY (sales_id),
    FOREIGN KEY (customer_id) REFERENCES star_schema.d_customer (dimension_customer_id),
    FOREIGN KEY (product_id) REFERENCES star_schema.d_product (dimension_product_id),
    FOREIGN KEY (date_id) REFERENCES star_schema.d_date (dimension_date_id)
);
--This statement inserts attribute vales into dimension d_product table
INSERT INTO star_schema.d_product
SELECT *
FROM StagingDatabase.staging.stage_dim_product;
--This statement inserts attribute vales into dimension d_customer table
INSERT INTO star_schema.d_customer
SELECT *
FROM StagingDatabase.staging.stage_dim_customer;
--This statement inserts attribute vales into dimension d_date table
INSERT INTO star_schema.d_date(dimension_date_id, month_name, day_name, date)(SELECT * FROM StagingDatabase.staging.stage_dim_date);
--This statement inserts attribute vales into fact f_sales table
INSERT INTO star_schema.f_sales(sales_id, customer_id, product_id, date_id, quantity, line_total) (SELECT sales_id, customer_id, product_id, date_id, quantity, line_total
                                                                                                   FROM StagingDatabase.staging.stage_f_sales);

-- This statement returns Top seller products
SELECT FS.product_id, name, COUNT(*) as COUNT
FROM star_schema.f_sales AS FS
         JOIN star_schema.d_product ON FS.product_id = d_product.dimension_product_id
GROUP BY FS.product_id, name
ORDER BY COUNT DESC;
