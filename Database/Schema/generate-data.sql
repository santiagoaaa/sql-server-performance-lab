--Poblar tablas
use northwindLab
SET NOCOUNT ON;
ALTER DATABASE northwindLab SET RECOVERY SIMPLE; -- Minimiza el crecimiento del Transaction Log
GO

PRINT '1/8. Generando Catálogos Base (Categories, Warehouses, Employees)...';

-- Categories (10 categorías)
IF (SELECT COUNT(*) FROM dbo.Categories) < 10
BEGIN
    WITH Seq AS (
        SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.Categories (CategoryName, Description)
    SELECT 
        CONCAT('Categoría ', N), 
        CONCAT('Descripción detallada para la categoría de productos número ', N)
    FROM Seq;
END;

-- Warehouses (50 almacenes)
IF (SELECT COUNT(*) FROM dbo.Warehouses) < 50
BEGIN
    WITH Seq AS (
        SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.Warehouses (WarehouseName, Location, IsActive)
    SELECT 
        CONCAT('Almacén Central ', N), 
        CONCAT('Ubicación Industrial Zona ', (N % 10) + 1), 
        1
    FROM Seq;
END;

-- Employees (1,000 empleados)
IF (SELECT COUNT(*) FROM dbo.Employees) < 1000
BEGIN
    WITH Seq AS (
        SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.Employees (EmployeeNumber, FirstName, LastName, Email, Position, HireDate, IsActive)
    SELECT 
        CONCAT('EMP-', RIGHT('00000' + CAST(N AS VARCHAR(5)), 5)),
        CONCAT('Empleado_', N),
        CONCAT('Apellido_', N),
        CONCAT('emp', N, '@empresa.com'),
        CASE WHEN N % 10 = 0 THEN 'Sales Manager' ELSE 'Sales Representative' END,
        DATEADD(DAY, - (N % 1000), CAST('2025-01-01' AS DATE)),
        1
    FROM Seq;
END;
GO

-- ============================================================================
-- 2. CUSTOMERS (1,000,000 Registros)
-- ============================================================================
PRINT '2/8. Insertando 1,000,000 Registros en Customers...';

WITH Seq AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN sys.all_columns c
)
INSERT INTO dbo.Customers (Name, Email, Phone, City, State, Country, CreatedAt, IsActive)
SELECT 
    CONCAT('Cliente ', N),
    CONCAT('customer_', N, '@domain.com'),
    CONCAT('+52-461-', RIGHT('0000000' + CAST(N AS VARCHAR(7)), 7)),
    CONCAT('Ciudad ', (N % 100) + 1),
    CONCAT('Estado ', (N % 32) + 1),
    'Mexico',
    DATEADD(SECOND, - (N % 10000000), SYSDATETIME()),
    1
FROM Seq;
GO
-- ============================================================================
-- 3. PRODUCTS (100,000 Registros)
-- ============================================================================
PRINT '3/8. Insertando 100,000 Registros en Products...';

WITH Seq AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM sys.all_columns a CROSS JOIN sys.all_columns b
)
INSERT INTO dbo.Products (CategoryId, Sku, Name, Price, Cost, IsActive, CreatedAt)
SELECT 
    (N % 10) + 1, -- Relacionado a Categories (1-10)
    CONCAT('SKU-PROD-', RIGHT('000000' + CAST(N AS VARCHAR(6)), 6)),
    CONCAT('Producto Catálogo ', N),
    CAST((N % 5000) + 10.50 AS DECIMAL(18,2)),
    CAST(((N % 5000) + 10.50) * 0.60 AS DECIMAL(18,2)),
    1,
    DATEADD(MINUTE, - (N % 500000), SYSDATETIME())
FROM Seq;
GO
-- ============================================================================
-- 4. INVENTORY (500,000 Registros)
-- ============================================================================
PRINT '4/8. Insertando 500,000 Registros en Inventory...';

-- Relaciona los 100,000 productos distribuidos en los primeros 5 almacenes (500,000 filas únicas)
WITH ProductsSeq AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ProdID
    FROM sys.all_columns a CROSS JOIN sys.all_columns b
),
WarehousesSeq AS (
    SELECT TOP (5) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS WhID
    FROM sys.all_columns
)
INSERT INTO dbo.Inventory (WarehouseId, ProductId, Quantity, ReservedQuantity, LastUpdated)
SELECT 
    w.WhID,
    p.ProdID,
    (p.ProdID % 500) + 50,
    ((p.ProdID % 500) + 50) / 10,
    SYSDATETIME()
FROM ProductsSeq p
CROSS JOIN WarehousesSeq w;
GO
-- ============================================================================
-- 5. ORDERS (5,000,000 Registros) - Inserción por Bloques para evitar desbordamiento
-- ============================================================================
PRINT '5/8. Insertando 5,000,000 Registros en Orders...';

DECLARE @BatchSize INT = 1000000;
DECLARE @I INT = 0;

