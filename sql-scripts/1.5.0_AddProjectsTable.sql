USE [HR_System_DB];
GO

CREATE TABLE Projects (
    ProjectId INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName NVARCHAR(150) NOT NULL,
    Budget DECIMAL(18,2) NULL,
    StartDate DATETIME DEFAULT GETDATE()
);
GO


INSERT INTO Projects (ProjectName, Budget) VALUES ('eDocument Dynamic System', 50000.00);
GO