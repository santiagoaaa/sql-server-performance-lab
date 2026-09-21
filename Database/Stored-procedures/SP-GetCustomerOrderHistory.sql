USE northwindLab;
GO

-- ============================================================================
-- Stored Procedure: dbo.GetCustomerOrderHistory
-- DESCRIPCIÓN: Procedimiento intencionalmente ineficiente para pruebas de
--              desempeño, tuning y detección de cuellos de botella en SQL Server.
-- ============================================================================
IF OBJECT_ID('dbo.GetCustomerOrderHistory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GetCustomerOrderHistory;
GO

CREATE PROCEDURE dbo.GetCustomerOrderHistory
    @CustomerId INT = NULL,
    @SearchTerm NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Anti-Patrón 1: DISTINCT innecesario sobre un gran conjunto de datos
    SELECT DISTINCT
        -- Anti-Patrón 2: Conversiones explícitas y funciones sobre columnas
        CAST(c.CustomerId AS VARCHAR(20))                       AS Cliente_ID_Texto,
        UPPER(ISNULL(c.Name, 'SIN NOMBRE'))                     AS NombreCliente,
        LOWER(ISNULL(c.Email, 'contacto@desconocido.com'))       AS CorreoCliente,
        
        -- Anti-Patrón 3: Concatenaciones pesadas de cadenas y formatos de fecha
        CONCAT(c.City, ', ', c.State, ' - ', c.Country)          AS UbicacionCompleta,
        CONVERT(VARCHAR(30), o.OrderDate, 111)                  AS FechaOrdenTexto,
        YEAR(o.OrderDate)                                       AS AnioOrden,
        
        -- Anti-Patrón 4: Subconsultas correlacionadas ejecutadas fila por fila (Efecto RBAR)
        (SELECT COUNT(*) 
         FROM dbo.Orders o2 
         WHERE o2.CustomerId = c.CustomerId)                    AS TotalHistoricoOrdenesCliente,

        (SELECT TOP 1 p.Name 
         FROM dbo.OrderDetails od2 
         INNER JOIN dbo.Products p2 ON od2.ProductId = p2.ProductId 
         WHERE od2.OrderId = o.OrderId)                         AS PrimerProductoDeLaOrden,

        (SELECT COUNT(*) 
         FROM dbo.OrderDetails od3 
         WHERE od3.OrderId = o.OrderId)                         AS CantidadItemsEnOrden,

        -- Datos directos de las tablas en JOIN
        o.OrderId,
        o.Status                                                AS EstadoOrden,
        od.OrderDetailId,
        p.ProductId,
        p.Sku                                                   AS SKU_Producto,
        p.Name                                                  AS NombreProducto,
        cat.CategoryName                                        AS CategoriaProducto,
        
        -- Anti-Patrón 5: Cálculos matemáticos redundantes por cada fila
        od.Quantity,
        od.UnitPrice,
        od.Discount,
        CAST((od.Quantity * od.UnitPrice) AS DECIMAL(18,2))     AS SubTotalBruto,
        CAST((od.Quantity * od.UnitPrice * (1 - (od.Discount / 100.0))) AS DECIMAL(18,2)) AS TotalNetoLinea,

        -- Anti-Patrón 6: Subconsulta a tablas de sistema
        (SELECT TOP 1 name FROM sys.databases WHERE database_id = DB_ID()) AS NombreBD

    FROM dbo.Orders o

    -- Anti-Patrón 7: JOINs Non-SARGable con funciones y conversiones
    LEFT JOIN dbo.Customers c 
        ON CAST(o.CustomerId AS VARCHAR(20)) = CAST(c.CustomerId AS VARCHAR(20))

    LEFT JOIN dbo.OrderDetails od 
        ON CAST(o.OrderId AS VARCHAR(20)) = CAST(od.OrderId AS VARCHAR(20))

    LEFT JOIN dbo.Products p 
        ON od.ProductId = p.ProductId 
        AND ISNULL(p.IsActive, 1) = 1

    LEFT JOIN dbo.Categories cat 
        ON ISNULL(p.CategoryId, 0) = ISNULL(cat.CategoryID, 0)

    -- Anti-Patrón 8: Cláusula WHERE Non-SARGable y comodines frontales (%term%)
    WHERE 
        -- Evita Index Seek en CustomerId mediante coalescencia/parámetro opcional ineficiente
        (@CustomerId IS NULL OR c.CustomerId = @CustomerId OR @CustomerId = 0)
        
        -- Búsqueda por patrón con wildcard al inicio (fuerza Index Scan)
        AND (@SearchTerm IS NULL OR c.Name LIKE '%' + @SearchTerm + '%' OR p.Name LIKE '%' + @SearchTerm + '%')
        
        -- Filtrado con función aplicada directamente a la columna de fecha
        AND YEAR(o.OrderDate) >= 2000
        
        -- Operación aritmética en el filtro
        AND (od.UnitPrice + 0) >= 0

END;
GO