WHILE @I < 5
BEGIN
    WITH Seq AS (
        SELECT TOP (@BatchSize) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (@I * @BatchSize) AS N
        FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN sys.all_columns c
    )
    INSERT INTO dbo.Orders (CustomerId, EmployeeId, OrderDate, Status, TotalAmount)
    SELECT 
        (N % 1000000) + 1, -- Relacionado a Customers (1 - 1,000,000)
        (N % 1000) + 1,    -- Relacionado a Employees (1 - 1,000)
        DATEADD(MINUTE, - (N % 2000000), SYSDATETIME()),
        CASE WHEN N % 5 = 0 THEN 'Pending' WHEN N % 12 = 0 THEN 'Cancelled' ELSE 'Completed' END,
        CAST((N % 1500) + 100.00 AS DECIMAL(18,2))
    FROM Seq;

    SET @I = @I + 1;
    PRINT CONCAT('    -> Carga Orders bloque ', @I, ' de 5 completada.');
END;
GO
-- ============================================================================
-- 6. ORDERDETAILS (15,000,000 Registros) - 3 Detalles por Cada Orden
-- ============================================================================
PRINT '6/8. Insertando 15,000,000 Registros en OrderDetails...';

DECLARE @OrderBatch INT = 1000000;
DECLARE @J INT = 0;

WHILE @J < 5
BEGIN
    -- Mapea 3 detalles de producto para cada una de las 1,000,000 de órdenes en este bloque
    WITH OrdersBlock AS (
        SELECT TOP (@OrderBatch) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (@J * @OrderBatch) AS OrderId
        FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN sys.all_columns c
    ),
    DetailMultiplier AS (
        SELECT 1 AS ItemNum UNION ALL SELECT 2 UNION ALL SELECT 3
    )
    INSERT INTO dbo.OrderDetails (OrderId, ProductId, Quantity, UnitPrice, Discount)
    SELECT 
        o.OrderId,
        ((o.OrderId * 3 + d.ItemNum) % 100000) + 1, -- Relacionado a Products (1 - 100,000)
        (d.ItemNum * 2),
        CAST(((o.OrderId % 500) + 20.00) AS DECIMAL(18,2)),
        CAST((d.ItemNum * 2.50) AS DECIMAL(5,2))
    FROM OrdersBlock o
    CROSS JOIN DetailMultiplier d;

    SET @J = @J + 1;
    PRINT CONCAT('    -> Carga OrderDetails bloque ', @J, ' de 5 completada.');
END;
GO
-- ============================================================================
-- 7. PAYMENTS (5,000,000 Registros)
-- ============================================================================
-- Nota: La tabla Payments no venía definida en el DDL provisto, por lo que se crea
-- y puebla automáticamente a razón de 1 pago asociado a cada Order.
-- ============================================================================
PRINT '7/8. Creando e insertando 5,000,000 Registros en Payments...';

IF OBJECT_ID('dbo.Payments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payments (
        PaymentId INT IDENTITY(1,1) NOT NULL,
        OrderId INT NOT NULL,
        PaymentDate DATETIME2 NOT NULL CONSTRAINT DF_Payments_PaymentDate DEFAULT SYSDATETIME(),
        Amount DECIMAL(18,2) NOT NULL,
        PaymentMethod VARCHAR(30) NOT NULL,
        TransactionStatus VARCHAR(20) NOT NULL CONSTRAINT DF_Payments_Status DEFAULT 'Approved',
        CONSTRAINT PK_Payments PRIMARY KEY CLUSTERED (PaymentId),
        CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(OrderId) ON DELETE CASCADE
    );
END;

DECLARE @PaymentBatch INT = 1000000;
DECLARE @K INT = 0;

WHILE @K < 5
BEGIN
    WITH OrdersBlock AS (
        SELECT TOP (@PaymentBatch) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (@K * @PaymentBatch) AS OrderId
        FROM sys.all_columns a CROSS JOIN sys.all_columns b CROSS JOIN sys.all_columns c
    )
    INSERT INTO dbo.Payments (OrderId, PaymentDate, Amount, PaymentMethod, TransactionStatus)
    SELECT 
        o.OrderId,
        DATEADD(MINUTE, 30, SYSDATETIME()),
        CAST((o.OrderId % 1500) + 100.00 AS DECIMAL(18,2)),
        CASE WHEN o.OrderId % 3 = 0 THEN 'Credit Card' WHEN o.OrderId % 3 = 1 THEN 'Bank Transfer' ELSE 'Cash' END,
        'Approved'
    FROM OrdersBlock o;

    SET @K = @K + 1;
    PRINT CONCAT('    -> Carga Payments bloque ', @K, ' de 5 completada.');
END;
GO
-- Insertar 1,000 clientes con Country = 'Guatemala'
PRINT '8/8. insertando 1000 Registros en Customers con country Guatemala...';
INSERT INTO dbo.Customers (Name, Email, Country)
SELECT TOP (1000)
    'Cliente GUA ' + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR(10)),
    'gua' + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR(10)) + '@test.com',
    'Guatemala'
FROM sys.all_objects;
GO

-- Restablecer el Recovery Model de la base de datos a su estado original
ALTER DATABASE northwindLab SET RECOVERY FULL;
GO

PRINT '=======================================================';
PRINT '  PROCESO DE INSERCIÓN MASIVA COMPLETADO EXITOSAMENTE';
PRINT '=======================================================';