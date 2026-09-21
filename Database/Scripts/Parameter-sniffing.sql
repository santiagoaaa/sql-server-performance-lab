USE northwindLab;
GO

-- ============================================================================
-- CONSULTA: Reporte Dinámico de Histórico de Cliente
-- PARÁMETRO DE PRUEBA: 
--   - Si @CustomerId tiene 10-50 registros -> Ejecuta en ~5 ms (Parece "buena")
--   - Si @CustomerId tiene 500,000+ registros -> Escaneo masivo, Spills a TempDB y CPU al 100%
-- ============================================================================

DECLARE @CustomerId INT = 1; -- Cambiar por el ID con millones de filas para ver el colapso

SELECT DISTINCT
    -- Anti-Patrón 1: Conversión explícita y concatenación de cadenas por cada fila
    CAST(c.CustomerId AS VARCHAR(20))                       AS Cliente_ID_Texto,
    UPPER(ISNULL(c.Name, 'SIN NOMBRE'))                     AS NombreCliente,
    CONCAT(c.City, ', ', c.State, ' - ', c.Country)          AS UbicacionCliente,
    
    -- Anti-Patrón 2: Subconsultas correlacionadas ejecutadas N veces (Row-By-Agonizing-Row)
    -- Para 10 filas hace 20 sub-selects. Para 500,000 filas ejecuta 1,000,000 de subconsultas en disco.
    (SELECT COUNT(*) 
     FROM dbo.Orders o2 
     WHERE o2.CustomerId = c.CustomerId)                    AS TotalHistoricoOrdenes,

    (SELECT SUM(od2.Quantity * od2.UnitPrice) 
     FROM dbo.Orders o3 
     INNER JOIN dbo.OrderDetails od2 ON o3.OrderId = od2.OrderId 
     WHERE o3.CustomerId = c.CustomerId)                    AS MapeoGastoTotalCliente,

    -- Datos de la transacción
    o.OrderId,
    CONVERT(VARCHAR(30), o.OrderDate, 111)                  AS FechaOrdenTexto,
    YEAR(o.OrderDate)                                       AS AnioOrden,
    od.OrderDetailId,
    p.Sku                                                   AS SKU_Producto,
    p.Name                                                  AS NombreProducto,
    cat.CategoryName                                        AS CategoriaProducto,
    
    -- Anti-Patrón 3: Expresiones matemáticas complejas en el SELECT
    od.Quantity,
    od.UnitPrice,
    od.Discount,
    CAST((od.Quantity * od.UnitPrice * (1 - (od.Discount / 100.0))) AS DECIMAL(18,2)) AS TotalNetoLinea

FROM dbo.Orders o

-- Anti-Patrón 4: JOINs Non-SARGable con CAST explícito
-- Rompe la capacidad del optimizador de usar Index Seeks, forzando un Clustered Index Scan completo
LEFT JOIN dbo.Customers c 
    ON CAST(o.CustomerId AS VARCHAR(20)) = CAST(c.CustomerId AS VARCHAR(20))

LEFT JOIN dbo.OrderDetails od 
    ON CAST(o.OrderId AS VARCHAR(20)) = CAST(od.OrderId AS VARCHAR(20))

LEFT JOIN dbo.Products p 
    ON od.ProductId = p.ProductId 
    AND ISNULL(p.IsActive, 1) = 1

LEFT JOIN dbo.Categories cat 
    ON ISNULL(p.CategoryId, 0) = ISNULL(cat.CategoryID, 0)

-- Anti-Patrón 5: Cláusula WHERE con funciones sobre columnas y operaciones matemáticas
WHERE 
    -- Destruye la SARGabilidad del índice en CustomerId
    (c.CustomerId + 0) = @CustomerId
    
    -- Función de fecha aplicada a la columna
    AND YEAR(o.OrderDate) >= 2000


GO