USE northwindLab;
GO
CREATE PROCEDURE dbo.ObtenerClientesPorPais
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT CustomerId, Name, Email, Country
    FROM dbo.Customers
    WHERE Country = @Country;
END;
GO