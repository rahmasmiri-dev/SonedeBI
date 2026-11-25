/* ============================================================================
   PHASE 3 - ÉTAPE 1 : Partie de FADI (Production, Distribution, Desserte,
                       Taux de branchement ménages & Qualité de l'eau)
   À exécuter APRÈS SONEDE_SQL_Scripts.sql (script du groupe).
   Auteur : Fadi. Relançable : idempotent, sans conflit avec les autres membres.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   1. STAGING (SA_SONEDE) : Vérification des tables du périmètre Fadi
   ---------------------------------------------------------------------------- */
USE SA_SONEDE;
GO

IF OBJECT_ID(N'dbo.Stg_Production', N'U') IS NULL
CREATE TABLE dbo.Stg_Production (
    Annee       NVARCHAR(20),
    Source_Eau  NVARCHAR(150),
    Volume      NVARCHAR(50),
    Unite       NVARCHAR(50),
    Source_File NVARCHAR(255),
    Load_Date   DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'dbo.Stg_Distribution', N'U') IS NULL
CREATE TABLE dbo.Stg_Distribution (
    Annee                   NVARCHAR(20),
    Volume_Distribue_1000m3 NVARCHAR(50),
    Source_File             NVARCHAR(255),
    Load_Date               DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'dbo.Stg_Desserte', N'U') IS NULL
CREATE TABLE dbo.Stg_Desserte (
    Annee                       NVARCHAR(20),
    Region                      NVARCHAR(100),
    Milieu                      NVARCHAR(50),
    Population_Desservie_1000   NVARCHAR(50),
    Source_File                 NVARCHAR(255),
    Load_Date                   DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'dbo.Stg_Taux_Branchement_Menages', N'U') IS NULL
CREATE TABLE dbo.Stg_Taux_Branchement_Menages (
    Annee                 NVARCHAR(20),
    Milieu                NVARCHAR(50),
    Effectif_Menages_1000 NVARCHAR(50),
    Menages_Branches_1000 NVARCHAR(50),
    Taux_Branchement      NVARCHAR(50),
    Source_File           NVARCHAR(255),
    Load_Date             DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'dbo.Stg_Qualite', N'U') IS NULL
CREATE TABLE dbo.Stg_Qualite (
    Annee             NVARCHAR(20),
    Mois              NVARCHAR(30),
    Nb_Analyses       NVARCHAR(50),
    Nb_Non_Conformes  NVARCHAR(50),
    Source_File       NVARCHAR(255),
    Load_Date         DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Procédure utilitaire dédiée au nettoyage du périmètre Fadi avant chargement SSIS
CREATE OR ALTER PROCEDURE dbo.usp_Truncate_Staging_Fadi
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.Stg_Production;
    TRUNCATE TABLE dbo.Stg_Distribution;
    TRUNCATE TABLE dbo.Stg_Desserte;
    TRUNCATE TABLE dbo.Stg_Taux_Branchement_Menages;
    TRUNCATE TABLE dbo.Stg_Qualite;
END;
GO

/* ----------------------------------------------------------------------------
   2. DATA WAREHOUSE (SONEDE_DW) : Dimensions & Faits du périmètre Fadi
   ---------------------------------------------------------------------------- */
USE SONEDE_DW;
GO

-- 2.1. Peuplement idempotent de Dim_Milieu
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Milieu WHERE Milieu = N'Urbain')
    INSERT INTO dbo.Dim_Milieu (Milieu) VALUES (N'Urbain');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Milieu WHERE Milieu = N'Rural')
    INSERT INTO dbo.Dim_Milieu (Milieu) VALUES (N'Rural');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Milieu WHERE Milieu = N'Total')
    INSERT INTO dbo.Dim_Milieu (Milieu) VALUES (N'Total');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Milieu WHERE Milieu = N'Inconnu')
    INSERT INTO dbo.Dim_Milieu (Milieu) VALUES (N'Inconnu');
GO

