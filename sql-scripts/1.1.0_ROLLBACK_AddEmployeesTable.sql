USE [HR_System_DB];
GO

 
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Employees;
END
GO