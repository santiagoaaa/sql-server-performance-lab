use northwindLab;
GO
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
    DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers (
    CustomerId INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NULL,
    City NVARCHAR(50) NULL,
    State NVARCHAR(50) NULL,
    Country NVARCHAR(50) NOT NULL CONSTRAINT DF_Customers_Country DEFAULT 'Mexico',
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSDATETIME(),
    IsActive BIT NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT 1,
    
    -- Definición de Restricciones
    CONSTRAINT PK_Customers PRIMARY KEY   (CustomerId),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email)
);
GO

IF OBJECT_ID('dbo.Warehouses', 'U') IS NOT NULL
    DROP TABLE dbo.Warehouses;
GO
-- Tabla: Warehouses
CREATE TABLE dbo.Warehouses (
    WarehouseID INT IDENTITY(1,1) NOT NULL,
    WarehouseName NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Warehouses_IsActive DEFAULT 1,
    CONSTRAINT PK_Warehouses PRIMARY KEY   (WarehouseID)
);

GO

IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL
    DROP TABLE dbo.Categories;
GO

CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NULL,
    CONSTRAINT PK_Categories PRIMARY KEY   (CategoryID)
);
GO

-- Verificar si la tabla ya existe y eliminarla para una recreación limpia
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Products (
    ProductId INT IDENTITY(1,1) NOT NULL,
    CategoryId INT NOT NULL,
    Sku VARCHAR(30) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    Cost DECIMAL(18,2) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSDATETIME(),

    -- Definición de Restricciones
    CONSTRAINT PK_Products PRIMARY KEY   (ProductId),
    CONSTRAINT UQ_Products_Sku UNIQUE (Sku),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) 
        REFERENCES dbo.Categories(CategoryID)
);
GO

-- Tabla: Employees
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
    DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees (
    EmployeeID INT IDENTITY(1,1) NOT NULL,
    EmployeeNumber VARCHAR(20) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL, -- Ej. 'Sales Representative', 'Sales Manager'
    HireDate DATE NOT NULL,
    ManagerID INT NULL, -- Autorreferencia para jerarquía de equipo de ventas
    IsActive BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT 1,
    CONSTRAINT PK_Employees PRIMARY KEY  (EmployeeID),
    CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerID) 
        REFERENCES dbo.Employees(EmployeeID)
);

GO

-- Verificar si la tabla ya existe y eliminarla para una recreación limpia
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders (
    OrderId INT IDENTITY(1,1) NOT NULL,
    CustomerId INT NOT NULL,
    EmployeeId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT SYSDATETIME(),
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Orders_Status DEFAULT 'Pending',
    TotalAmount DECIMAL(18,2) NOT NULL,

    -- Definición de Restricciones (Claves Primaria y Foráneas)
    CONSTRAINT PK_Orders PRIMARY KEY   (OrderId),
    --CONSTRAINT FK_Orders_Customers_Orders FOREIGN KEY (CustomerId) 
    --    REFERENCES dbo.Customers(CustomerId),
    --CONSTRAINT FK_Orders_Employees FOREIGN KEY (EmployeeId) 
    --    REFERENCES dbo.Employees(EmployeeId)
);
GO

-- Verificar si la tabla ya existe y eliminarla para una recreación limpia
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL
    DROP TABLE dbo.OrderDetails;
GO

CREATE TABLE dbo.OrderDetails (
    OrderDetailId INT IDENTITY(1,1) NOT NULL,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    Discount DECIMAL(5,2) NOT NULL CONSTRAINT DF_OrderDetails_Discount DEFAULT 0.00,

    -- Definición de Restricciones (Clave Primaria y Claves Foráneas)
    CONSTRAINT PK_OrderDetails PRIMARY KEY   (OrderDetailId),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId) 
        REFERENCES dbo.Orders(OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductId) 
        REFERENCES dbo.Products(ProductId),
    
    ---- Validaciones de Integridad
    --CONSTRAINT CHK_OrderDetails_Quantity CHECK (Quantity > 0),
    --CONSTRAINT CHK_OrderDetails_UnitPrice CHECK (UnitPrice >= 0),
    --CONSTRAINT CHK_OrderDetails_Discount CHECK (Discount BETWEEN 0.00 AND 100.00)
);
GO

IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL
    DROP TABLE dbo.Inventory;
GO

CREATE TABLE dbo.Inventory (
    WarehouseId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL CONSTRAINT DF_Inventory_Quantity DEFAULT 0,
    ReservedQuantity INT NOT NULL CONSTRAINT DF_Inventory_ReservedQuantity DEFAULT 0,
    LastUpdated DATETIME2 NOT NULL CONSTRAINT DF_Inventory_LastUpdated DEFAULT SYSDATETIME(),

    -- Clave Primaria Compuesta
    CONSTRAINT PK_Inventory PRIMARY KEY   (WarehouseId, ProductId),

    -- Relaciones de Clave Foránea
    CONSTRAINT FK_Inventory_Warehouses FOREIGN KEY (WarehouseId) 
        REFERENCES dbo.Warehouses(WarehouseID),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductId) 
        REFERENCES dbo.Products(ProductId),

    -- Validaciones de Integridad Operativa
    --CONSTRAINT CHK_Inventory_Quantity CHECK (Quantity >= 0),
    --CONSTRAINT CHK_Inventory_ReservedQuantity CHECK (ReservedQuantity >= 0),
    --CONSTRAINT CHK_Inventory_ValidReservation CHECK (ReservedQuantity <= Quantity)
);
GO