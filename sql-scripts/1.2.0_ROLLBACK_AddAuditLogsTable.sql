USE [HR_System_DB];
GO


IF OBJECT_ID('dbo.AuditLogs', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.AuditLogs;
END
GO