-- 2.2. Peuplement idempotent de Dim_Source_Eau (sources SONEDE réelles)
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Source_Eau WHERE Source_Libelle = N'Eaux de surface')
    INSERT INTO dbo.Dim_Source_Eau (Source_Libelle, Type_Ressource) VALUES (N'Eaux de surface', N'Surface');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Source_Eau WHERE Source_Libelle = N'Eaux souterraines')
    INSERT INTO dbo.Dim_Source_Eau (Source_Libelle, Type_Ressource) VALUES (N'Eaux souterraines', N'Souterraine');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Source_Eau WHERE Source_Libelle = N'Eaux dessalées')
    INSERT INTO dbo.Dim_Source_Eau (Source_Libelle, Type_Ressource) VALUES (N'Eaux dessalées', N'Non conventionnelle');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Source_Eau WHERE Source_Libelle = N'Total Production')
    INSERT INTO dbo.Dim_Source_Eau (Source_Libelle, Type_Ressource) VALUES (N'Total Production', N'Agrégat');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Source_Eau WHERE Source_Libelle = N'Inconnu')
    INSERT INTO dbo.Dim_Source_Eau (Source_Libelle, Type_Ressource) VALUES (N'Inconnu', N'Inconnu');
GO

-- 2.3. Ajout des niveaux Régionaux / National dans Dim_Territoire pour Fact_Desserte
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Territoire WHERE Gouvernorat = N'National' AND District = N'National')
    INSERT INTO dbo.Dim_Territoire (Code_Gouvernorat, Gouvernorat, District, Zone)
    VALUES (N'TN-NAT', N'National', N'National', N'National');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Territoire WHERE Gouvernorat = N'Grand Tunis' AND District = N'Région Grand Tunis')
    INSERT INTO dbo.Dim_Territoire (Code_Gouvernorat, Gouvernorat, District, Zone)
    VALUES (N'TN-GTU', N'Grand Tunis', N'Région Grand Tunis', N'Grand Tunis');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Territoire WHERE Gouvernorat = N'Nord' AND District = N'Région Nord')
    INSERT INTO dbo.Dim_Territoire (Code_Gouvernorat, Gouvernorat, District, Zone)
    VALUES (N'TN-NRD', N'Nord', N'Région Nord', N'Nord');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Territoire WHERE Gouvernorat = N'Centre' AND District = N'Région Centre')
    INSERT INTO dbo.Dim_Territoire (Code_Gouvernorat, Gouvernorat, District, Zone)
    VALUES (N'TN-CTR', N'Centre', N'Région Centre', N'Centre');
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Territoire WHERE Gouvernorat = N'Sud' AND District = N'Région Sud')
    INSERT INTO dbo.Dim_Territoire (Code_Gouvernorat, Gouvernorat, District, Zone)
    VALUES (N'TN-SUD', N'Sud', N'Région Sud', N'Sud');
GO

-- 2.4. Table de faits dédiée au Taux de branchement des ménages (Fichier Taux_Branchement_Menages)
IF OBJECT_ID(N'dbo.Fact_Taux_Branchement', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Taux_Branchement (
        Fact_ID               INT IDENTITY(1,1) PRIMARY KEY,
        Temps_SK              INT NOT NULL REFERENCES dbo.Dim_Temps(Temps_SK),
        Milieu_SK             INT NOT NULL REFERENCES dbo.Dim_Milieu(Milieu_SK),
        Effectif_Menages_1000 DECIMAL(12,2) NULL,
        Menages_Branches_1000 DECIMAL(12,2) NULL,
        Taux_Branchement_Pct  DECIMAL(6,2)  NULL
    );
    CREATE INDEX IX_FTB_Temps  ON dbo.Fact_Taux_Branchement(Temps_SK);
    CREATE INDEX IX_FTB_Milieu ON dbo.Fact_Taux_Branchement(Milieu_SK);
END;
GO

-- 2.5. Contrôle final du périmètre Fadi
SELECT
    (SELECT COUNT(*) FROM SA_SONEDE.sys.tables WHERE name IN (
        'Stg_Production','Stg_Distribution','Stg_Desserte','Stg_Taux_Branchement_Menages','Stg_Qualite'
    )) AS stg_fadi_ok,
    (SELECT COUNT(*) FROM SONEDE_DW.sys.tables WHERE name IN (
        'Fact_Production','Fact_Distribution','Fact_Desserte','Fact_Taux_Branchement','Fact_Qualite'
    )) AS fact_fadi_ok,
    (SELECT COUNT(*) FROM SONEDE_DW.dbo.Dim_Milieu) AS nb_milieux,
    (SELECT COUNT(*) FROM SONEDE_DW.dbo.Dim_Source_Eau) AS nb_sources_eau;
GO