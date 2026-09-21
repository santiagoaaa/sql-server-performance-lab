# sql-server-performance-lab

A reproducible laboratory for diagnosing and optimizing
SQL Server performance problems in an enterprise application.

## Scenario

A growing sales and distribution company is experiencing
performance problems in its internal application.

The objective of this project is to identify the root causes,
apply targeted optimizations and measure the results.

## Instructions to replicate

1. Clone repository
2. Go to Database/Schema
3. Open SQL Server
4. First Run SchemaLab.sql
5. Second Run generate-data.sql
6. Validate with SelectAll.sql

## Examples
In Database/Scripts and Database/Stored-procedures we have all querys with a problem in performance. If you try to run this querys, sql server will not return information because never finish the statment.

The goal of this is improve this query and get the information of each one.

Database/Scripts 
1. MissingIndex.sql -> is a simple query but with a great problem
2. QueryWithMuchColumns -> is a query with a lot of columns
3. QueryWithJoins -> is a query with a lot of joins
4. Parameter-sniffing -> this in some moments return data

Database/Stored-procedures
1. SP-GetCustomerOrderHistory -> report of orders and customers
2. sp_ObtenerHistoricoOrdenes -> SP with pagination
