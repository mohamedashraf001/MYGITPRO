USE [HR_System_DB];
GO


CREATE TABLE MissingRollbackDemo (
    DemoId INT IDENTITY(1,1) PRIMARY KEY,
    Notes NVARCHAR(200) NOT NULL
);
GO

INSERT INTO MissingRollbackDemo (Notes) VALUES ('Testing missing rollback scenario');
GO