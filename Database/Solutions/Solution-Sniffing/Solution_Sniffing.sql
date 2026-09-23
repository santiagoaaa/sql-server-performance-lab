use northwindLab

CREATE NONCLUSTERED INDEX IX_Customers_Country
ON [dbo].[Customers] ([Country])

GO
ALTER PROCEDURE dbo.ObtenerClientesPorPais
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT CustomerId, Name, Email, Country
    FROM dbo.Customers
    WHERE Country = @Country
    OPTION (RECOMPILE); -- Recompila únicamente este SELECT
END;
GO

