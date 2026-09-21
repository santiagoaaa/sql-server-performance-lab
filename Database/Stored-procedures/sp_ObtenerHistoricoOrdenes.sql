USE northwindLab;
GO

CREATE OR alter PROCEDURE dbo.sp_ObtenerHistoricoOrdenes
    @PageNumber INT = 1,     -- Ejemplo: Página 10,000 (Deep Paging)
    @PageSize INT = 50,      -- 50 registros por página
    @AnioConsulta INT = 2026 -- Filtro por año
AS
BEGIN
    SET NOCOUNT ON;

    -- Cálculo del desplazamiento (Offset)
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    SELECT DISTINCT
        -- Columna requerida en el SELECT para solucionar el ORDER BY con DISTINCT
        LEN(ISNULL(p.Name, ''))                         AS LargoNombreProducto,
        
        -- Antipatrón 1: Conversiones explícitas de tipos de datos en la salida
        CAST(o.OrderId AS VARCHAR(50))                  AS OrderId_Texto,
        o.OrderId,                                      -- Se agrega la columna directa para permitir el ORDER BY
        o.OrderDate,
        
        -- Antipatrón 2: Subconsultas correlacionadas por cada fila evaluada (Efecto RBAR)
        (SELECT TOP 1 UPPER(c.Name) 
         FROM dbo.Customers c 
         WHERE CAST(c.CustomerId AS VARCHAR(20)) = CAST(o.CustomerId AS VARCHAR(20))) AS NombreCliente,

        (SELECT TOP 1 CONCAT(e.FirstName, ' ', e.LastName) 
         FROM dbo.Employees e 
         WHERE e.EmployeeID = o.EmployeeId)              AS NombreVendedor,

        p.ProductId,
        p.Sku,
        p.Name                                          AS NombreProducto,
        
        -- Subconsulta extra para traer el nombre de la categoría
        (SELECT cat.CategoryName 
         FROM dbo.Categories cat 
         WHERE ISNULL(cat.CategoryID, 0) = ISNULL(p.CategoryId, 0)) AS Categoria,

        od.Quantity,
        od.UnitPrice,
        od.Discount,

        -- Antipatrón 3: Cálculo en tiempo de ejecución (Monto Neto)
        CAST(((od.Quantity * od.UnitPrice) * (1 - (od.Discount / 100.0))) AS DECIMAL(18,2)) AS TotalNetoLinea,

        -- Antipatrón 4: Subconsulta a tablas de sistema por fila
        (SELECT TOP 1 name FROM sys.databases WHERE database_id = DB_ID()) AS BaseDatosActual

    FROM dbo.Orders o

    -- Antipatrón 5: JOINs Non-SARGable con CAST e ISNULL
    LEFT JOIN dbo.OrderDetails od 
        ON CAST(o.OrderId AS VARCHAR(20)) = CAST(od.OrderId AS VARCHAR(20))

    LEFT JOIN dbo.Products p 
        ON (od.ProductId + 0) = (p.ProductId + 0) 
        AND ISNULL(p.IsActive, 1) = 1

    -- Antipatrón 6: Cláusula WHERE Non-SARGable (aplica función YEAR sobre columna)
    WHERE YEAR(o.OrderDate) = @AnioConsulta
      AND (o.OrderId * 1) > 0

    -- Antipatrón 7: ORDER BY ordenando por columnas que ya están explícitamente en el SELECT
    ORDER BY 
        LEN(ISNULL(p.Name, '')) DESC,
        o.OrderId DESC

    -- Antipatrón 8: Paginación profunda (Deep Paging)
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO