USE SA_SONEDE;
GO

-- 1. Table Staging : Branchements 2019 par district
IF OBJECT_ID('dbo.Stg_Wael_Branchement_2019', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Wael_Branchement_2019 (
        Region_Brut        NVARCHAR(200) NULL,
        Entreprise         NVARCHAR(60)  NULL,
        SONEDE             NVARCHAR(60)  NULL,
        Total              NVARCHAR(60)  NULL,
        Source_File        NVARCHAR(200) NULL,
        Load_Date          DATETIME2     DEFAULT SYSDATETIME()
    );
END
GO

-- 2. Table Staging : Consommation par abonné - Secteur Collectif (2002-2024)
IF OBJECT_ID('dbo.Stg_Wael_Conso_Collectif', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Wael_Conso_Collectif (
        Annee              NVARCHAR(20)  NULL,
        Secteur_Collectif  NVARCHAR(200) NULL,
        Conso_M3_Par_Abonne NVARCHAR(60) NULL,
        Source_File        NVARCHAR(200) NULL,
        Load_Date          DATETIME2     DEFAULT SYSDATETIME()
    );
END
GO

-- 3. Table Staging : Consommation par abonné - Secteur Domestique (2002-2019, après Unpivot)
IF OBJECT_ID('dbo.Stg_Wael_Conso_Domestique', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Wael_Conso_Domestique (
        Designation        NVARCHAR(200) NULL,
        Annee              NVARCHAR(20)  NULL,
        Conso_M3_Par_Abonne NVARCHAR(60) NULL,
        Source_File        NVARCHAR(200) NULL,
        Load_Date          DATETIME2     DEFAULT SYSDATETIME()
    );
END
GO

-- 4. Table Staging : Consommation par abonné - Secteur Industriel (2002-2024)
IF OBJECT_ID('dbo.Stg_Wael_Conso_Industriel', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Wael_Conso_Industriel (
        Annee              NVARCHAR(20)  NULL,
        Secteur_Industriel NVARCHAR(200) NULL,
        Conso_M3_Par_Abonne NVARCHAR(60) NULL,
        Source_File        NVARCHAR(200) NULL,
        Load_Date          DATETIME2     DEFAULT SYSDATETIME()
    );
END
GO

-- 5. Table Staging : Consommation par usage et par district (2007-2024)
IF OBJECT_ID('dbo.Stg_Wael_Conso_Par_Usage', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Wael_Conso_Par_Usage (
        Annee                  NVARCHAR(20)  NULL,
        Code_District          NVARCHAR(20)  NULL,
        District_Brut          NVARCHAR(200) NULL,
        Domestique_Branche     NVARCHAR(60)  NULL,
        Domestique_Non_Branche NVARCHAR(60)  NULL,
        Commerce               NVARCHAR(60)  NULL,
        Administration         NVARCHAR(60)  NULL,
        Municipal              NVARCHAR(60)  NULL,
        Industrie              NVARCHAR(60)  NULL,
        Tourisme               NVARCHAR(60)  NULL,
        Divers                 NVARCHAR(60)  NULL,
        Source_File            NVARCHAR(200) NULL,
        Load_Date              DATETIME2     DEFAULT SYSDATETIME()
    );
END
GO

-- Requête de vérification attendue : 5 tables créées
SELECT name AS Table_Creee, create_date
FROM sys.tables
WHERE name LIKE 'Stg_Wael_%'
ORDER BY name;