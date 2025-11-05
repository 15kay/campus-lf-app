-- WSU Campus Lost & Found Database Schema
-- Execute this script in SQL Server Management Studio

CREATE DATABASE CampusLostFound
ON (FILENAME = 'E:\CampusLostFound.mdf')
LOG ON (FILENAME = 'E:\CampusLostFound.ldf');
GO

USE CampusLostFound;
GO

-- Users table
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    StudentId NVARCHAR(50),
    Phone NVARCHAR(20),
    IsAdmin BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Items table
CREATE TABLE Items (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Location NVARCHAR(200),
    DateTime DATETIME2 NOT NULL,
    IsLost BIT NOT NULL,
    ContactInfo NVARCHAR(255),
    Category NVARCHAR(50),
    ImagePath NVARCHAR(500),
    UserId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Messages table
CREATE TABLE Messages (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SenderId UNIQUEIDENTIFIER NOT NULL,
    ReceiverId UNIQUEIDENTIFIER NOT NULL,
    ItemId UNIQUEIDENTIFIER,
    Content NVARCHAR(MAX) NOT NULL,
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (SenderId) REFERENCES Users(Id),
    FOREIGN KEY (ReceiverId) REFERENCES Users(Id),
    FOREIGN KEY (ItemId) REFERENCES Items(Id)
);

-- Forum Posts table
CREATE TABLE ForumPosts (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    Category NVARCHAR(50),
    ViewCount INT DEFAULT 0,
    LikeCount INT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Forum Comments table
CREATE TABLE ForumComments (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PostId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (PostId) REFERENCES ForumPosts(Id) ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- Notifications table
CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    IsRead BIT DEFAULT 0,
    ItemId UNIQUEIDENTIFIER,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (ItemId) REFERENCES Items(Id)
);

-- User Karma/Points table
CREATE TABLE UserKarma (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Points INT DEFAULT 0,
    Reason NVARCHAR(200),
    ItemId UNIQUEIDENTIFIER,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (ItemId) REFERENCES Items(Id)
);

-- Smart Matches table
CREATE TABLE SmartMatches (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    LostItemId UNIQUEIDENTIFIER NOT NULL,
    FoundItemId UNIQUEIDENTIFIER NOT NULL,
    MatchScore DECIMAL(3,2) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Pending',
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (LostItemId) REFERENCES Items(Id),
    FOREIGN KEY (FoundItemId) REFERENCES Items(Id)
);

-- User Sessions table (for authentication)
CREATE TABLE UserSessions (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Token NVARCHAR(500) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IX_Items_UserId ON Items(UserId);
CREATE INDEX IX_Items_DateTime ON Items(DateTime DESC);
CREATE INDEX IX_Items_Category ON Items(Category);
CREATE INDEX IX_Items_IsLost ON Items(IsLost);
CREATE INDEX IX_Messages_SenderId ON Messages(SenderId);
CREATE INDEX IX_Messages_ReceiverId ON Messages(ReceiverId);
CREATE INDEX IX_Messages_CreatedAt ON Messages(CreatedAt DESC);
CREATE INDEX IX_ForumPosts_UserId ON ForumPosts(UserId);
CREATE INDEX IX_ForumPosts_CreatedAt ON ForumPosts(CreatedAt DESC);
CREATE INDEX IX_ForumComments_PostId ON ForumComments(PostId);
CREATE INDEX IX_Notifications_UserId ON Notifications(UserId);
CREATE INDEX IX_Notifications_IsRead ON Notifications(IsRead);
CREATE INDEX IX_UserKarma_UserId ON UserKarma(UserId);
CREATE INDEX IX_SmartMatches_LostItemId ON SmartMatches(LostItemId);
CREATE INDEX IX_SmartMatches_FoundItemId ON SmartMatches(FoundItemId);
CREATE INDEX IX_UserSessions_UserId ON UserSessions(UserId);
CREATE INDEX IX_UserSessions_Token ON UserSessions(Token);

-- Item Status History table
CREATE TABLE ItemStatusHistory (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ItemId UNIQUEIDENTIFIER NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    UpdatedBy UNIQUEIDENTIFIER NOT NULL,
    Notes NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ItemId) REFERENCES Items(Id) ON DELETE CASCADE,
    FOREIGN KEY (UpdatedBy) REFERENCES Users(Id)
);

-- Campus Locations table
CREATE TABLE CampusLocations (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(100) NOT NULL,
    Campus NVARCHAR(50) NOT NULL,
    Building NVARCHAR(100),
    Floor NVARCHAR(20),
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAtDATETIME2 DEFAULT GETDATE()
);

-- User Preferences table
CREATE TABLE UserPreferences (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    EmailNotifications BIT DEFAULT 1,
    PushNotifications BIT DEFAULT 1,
    SMSNotifications BIT DEFAULT 0,
    DarkMode BIT DEFAULT 0,
    Language NVARCHAR(10) DEFAULT 'en',
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Admin Logs table
CREATE TABLE AdminLogs (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    AdminId UNIQUEIDENTIFIER NOT NULL,
    Action NVARCHAR(100) NOT NULL,
    TargetType NVARCHAR(50),
    TargetId UNIQUEIDENTIFIER,
    Details NVARCHAR(MAX),
    IPAddress NVARCHAR(45),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (AdminId) REFERENCES Users(Id)
);

-- Additional indexes
CREATE INDEX IX_ItemStatusHistory_ItemId ON ItemStatusHistory(ItemId);
CREATE INDEX IX_CampusLocations_Campus ON CampusLocations(Campus);
CREATE INDEX IX_UserPreferences_UserId ON UserPreferences(UserId);
CREATE INDEX IX_AdminLogs_AdminId ON AdminLogs(AdminId);
CREATE INDEX IX_AdminLogs_CreatedAt ON AdminLogs(CreatedAt DESC);

-- Insert default campus locations
INSERT INTO CampusLocations (Name, Campus, Building, Description) VALUES
('Main Entrance', 'Buffalo City', 'Main Building', 'Primary campus entrance'),
('Library', 'Buffalo City', 'Library Building', 'Main campus library'),
('Student Center', 'Buffalo City', 'Student Center', 'Student activities center'),
('Cafeteria', 'Buffalo City', 'Dining Hall', 'Main dining facility'),
('Residence Halls', 'Buffalo City', 'Various', 'Student accommodation areas'),
('Main Entrance', 'Butterworth', 'Main Building', 'Butterworth campus entrance'),
('Library', 'Butterworth', 'Academic Block', 'Butterworth campus library'),
('Main Entrance', 'Queenstown', 'Administration', 'Queenstown campus entrance'),
('Library', 'Queenstown', 'Academic Building', 'Queenstown campus library'),
('Main Entrance', 'Mthatha', 'Main Block', 'Mthatha campus entrance'),
('Library', 'Mthatha', 'Learning Center', 'Mthatha campus library');

-- Insert notification types
INSERT INTO Notifications (Id, UserId, Title, Message, Type, IsRead, CreatedAt) VALUES
(NEWID(), '00000000-0000-0000-0000-000000000000', 'System', 'Welcome to WSU Campus Lost & Found!', 'System', 1, GETDATE());