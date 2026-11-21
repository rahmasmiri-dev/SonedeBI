/* =====================================================================
   DS1 - SONEDE BI : scripts SQL (SA_SONEDE + SONEDE_DW)
   ATTENTION : les noms de colonnes de staging sont a ADAPTER aux
   fichiers Excel reels apres votre Data Profiling.
   ===================================================================== */

/* ---------- 1. BASES ---------- */
IF DB_ID('SA_SONEDE') IS NULL CREATE DATABASE SA_SONEDE;
IF DB_ID('SONEDE_DW') IS NULL CREATE DATABASE SONEDE_DW;
GO

/* =====================================================================
   2. STAGING  (SA_SONEDE) : tout en NVARCHAR, aucune contrainte
   ===================================================================== */
USE SA_SONEDE;
GO
CREATE TABLE dbo.Log_ETL_Execution (
    LogID        INT IDENTITY(1,1) PRIMARY KEY,
    PackageName  VARCHAR(100),
    StartTime    DATETIME2 DEFAULT SYSDATETIME(),
    EndTime      DATETIME2 NULL,
    Status       VARCHAR(20) DEFAULT 'RUNNING',  -- RUNNING / SUCCESS / FAILED
    RowsRead     INT NULL,
    RowsLoaded   INT NULL,
    RowsRejected INT NULL,
    ErrorMessage NVARCHAR(4000) NULL
);

