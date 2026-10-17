USE [HR_System_DB];
GO


CREATE TABLE Employees (
    EmpId INT IDENTITY(1,1) PRIMARY KEY,
    EmpName NVARCHAR(100) NOT NULL,
    DeptId INT NULL
);
GO

INSERT INTO Employees (EmpName, DeptId) VALUES ('Mohamed Ashraf', 1);
GO