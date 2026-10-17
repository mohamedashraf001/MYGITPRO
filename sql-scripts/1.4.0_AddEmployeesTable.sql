USE [HR_System_DB];
GO


CREATE TABLE medo (
    EmployeeId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    Department NVARCHAR(100) NULL,
    HireDate DATETIME DEFAULT GETDATE()
);
GO

INSERT INTO medo (FullName, Department) VALUES ('Mohamed Ashraf', 'IT Support');
GO