CREATE TABLE dbo.Stg_Barrages (
    Barrage NVARCHAR(100), Date_Releve NVARCHAR(30), Reserve_Mm3 NVARCHAR(30),
    Capacite_Mm3 NVARCHAR(30), Taux_Remplissage NVARCHAR(30), Apports_Mm3 NVARCHAR(30),
    Gouvernorat NVARCHAR(100), Latitude NVARCHAR(30), Longitude NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Production (
    Annee NVARCHAR(10), Source_Eau NVARCHAR(100), Volume NVARCHAR(30), Unite NVARCHAR(20),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Distribution (
    Annee NVARCHAR(10), Volume_Distribue_1000m3 NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Conso_Usage_Region (
    Annee NVARCHAR(10), Region NVARCHAR(100), Usage_ NVARCHAR(100), Volume_1000m3 NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Conso_Secteur (
    Annee NVARCHAR(10), Secteur NVARCHAR(100), Volume_1000m3 NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Conso_Par_Abonne (
    Annee NVARCHAR(10), Secteur NVARCHAR(100), Conso_m3_Par_Abonne NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Abonnes (
    Annee NVARCHAR(10), Region NVARCHAR(100), Usage_ NVARCHAR(100), Nb_Abonnes NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Desserte (
    Annee NVARCHAR(10), Milieu NVARCHAR(50), Region NVARCHAR(100), Population_Desservie_1000 NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Tarifs (
    Trimestre NVARCHAR(20), Annee NVARCHAR(10), Categorie NVARCHAR(100), Redevance NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Casses (
    Annee NVARCHAR(10), Type_Reseau NVARCHAR(100), Origine NVARCHAR(50), Nb_Casses NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Fuites (
    Annee NVARCHAR(10), Type_Reseau NVARCHAR(100), Nb_Fuites NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Qualite (
    Annee NVARCHAR(10), Mois NVARCHAR(20), Nb_Analyses NVARCHAR(30), Nb_Non_Conformes NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
-- Sources complementaires (exigence : au moins 2)
CREATE TABLE dbo.Stg_Climat (
    Gouvernorat NVARCHAR(100), Annee NVARCHAR(10), Mois NVARCHAR(10),
    Pluviometrie_mm NVARCHAR(30), Temp_Moy_C NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Population (
    Gouvernorat NVARCHAR(100), Annee NVARCHAR(10), Population NVARCHAR(30), Nb_Menages NVARCHAR(30),
    Source_File NVARCHAR(200), Load_Date DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Stg_Ref_Gouvernorat (   -- referentiel de mapping des noms
    Nom_Brut NVARCHAR(100), Gouvernorat_Std NVARCHAR(100), Zone NVARCHAR(50), Code_ISO NVARCHAR(10)
);
GO

/* Vidage du staging (tache SQL du flux de controle SSIS) */
CREATE OR ALTER PROCEDURE dbo.usp_Truncate_Staging AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.Stg_Barrages;      TRUNCATE TABLE dbo.Stg_Production;
    TRUNCATE TABLE dbo.Stg_Distribution;  TRUNCATE TABLE dbo.Stg_Conso_Usage_Region;
    TRUNCATE TABLE dbo.Stg_Conso_Secteur; TRUNCATE TABLE dbo.Stg_Conso_Par_Abonne;
    TRUNCATE TABLE dbo.Stg_Abonnes;       TRUNCATE TABLE dbo.Stg_Desserte;
    TRUNCATE TABLE dbo.Stg_Tarifs;        TRUNCATE TABLE dbo.Stg_Casses;
    TRUNCATE TABLE dbo.Stg_Fuites;        TRUNCATE TABLE dbo.Stg_Qualite;
    TRUNCATE TABLE dbo.Stg_Climat;        TRUNCATE TABLE dbo.Stg_Population;
    -- Stg_Ref_Gouvernorat est un referentiel : on ne le vide pas
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Log_Start @Package VARCHAR(100), @LogID INT OUTPUT AS
BEGIN
    INSERT dbo.Log_ETL_Execution(PackageName) VALUES(@Package);
    SET @LogID = SCOPE_IDENTITY();
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Log_End
    @LogID INT, @Status VARCHAR(20), @Read INT=NULL, @Loaded INT=NULL, @Rejected INT=NULL, @Err NVARCHAR(4000)=NULL AS
BEGIN
    UPDATE dbo.Log_ETL_Execution
       SET EndTime=SYSDATETIME(), Status=@Status, RowsRead=@Read, RowsLoaded=@Loaded,
           RowsRejected=@Rejected, ErrorMessage=@Err
     WHERE LogID=@LogID;
END;
GO

/* =====================================================================
   3. ENTREPOT  (SONEDE_DW) : schema en constellation
   ===================================================================== */
USE SONEDE_DW;
GO
/* ---------- DIMENSIONS ---------- */
CREATE TABLE dbo.Dim_Temps (
    Temps_SK     INT IDENTITY(1,1) PRIMARY KEY,
    Date_Key     INT NOT NULL,                -- yyyymmdd (annuel => yyyy0101)
    Date_Complete DATE NOT NULL,
    Annee        SMALLINT NOT NULL,
    Semestre     TINYINT NOT NULL,
    Trimestre    TINYINT NOT NULL,
    Mois         TINYINT NOT NULL,
    Nom_Mois     VARCHAR(20) NOT NULL,
    Saison       VARCHAR(10) NOT NULL,        -- Hiver/Printemps/Ete/Automne
    Est_Ete      BIT NOT NULL,                -- Juin-Septembre
    CONSTRAINT UQ_Dim_Temps UNIQUE (Date_Key)
);
CREATE TABLE dbo.Dim_Territoire (
    Territoire_SK INT IDENTITY(1,1) PRIMARY KEY,
    Code_Gouvernorat VARCHAR(10) NOT NULL,
    Gouvernorat  VARCHAR(100) NOT NULL,
    Zone         VARCHAR(50) NOT NULL,        -- Nord / Centre / Sud ...
    District     VARCHAR(100) NULL,           -- district SONEDE si disponible
    Latitude     DECIMAL(9,6) NULL,
    Longitude    DECIMAL(9,6) NULL,
    CONSTRAINT UQ_Dim_Territoire UNIQUE (Code_Gouvernorat)
);
CREATE TABLE dbo.Dim_Barrage (
    Barrage_SK   INT IDENTITY(1,1) PRIMARY KEY,
    Nom_Barrage  VARCHAR(100) NOT NULL,
    Territoire_SK INT NULL,
    Capacite_Max_Mm3 DECIMAL(18,3) NULL,
    Latitude     DECIMAL(9,6) NULL,
    Longitude    DECIMAL(9,6) NULL,
    CONSTRAINT UQ_Dim_Barrage UNIQUE (Nom_Barrage),
    CONSTRAINT FK_Barrage_Terr FOREIGN KEY (Territoire_SK) REFERENCES dbo.Dim_Territoire(Territoire_SK)
);
CREATE TABLE dbo.Dim_Usage (
    Usage_SK     INT IDENTITY(1,1) PRIMARY KEY,
    Usage_Libelle VARCHAR(100) NOT NULL,      -- Domestique, Industriel, Touristique, Collectif, Administratif...
    Secteur      VARCHAR(50) NOT NULL,        -- Domestique / Collectif / Industriel / Autre
    CONSTRAINT UQ_Dim_Usage UNIQUE (Usage_Libelle)
);
CREATE TABLE dbo.Dim_Source_Eau (
    Source_SK    INT IDENTITY(1,1) PRIMARY KEY,
    Source_Libelle VARCHAR(100) NOT NULL,     -- Barrages, Nappes profondes, Nappes phreatiques, Dessalement...
    Type_Ressource VARCHAR(30) NOT NULL,      -- Surface / Souterraine / Non conventionnelle
    CONSTRAINT UQ_Dim_Source UNIQUE (Source_Libelle)
);
CREATE TABLE dbo.Dim_Type_Reseau (
    Reseau_SK    INT IDENTITY(1,1) PRIMARY KEY,
    Type_Reseau  VARCHAR(100) NOT NULL,       -- Adduction, Distribution, Branchement
    CONSTRAINT UQ_Dim_Reseau UNIQUE (Type_Reseau)
);
CREATE TABLE dbo.Dim_Type_Intervention (
    Intervention_SK INT IDENTITY(1,1) PRIMARY KEY,
    Nature       VARCHAR(20) NOT NULL,        -- Casse / Fuite
    Origine      VARCHAR(30) NOT NULL,        -- Provoquee / Spontanee / Non applicable
    CONSTRAINT UQ_Dim_Interv UNIQUE (Nature, Origine)
);
CREATE TABLE dbo.Dim_Milieu (
    Milieu_SK    INT IDENTITY(1,1) PRIMARY KEY,
    Milieu       VARCHAR(30) NOT NULL,        -- Communal / Non communal
    CONSTRAINT UQ_Dim_Milieu UNIQUE (Milieu)
);

/* ---------- FAITS ---------- */
-- F1 : etat mensuel des barrages (grain : barrage x mois)
CREATE TABLE dbo.Fact_Barrage (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Barrage_SK INT NOT NULL,
    Reserve_Mm3 DECIMAL(18,3) NULL, Capacite_Mm3 DECIMAL(18,3) NULL,
    Taux_Remplissage_Pct DECIMAL(18,3) NULL, Apports_Mm3 DECIMAL(18,3) NULL,
    CONSTRAINT FK_FB_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FB_B FOREIGN KEY (Barrage_SK) REFERENCES dbo.Dim_Barrage(Barrage_SK),
    CONSTRAINT UQ_FB UNIQUE (Temps_SK, Barrage_SK)
);
-- F2 : production annuelle par source (grain : annee x source)
CREATE TABLE dbo.Fact_Production (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Source_SK INT NOT NULL,
    Volume_Produit_1000m3 DECIMAL(18,3) NULL,
    CONSTRAINT FK_FP_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FP_S FOREIGN KEY (Source_SK) REFERENCES dbo.Dim_Source_Eau(Source_SK),
    CONSTRAINT UQ_FP UNIQUE (Temps_SK, Source_SK)
);
-- F3 : distribution annuelle (grain : annee)
CREATE TABLE dbo.Fact_Distribution (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL,
    Volume_Distribue_1000m3 DECIMAL(18,3) NULL,
    CONSTRAINT FK_FD_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT UQ_FD UNIQUE (Temps_SK)
);
-- F4 : consommation / abonnes (grain : annee x gouvernorat x usage)
CREATE TABLE dbo.Fact_Consommation (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Territoire_SK INT NOT NULL, Usage_SK INT NOT NULL,
    Volume_Facture_1000m3 DECIMAL(18,3) NULL,
    Nb_Abonnes BIGINT NULL,
    Conso_Par_Abonne_m3 DECIMAL(18,3) NULL,
    CONSTRAINT FK_FC_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FC_R FOREIGN KEY (Territoire_SK) REFERENCES dbo.Dim_Territoire(Territoire_SK),
    CONSTRAINT FK_FC_U FOREIGN KEY (Usage_SK) REFERENCES dbo.Dim_Usage(Usage_SK),
    CONSTRAINT UQ_FC UNIQUE (Temps_SK, Territoire_SK, Usage_SK)
);
-- F5 : desserte (grain : annee x gouvernorat x milieu)
CREATE TABLE dbo.Fact_Desserte (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Territoire_SK INT NOT NULL, Milieu_SK INT NOT NULL,
    Population_Desservie_1000 DECIMAL(18,3) NULL,
    CONSTRAINT FK_FDe_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FDe_R FOREIGN KEY (Territoire_SK) REFERENCES dbo.Dim_Territoire(Territoire_SK),
    CONSTRAINT FK_FDe_M FOREIGN KEY (Milieu_SK) REFERENCES dbo.Dim_Milieu(Milieu_SK),
    CONSTRAINT UQ_FDe UNIQUE (Temps_SK, Territoire_SK, Milieu_SK)
);
-- F6 : interventions reseau (grain : annee x type reseau x nature/origine)
CREATE TABLE dbo.Fact_Intervention_Reseau (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Reseau_SK INT NOT NULL, Intervention_SK INT NOT NULL,
    Nb_Interventions INT NULL,
    CONSTRAINT FK_FI_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FI_R FOREIGN KEY (Reseau_SK) REFERENCES dbo.Dim_Type_Reseau(Reseau_SK),
    CONSTRAINT FK_FI_I FOREIGN KEY (Intervention_SK) REFERENCES dbo.Dim_Type_Intervention(Intervention_SK),
    CONSTRAINT UQ_FI UNIQUE (Temps_SK, Reseau_SK, Intervention_SK)
);
-- F7 : qualite bacteriologique (grain : mois)
CREATE TABLE dbo.Fact_Qualite (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL,
    Nb_Analyses INT NULL, Nb_Non_Conformes INT NULL,
    CONSTRAINT FK_FQ_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT UQ_FQ UNIQUE (Temps_SK)
);
-- F8 : contexte climat + demographie (grain : mois x gouvernorat ; population repetee/annuelle)
CREATE TABLE dbo.Fact_Climat_Demo (
    Fact_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Temps_SK INT NOT NULL, Territoire_SK INT NOT NULL,
    Pluviometrie_mm DECIMAL(18,3) NULL, Temp_Moy_C DECIMAL(18,3) NULL,
    Population BIGINT NULL, Nb_Menages BIGINT NULL,
    CONSTRAINT FK_FCD_T FOREIGN KEY (Temps_SK) REFERENCES dbo.Dim_Temps(Temps_SK),
    CONSTRAINT FK_FCD_R FOREIGN KEY (Territoire_SK) REFERENCES dbo.Dim_Territoire(Territoire_SK),
    CONSTRAINT UQ_FCD UNIQUE (Temps_SK, Territoire_SK)
);
GO

/* ---------- INDEXATION STRATEGIQUE (cles etrangeres des faits) ---------- */
CREATE INDEX IX_FB_Temps   ON dbo.Fact_Barrage(Temps_SK)   INCLUDE (Reserve_Mm3, Taux_Remplissage_Pct);
CREATE INDEX IX_FB_Barrage ON dbo.Fact_Barrage(Barrage_SK);
CREATE INDEX IX_FP_Source  ON dbo.Fact_Production(Source_SK);
CREATE INDEX IX_FC_Terr    ON dbo.Fact_Consommation(Territoire_SK) INCLUDE (Volume_Facture_1000m3, Nb_Abonnes);
CREATE INDEX IX_FC_Usage   ON dbo.Fact_Consommation(Usage_SK);
CREATE INDEX IX_FC_Temps   ON dbo.Fact_Consommation(Temps_SK);
CREATE INDEX IX_FDe_Terr   ON dbo.Fact_Desserte(Territoire_SK);
CREATE INDEX IX_FI_Reseau  ON dbo.Fact_Intervention_Reseau(Reseau_SK);
CREATE INDEX IX_FI_Interv  ON dbo.Fact_Intervention_Reseau(Intervention_SK);
CREATE INDEX IX_FCD_Terr   ON dbo.Fact_Climat_Demo(Territoire_SK);
CREATE INDEX IX_DT_Annee   ON dbo.Dim_Temps(Annee, Mois);
GO

/* ---------- MEMBRES "INCONNU" (-1 gere via lookup en erreur => ligne par defaut) ---------- */
SET IDENTITY_INSERT dbo.Dim_Territoire ON;
INSERT dbo.Dim_Territoire(Territoire_SK,Code_Gouvernorat,Gouvernorat,Zone) VALUES(0,'NA','Non renseigne','Non renseigne');
SET IDENTITY_INSERT dbo.Dim_Territoire OFF;
GO

/* ---------- GENERATION DE Dim_Temps (2007 -> 2026, grain mensuel) ---------- */
;WITH n AS (SELECT TOP (240) ROW_NUMBER() OVER(ORDER BY (SELECT NULL))-1 AS i FROM sys.all_objects),
d AS (SELECT DATEADD(MONTH,i,'2007-01-01') AS dt FROM n)
INSERT dbo.Dim_Temps(Date_Key,Date_Complete,Annee,Semestre,Trimestre,Mois,Nom_Mois,Saison,Est_Ete)
SELECT CONVERT(INT,FORMAT(dt,'yyyyMMdd')), dt, YEAR(dt),
       CASE WHEN MONTH(dt)<=6 THEN 1 ELSE 2 END, DATEPART(QUARTER,dt), MONTH(dt),
       DATENAME(MONTH,dt),
       CASE WHEN MONTH(dt) IN (12,1,2) THEN 'Hiver' WHEN MONTH(dt) IN (3,4,5) THEN 'Printemps'
            WHEN MONTH(dt) IN (6,7,8) THEN 'Ete' ELSE 'Automne' END,
       CASE WHEN MONTH(dt) BETWEEN 6 AND 9 THEN 1 ELSE 0 END
FROM d;
-- Convention : donnees annuelles rattachees au mois de janvier (Date_Key = yyyy0101).
GO

/* =====================================================================
   4. REQUETES DE RECONCILIATION  Staging -> DW (Phase 6)
   ===================================================================== */
-- Exemple : consommation par secteur
SELECT 'Staging' AS Couche, COUNT(*) AS Nb_Lignes,
       SUM(TRY_CONVERT(DECIMAL(18,3), REPLACE(Volume_1000m3,',','.'))) AS Somme_Volume
FROM SA_SONEDE.dbo.Stg_Conso_Usage_Region
UNION ALL
SELECT 'DW', COUNT(*), SUM(Volume_Facture_1000m3) FROM SONEDE_DW.dbo.Fact_Consommation;

SELECT 'Staging' AS Couche, COUNT(*) AS Nb_Lignes, SUM(TRY_CONVERT(DECIMAL(18,3),REPLACE(Reserve_Mm3,',','.'))) AS Somme_Reserve
FROM SA_SONEDE.dbo.Stg_Barrages
UNION ALL
SELECT 'DW', COUNT(*), SUM(Reserve_Mm3) FROM SONEDE_DW.dbo.Fact_Barrage;

SELECT 'Staging' AS Couche, COUNT(*) AS Nb_Lignes, SUM(TRY_CONVERT(INT,Nb_Casses)) AS Total
FROM SA_SONEDE.dbo.Stg_Casses
UNION ALL
SELECT 'DW', COUNT(*), SUM(Nb_Interventions) FROM SONEDE_DW.dbo.Fact_Intervention_Reseau fi
JOIN SONEDE_DW.dbo.Dim_Type_Intervention di ON di.Intervention_SK=fi.Intervention_SK AND di.Nature='Casse';

-- Controle d'orphelins (doit retourner 0)
SELECT COUNT(*) AS Orphelins_Conso
FROM SONEDE_DW.dbo.Fact_Consommation f
LEFT JOIN SONEDE_DW.dbo.Dim_Territoire t ON t.Territoire_SK=f.Territoire_SK
WHERE t.Territoire_SK IS NULL;

-- Journal ETL
SELECT * FROM SA_SONEDE.dbo.Log_ETL_Execution ORDER BY LogID DESC;