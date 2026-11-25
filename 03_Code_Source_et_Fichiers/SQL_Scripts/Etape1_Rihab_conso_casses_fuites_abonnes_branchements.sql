USE SA_SONEDE;
GO

-- 1. Table Staging pour les branchements globaux (Fichier 3)
IF OBJECT_ID('dbo.Stg_Branchements_Global', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Branchements_Global (
        Annee             NVARCHAR(10),
        Type_Realisation  NVARCHAR(50),
        Nb_Branchements   NVARCHAR(30),
        Source_File       NVARCHAR(200),
        Load_Date         DATETIME2 DEFAULT SYSDATETIME()
    );
END
GO

-- 2. Table Staging pour les abonnés trimestriels par usage (Fichier 5)
IF OBJECT_ID('dbo.Stg_Abonnes_Trimestre', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Abonnes_Trimestre (
        Annee        NVARCHAR(10),
        Trimestre    NVARCHAR(10),
        Usage_       NVARCHAR(100),
        Nb_Abonnes   NVARCHAR(30),
        Source_File  NVARCHAR(200),
        Load_Date    DATETIME2 DEFAULT SYSDATETIME()
    );
END
GO

-- 3. Table Staging pour le taux de branchement des ménages (Fichier 6)
IF OBJECT_ID('dbo.Stg_Taux_Branchement_Menages', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Taux_Branchement_Menages (
        Annee                  NVARCHAR(10),
        Milieu                 NVARCHAR(50),
        Effectif_Menages_1000  NVARCHAR(30),
        Menages_Branches_1000  NVARCHAR(30),
        Taux_Branchement       NVARCHAR(30),
        Source_File            NVARCHAR(200),
        Load_Date              DATETIME2 DEFAULT SYSDATETIME()
    );
END
GO

-- Requête de vérification (résultat attendu : tes 6 tables)
SELECT t.name AS Table_Staging, COUNT(c.column_id) AS Nb_Colonnes
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN (
    'Stg_Conso_Secteur',
    'Stg_Casses',
    'Stg_Branchements_Global',
    'Stg_Fuites',
    'Stg_Abonnes_Trimestre',
    'Stg_Taux_Branchement_Menages'
)
GROUP BY t.name
ORDER BY t.name;