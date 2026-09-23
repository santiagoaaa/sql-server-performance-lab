use northwindLab
--Revisar cantidad de paises

--SELECT distinct Country, COUNT(*) as CantidadRegistrosP
--    FROM dbo.Customers
--group by Country

--Realizar mediciones
SET STATISTICS IO, TIME ON;
GO
    ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
    Exec dbo.ObtenerClientesPorPais @country = 'Guatemala'
    Exec dbo.ObtenerClientesPorPais @country = 'Mexico'
GO
--SET STATISTICS IO, TIME OFF;