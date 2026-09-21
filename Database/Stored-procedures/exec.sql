USE northwindLab;

EXEC sp_ObtenerHistoricoOrdenes
    @PageNumber = 1, 
    @PageSize = 5;