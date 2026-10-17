USE [HR_System_DB];
GO


IF OBJECT_ID('dbo.MissingRollbackDemo', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.MissingRollbackDemo;
END
GO