USE [HR_System_DB];
GO


IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Departments;
END
GO