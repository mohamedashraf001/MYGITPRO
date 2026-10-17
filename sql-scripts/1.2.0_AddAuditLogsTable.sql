USE [HR_System_DB];
GO


CREATE TABLE AuditLogs (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    ActionName NVARCHAR(100) NOT NULL,
    UserName NVARCHAR(100) NOT NULL,
    ActionDate DATETIME DEFAULT GETDATE()
);
GO


INSERT INTO AuditLogs (ActionName, UserName) VALUES ('Database Migration 1.2.0 Applied', 'System_Admin');
GO