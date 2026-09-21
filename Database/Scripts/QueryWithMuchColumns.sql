USE northwindLab;
GO

SELECT 
    DISTINCT 
    UPPER(ISNULL(c.Name, 'SIN NOMBRE'))                         AS Cliente_Mayusculas,
    LOWER(ISNULL(c.Email, 'SIN_EMAIL@DOMINIO.COM'))              AS Email_Minisculas,
    REVERSE(c.City)                                             AS Ciudad_Al_Reves,
    LEN(c.Name) + LEN(c.City) + LEN(c.Country)                  AS Longitud_Total_Texto_Cliente,

    (SELECT TOP 1 p.Name 
     FROM dbo.OrderDetails od2 
     INNER JOIN dbo.Products p ON od2.ProductId = p.ProductId 
     WHERE od2.OrderId = o.OrderId)                             AS Primer_Producto_De_La_Orden,

    (SELECT COUNT(*) 
     FROM dbo.Orders o2 
     WHERE o2.CustomerId = c.CustomerId)                        AS Total_Historico_Ordenes_Cliente,

    (SELECT SUM(TotalAmount) 
     FROM dbo.Orders o3 
     WHERE o3.CustomerId = c.CustomerId)                        AS Total_Gasto_Historico_Cliente,
    CONCAT(c.CustomerId, ' - ', o.OrderId, ' - ', e.EmployeeID) AS ID_Compuesto_Texto,
    CAST(o.OrderDate AS VARCHAR(50))                            AS Fecha_Como_Texto_Formato_1,
    CONVERT(VARCHAR(30), o.OrderDate, 111)                      AS Fecha_Como_Texto_Formato_2,
    CASE 
        WHEN o.TotalAmount > 1000 THEN 'CLIENTE VIP'
        WHEN o.TotalAmount BETWEEN 500 AND 1000 THEN 'CLIENTE REGULAR'
        ELSE 'CLIENTE OCASIONAL'
    END                                                         AS Categoria_Evaluada_Dinamica,
    e.FirstName + ' ' + e.LastName                             AS Nombre_Empleado,
    e.Position                                                  AS Puesto_Empleado,
    o.TotalAmount                                               AS Monto_Original,
    (o.TotalAmount * 1.16) - (o.TotalAmount * 0.16)             AS Calculo_Matematico_Redundante,
    (SELECT TOP 1 name FROM sys.databases WHERE database_id = DB_ID()) AS Nombre_Base_Datos
FROM dbo.Orders o
LEFT JOIN dbo.Customers c 
    ON CAST(o.CustomerId AS VARCHAR(20)) = CAST(c.CustomerId AS VARCHAR(20))

LEFT JOIN dbo.Employees e 
    ON o.EmployeeId = e.EmployeeID 
    AND e.IsActive = 1
WHERE 
    c.Email LIKE '%@%'
    AND (o.TotalAmount + 0) > 0
    AND YEAR(o.OrderDate) >= 2000

GO