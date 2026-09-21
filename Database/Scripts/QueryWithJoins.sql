USE northwindLab;
GO

SELECT DISTINCT
    -- 1. Subconsultas correlacionadas dentro del SELECT (Efecto RBAR)
    o.OrderId,
    (SELECT TOP 1 UPPER(c.Name) 
     FROM dbo.Customers c 
     WHERE CAST(c.CustomerId AS VARCHAR(20)) = CAST(o.CustomerId AS VARCHAR(20))) AS NombreCliente,

    -- 2. Concatenaciones de texto y funciones innecesarias
    CONCAT(p.Sku, ' - ', LOWER(p.Name), ' - ', cat.CategoryName) AS ProductoInformacionLarga,
    
    -- 3. Cálculos complejos y redundantes evaluados por cada fila
    (od.Quantity * od.UnitPrice) - (od.Quantity * od.UnitPrice * (od.Discount / 100.0)) AS MontoNetoLineaCalculado,
    
    -- 4. Subconsulta a vistas de sistema para forzar I/O adicional por fila
    (SELECT TOP 1 name FROM sys.databases WHERE database_id = DB_ID()) AS BaseDatosActual

FROM dbo.Orders o

-- 5. JOINS con funciones y conversiones de tipo implícitas/explícitas (Non-SARGable)
LEFT JOIN dbo.OrderDetails od 
    ON CAST(o.OrderId AS VARCHAR(20)) = CAST(od.OrderId AS VARCHAR(20))

LEFT JOIN dbo.Products p 
    ON od.ProductId = p.ProductId 
    AND ISNULL(p.IsActive, 1) = 1

LEFT JOIN dbo.Categories cat 
    ON ISNULL(p.CategoryId, 0) = ISNULL(cat.CategoryID, 0)

-- 6. Filtros Non-SARGable en la cláusula WHERE que imposibilitan el uso de Index Seeks
WHERE 
    YEAR(o.OrderDate) >= 2000
    AND p.Name LIKE '%a%'
    AND (od.UnitPrice + 0) > 0

-- 7. Ordenamiento en memoria por campos calculados y cadenas transformadas

GO