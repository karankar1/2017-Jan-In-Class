/* ****************************
 * Complete Table Creation
 *************************** */
 /*
    Putting text between the [slash][asterix] and the
    [asterix][slash] means that this text inside is a
    multi-line comment.

    [CTRL] + r              -- toggles the "results" pane
    [CTRL] + [SHIFT] + r    -- intellisense - refresh the local cache
*/
-- this is a single-line comment (stars with two dashes)
-- CREATE DATABASE [ESP-A01]
USE [ESP-A01] -- this is a statement that tells us to switch to a particular database
-- Notice in the database name above, I had to "wrap" the name in square brackets
-- because the name had a hyphen in it.
-- For our objects (tables, columns, etc), we won't use hyphens or spaces, so
-- the brackets are optional...
GO  -- this statement helps to "separate" various DDL statements in our script
    -- so that they are executed as "blocks" of code.

/* DROP TABLE statements (to "clean up" the database for re-creation)  */
-- Tables from Specification Document 3

-- Tables from Specification Document 2

-- Tables from Specification Document 1
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'OrderDetails')
    DROP TABLE OrderDetails
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'InventoryItems')
    DROP TABLE InventoryItems
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Orders')
    DROP TABLE Orders
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Customers')
    DROP TABLE Customers

GO

-- To create a database table, we use the CREATE TABLE statement.
-- Note that the order in which we create/drop tables is important
-- because of how the tables are related via Foreign Keys.
CREATE TABLE Customers
(
    -- The body of a CREATE TABLE will identify a comma-separated list of
    -- Column Declarations.
    CustomerNumber  int
        -- A constraint is some sort of restriction for what is (and isn't)
        -- an acceptable value for the column
        CONSTRAINT PK_Customers_CustomerNumber
            -- A primary key constraint means that each row of data MUST
            -- have a unique value AND that this unique value will identify
            -- or distinquish each Customer from other Customers
            -- A primary key constraint results in a CLUSTERED INDEX,
            -- which simply means that the main (or primary) way in which
            -- the data is sorted (indexed) is by the data in this column.
            PRIMARY KEY
            -- An IDENTITY constraint means the database enters values when adding rows
            -- 100 is the "seed" (starting value), and 1 is the increment
            IDENTITY(100, 1)        NOT NULL,   -- NOT NULL when data is Required
    FirstName       varchar(50)     NOT NULL,
    LastName        varchar(60)     NOT NULL,
    [Address]       varchar(40)     NOT NULL,
    City            varchar(35)     NOT NULL,
    Province        char(2)
		-- A Default Constraint means that if no data is supplied for this column
		-- during an INSERT statement, then the default data will be entered.
		CONSTRAINT DF_Customers_Province
			DEFAULT('AB')			-- Strings are in single quotes
		-- A Check Constraint means that if the supplied data does not meet the
		-- requirements of the CHECK, then it will be rejected
		CONSTRAINT CK_Customers_Province
			CHECK  (Province = 'AB' OR
			        Province = 'BC' OR
			        Province = 'SK' OR
			        Province = 'MB' OR
			        Province = 'QC' OR
			        Province = 'NT' OR
			        Province = 'NS' OR
			        Province = 'NL' OR
			        Province = 'YK' OR
			        Province = 'NU' OR
			        Province = 'PE')
					    	        NOT NULL,
    PostalCode      char(6)
        CONSTRAINT CK_Customers_PostalCode
            CHECK (PostalCode LIKE '[A-Z][0-9][A-Z][0-9][A-Z][0-9]')
            -- PostalCode must match the pattern of A#A#A#
            -- In SQL, we can enclose a character pattern inside square brackets
            -- The A-Z means a "range" of characters from A through Z
            -- whereas [0-9] means the digits 0 through 9
                                    NOT NULL,
    PhoneNumber     char(13)
        CONSTRAINT CK_Customers_PhoneNumber
            CHECK (PhoneNumber LIKE
                   '([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
                                        NULL    -- Optional - can be "blank"
)

CREATE TABLE Orders
(
    OrderNumber     int
        CONSTRAINT PK_Orders_OrderNumber
            PRIMARY KEY
            IDENTITY(200, 1)                NOT NULL,
    CustomerNumber  int
        CONSTRAINT FK_Orders_CustomerNumber_Customers_CustomerNumber
            FOREIGN KEY REFERENCES
                Customers(CustomerNumber)   NOT NULL,
    [Date]          datetime                NOT NULL,
    Subtotal        money               
        CONSTRAINT CK_CustomerOrders_Subtotal
            CHECK (Subtotal > 0)            NOT NULL,
    GST             money               
        CONSTRAINT CK_CustomerOrders_GST
            CHECK (GST >= 0)                NOT NULL,
    Total           AS Subtotal + GST       -- Compute the Total instead of storing it
)

CREATE TABLE InventoryItems
(
    ItemNumber          varchar(5)
        CONSTRAINT PK_InventoryItems_ItemNumber
            PRIMARY KEY                 NOT NULL,
    ItemDescription     varchar(50)     NOT NULL,
    CurrentSalePrice    money           NOT NULL,
    InStockCount        int             NOT NULL,
    ReorderLevel        int             NOT NULL
)

CREATE TABLE OrderDetails
(
    OrderNumber     int
        CONSTRAINT FK_OrderDetails_OrderNumber_Orders_OrderNumber
        FOREIGN KEY REFERENCES
            Orders(OrderNumber)         NOT NULL,
    ItemNumber      varchar(5)
        CONSTRAINT FK_OrderDetails_ItemNumber_InventoryItems_ItemNumber
        FOREIGN KEY REFERENCES
            InventoryItems(ItemNumber)  NOT NULL,
    Quantity        int        
        CONSTRAINT DF_OrderDetails_Quantity
            DEFAULT (1)
        CONSTRAINT CK_OrderDetails_Quantity
            CHECK (Quantity > 0)
                                        NOT NULL,
    SellingPrice    money           
        CONSTRAINT CK_OrderDetails_SellingPrice
            CHECK (SellingPrice >= 0)
                                        NOT NULL,
    Amount          AS Quantity * SellingPrice  , -- Computed Column
    -- The following is a Table Constraint
    --  Composite Keys must be done as Table Constraints
    CONSTRAINT PK_OrderDetails_OrderNumber_ItemNumber
        PRIMARY KEY (OrderNumber, ItemNumber)
)

GO
-- End of tables for Specification Document 1

-- Assuming that the database is now being used, there may be a bunch of data in the database.
-- Inserting Customer data
INSERT INTO Customers(FirstName, LastName, [Address], City, PostalCode)
    VALUES ('Clark', 'Kent', '344 Clinton Street', 'Metropolis', 'S0S0N0')
INSERT INTO Customers(FirstName, LastName, [Address], City, PostalCode)
    VALUES ('Jimmy', 'Olsen', '242 River Close', 'Bakerline', 'B4K3R1')

-- Inserting inventory items
INSERT INTO InventoryItems(ItemNumber, ItemDescription, CurrentSalePrice, InStockCount, ReorderLevel)
    VALUES ('H8726', 'Cleaning Fan belt', 29.95, 3, 5),
           ('H8621', 'Engine Fan belt', 17.45, 10, 5)

-- Inserting an order
INSERT INTO Orders(CustomerNumber, [Date], Subtotal, GST)
    VALUES (100, GETDATE(), 17.45, 0.87)
INSERT INTO OrderDetails(OrderNumber, ItemNumber, Quantity, SellingPrice)
    VALUES (200, 'H8726', 1, 17.45)
GO

-- We can see data in our tables by doing SELECT statements
-- Select the customer information
SELECT  CustomerNumber, FirstName, LastName, 
        [Address] + ' ' + City + ', ' + Province AS 'Customer Address',
        PhoneNumber
FROM    Customers


/* ======================================================
 *   STUDENT  PRACTICE  (and solutions)                  
 * ====================================================== */

/*** Day 1
 *      Add simple CREATE TABLE and DROP TABLE statements
 *      for the tables in Specification Documents 2 & 3
 */

/* **********************************************
 * Specification Document 2
 * - Payments and PaymentLogDetails
 * ******************************************* */
 
/* **********************************************
 * Specification Document 3
 * - Suppliers, PurchaseOrders, PurchaseOrderItems,
 *   ChequeRegisters, PurchaseOrderPayments
 * ******************************************* */