use northwindLab

CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON [dbo].[Orders] ([CustomerId])


SELECT OrderID, EmployeeId, OrderDate, Status, TotalAmount
FROM Orders
WHERE CustomerId = 10;

