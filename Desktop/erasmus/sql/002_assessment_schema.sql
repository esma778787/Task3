IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.Users', N'email') IS NULL
        ALTER TABLE dbo.Users ADD email NVARCHAR(320) NULL;

    IF COL_LENGTH(N'dbo.Users', N'updated_at') IS NULL
        ALTER TABLE dbo.Users ADD updated_at DATETIME2 NULL;
END

GO

IF OBJECT_ID(N'dbo.AssessmentSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AssessmentSessions (
        SessionID BIGINT IDENTITY(1,1) PRIMARY KEY,
        UserID INT NOT NULL,
        ProjectID INT NULL,
        ExternalProjectID NVARCHAR(150) NULL,
        ProjectTitle NVARCHAR(500) NULL,
        ProjectSource NVARCHAR(150) NULL,
        ProjectUrl NVARCHAR(1000) NULL,
        ChallengeType NVARCHAR(50) NOT NULL,
        Status NVARCHAR(30) NOT NULL,
        StartedAt DATETIME2 NOT NULL,
        CompletedAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL,
        UpdatedAt DATETIME2 NOT NULL
    );
END

GO

IF OBJECT_ID(N'dbo.AssessmentAnswers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AssessmentAnswers (
        AnswerID BIGINT IDENTITY(1,1) PRIMARY KEY,
        SessionID BIGINT NOT NULL,
        QuestionID NVARCHAR(150) NOT NULL,
        DisplayOrder INT NOT NULL,
        QuestionType NVARCHAR(100) NULL,
        Skill NVARCHAR(100) NULL,
        CefrLevel NVARCHAR(20) NULL,
        QuestionText NVARCHAR(MAX) NULL,
        PassageText NVARCHAR(MAX) NULL,
        OptionsJson NVARCHAR(MAX) NULL,
        SelectedOptionIndex INT NULL,
        TextAnswer NVARCHAR(MAX) NULL,
        IsCorrect BIT NULL,
        EarnedScore DECIMAL(10,2) NULL,
        MaximumScore DECIMAL(10,2) NULL,
        AnsweredAt DATETIME2 NOT NULL,
        CreatedAt DATETIME2 NOT NULL,
        UpdatedAt DATETIME2 NOT NULL
    );
END

GO

IF OBJECT_ID(N'dbo.EnglishPlacementResults', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EnglishPlacementResults (
        ResultID BIGINT IDENTITY(1,1) PRIMARY KEY,
        SessionID BIGINT NOT NULL,
        EstimatedLevel NVARCHAR(30) NOT NULL,
        Percentage DECIMAL(5,2) NOT NULL,
        CorrectAnswers INT NOT NULL,
        IncorrectAnswers INT NOT NULL,
        EarnedWeightedScore DECIMAL(10,2) NOT NULL,
        MaximumWeightedScore DECIMAL(10,2) NOT NULL,
        GrammarScore DECIMAL(5,2) NULL,
        VocabularyScore DECIMAL(5,2) NULL,
        ReadingScore DECIMAL(5,2) NULL,
        CommunicationScore DECIMAL(5,2) NULL,
        UseOfEnglishScore DECIMAL(5,2) NULL,
        StrengthsJson NVARCHAR(MAX) NULL,
        WeaknessesJson NVARCHAR(MAX) NULL,
        AiFeedback NVARCHAR(MAX) NULL,
        FeedbackSource NVARCHAR(30) NULL,
        AiModel NVARCHAR(150) NULL,
        CreatedAt DATETIME2 NOT NULL,
        UpdatedAt DATETIME2 NOT NULL
    );
END

GO

IF OBJECT_ID(N'dbo.AssessmentSessions', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AssessmentSessions_Users')
        ALTER TABLE dbo.AssessmentSessions ADD CONSTRAINT FK_AssessmentSessions_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(id);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AssessmentSessions_Projects')
        ALTER TABLE dbo.AssessmentSessions ADD CONSTRAINT FK_AssessmentSessions_Projects FOREIGN KEY (ProjectID) REFERENCES dbo.Projects(ProjectID);

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_AssessmentSessions_ChallengeType')
        ALTER TABLE dbo.AssessmentSessions ADD CONSTRAINT CK_AssessmentSessions_ChallengeType CHECK (ChallengeType IN ('english_placement', 'project_fit'));

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_AssessmentSessions_Status')
        ALTER TABLE dbo.AssessmentSessions ADD CONSTRAINT CK_AssessmentSessions_Status CHECK (Status IN ('started', 'completed', 'failed'));
END

GO

IF OBJECT_ID(N'dbo.AssessmentAnswers', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AssessmentAnswers_SessionQuestion')
        CREATE UNIQUE INDEX IX_AssessmentAnswers_SessionQuestion ON dbo.AssessmentAnswers(SessionID, QuestionID);

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AssessmentAnswers_Sessions')
        ALTER TABLE dbo.AssessmentAnswers ADD CONSTRAINT FK_AssessmentAnswers_Sessions FOREIGN KEY (SessionID) REFERENCES dbo.AssessmentSessions(SessionID);
END

GO

IF OBJECT_ID(N'dbo.EnglishPlacementResults', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_EnglishPlacementResults_Session')
        CREATE UNIQUE INDEX IX_EnglishPlacementResults_Session ON dbo.EnglishPlacementResults(SessionID);

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_EnglishPlacementResults_FeedbackSource')
        ALTER TABLE dbo.EnglishPlacementResults ADD CONSTRAINT CK_EnglishPlacementResults_FeedbackSource CHECK (FeedbackSource IN ('openrouter', 'fallback', 'none'));

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_EnglishPlacementResults_Sessions')
        ALTER TABLE dbo.EnglishPlacementResults ADD CONSTRAINT FK_EnglishPlacementResults_Sessions FOREIGN KEY (SessionID) REFERENCES dbo.AssessmentSessions(SessionID);
END

GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Users_Email_Unique')
        CREATE UNIQUE INDEX IX_Users_Email_Unique ON dbo.Users(email) WHERE email IS NOT NULL;
END
