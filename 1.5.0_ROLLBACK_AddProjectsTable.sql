USE [HR_System_DB];
GO


IF OBJECT_ID('dbo.Projects', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Projects;
END
GO