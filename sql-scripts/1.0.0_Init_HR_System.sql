
CREATE DATABASE [HR_System_DB];
GO

USE [HR_System_DB];
GO


CREATE TABLE Departments (
    DeptId INT IDENTITY(1,1) PRIMARY KEY,
    DeptName NVARCHAR(100) NOT NULL
);
GO


INSERT INTO Departments (DeptName) VALUES ('IT Application Support'), ('Human Resources');
GO