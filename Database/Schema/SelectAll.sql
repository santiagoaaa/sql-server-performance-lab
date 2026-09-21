USE northwindLab;
GO

-- 1. Customers
SELECT TOP 100 
    CustomerId, Name, Email, Phone, City, State, Country, CreatedAt, IsActive 
FROM dbo.Customers;

-- 2. Warehouses
SELECT TOP 100 
    WarehouseID, WarehouseName, Location, IsActive 
FROM dbo.Warehouses;

-- 3. Categories
SELECT TOP 100 
    CategoryID, CategoryName, Description 
FROM dbo.Categories;

-- 4. Products
SELECT TOP 100 
    ProductId, CategoryId, Sku, Name, Price, Cost, IsActive, CreatedAt 
FROM dbo.Products;

-- 5. Employees
SELECT TOP 100 
    EmployeeID, EmployeeNumber, FirstName, LastName, Email, Position, HireDate, ManagerID, IsActive 
FROM dbo.Employees;

-- 6. Orders
SELECT TOP 100 
    OrderId, CustomerId, EmployeeId, OrderDate, Status, TotalAmount 
FROM dbo.Orders;

-- 7. OrderDetails
SELECT TOP 100 
    OrderDetailId, OrderId, ProductId, Quantity, UnitPrice, Discount 
FROM dbo.OrderDetails;

-- 8. Inventory
SELECT TOP 100 
    WarehouseId, ProductId, Quantity, ReservedQuantity, LastUpdated 
FROM dbo.Inventory;