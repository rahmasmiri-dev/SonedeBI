/* =====================================================================
   PHASE 3 - ÉTAPE 1 : partie de MELAK, adaptée au script du groupe
   Fichiers : nombre d'abonnés par usage 2007-2011, branchements 2020
   À exécuter APRÈS SONEDE_SQL_Scripts.sql (script du groupe).
   Auteur : Melak. Relançable : ne touche qu'aux tables de cette partie,
   sauf usp_Truncate_Staging et Stg_Ref_Gouvernorat (partagés, compatibles).
   ===================================================================== */
USE SA_SONEDE;
GO

/* ---------------------------------------------------------------------
   1. Stg_Abonnes adaptée aux fichiers réels : maille district SONEDE
      (le script du groupe prévoyait une colonne Region). Format long :
      une ligne par année x district x usage, produite par l'Unpivot SSIS.
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Stg_Abonnes', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.Stg_Abonnes', N'District') IS NULL
    DROP TABLE dbo.Stg_Abonnes;      -- ancienne version, vide
GO
IF OBJECT_ID(N'dbo.Stg_Abonnes', N'U') IS NULL
CREATE TABLE dbo.Stg_Abonnes (
    Annee       NVARCHAR(10),
    District    NVARCHAR(100),
    Usage_      NVARCHAR(100),
    Nb_Abonnes  NVARCHAR(30),
    Source_File NVARCHAR(200),
    Load_Date   DATETIME2 DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   2. Nouvelle table de staging : branchements 2020 (absente du script)
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Stg_Branchements', N'U') IS NULL
CREATE TABLE dbo.Stg_Branchements (
    Annee       NVARCHAR(10),
    District    NVARCHAR(100),
    Nb_Entrep   NVARCHAR(30),
    Nb_Sonede   NVARCHAR(30),
    Nb_Total    NVARCHAR(30),
    Source_File NVARCHAR(200),
    Load_Date   DATETIME2 DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   3. Référentiel des districts (préfixe Stg_Ref_ : jamais vidé)
      Nom_Brut = libellé normalisé par SSIS : UPPER(TRIM(REPLACE(x,"  "," ")))
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Stg_Ref_District', N'U') IS NULL
CREATE TABLE dbo.Stg_Ref_District (
    Nom_Brut        NVARCHAR(100) NOT NULL PRIMARY KEY,
    District_Std    NVARCHAR(100) NOT NULL,
    Gouvernorat_Std NVARCHAR(100) NOT NULL
);
GO

INSERT INTO dbo.Stg_Ref_District (Nom_Brut, District_Std, Gouvernorat_Std)
SELECT v.Nom_Brut, v.District_Std, v.Gouvernorat_Std
FROM (VALUES
    (N'ARIANA',              N'ARIANA',              N'Ariana'),
    (N'BARDO',               N'BARDO',               N'Tunis'),
    (N'BEJA',                N'BEJA',                N'Béja'),
    (N'BEN AROUS',           N'BEN AROUS',           N'Ben Arous'),
    (N'BIZERTE',             N'BIZERTE',             N'Bizerte'),
    (N'EL MANAR',            N'EL MANAR',            N'Tunis'),
    (N'EL OMRANE SUP',       N'EL OMRANE SUPERIEUR', N'Tunis'),
    (N'EL OMRANE SUPÉRIEUR', N'EL OMRANE SUPERIEUR', N'Tunis'),
    (N'EZZAHRA',             N'EZZAHRA',             N'Ben Arous'),
    (N'GABES',               N'GABES',               N'Gabès'),
    (N'GAFSA',               N'GAFSA',               N'Gafsa'),
    (N'GROMBALIA',           N'GROMBALIA',           N'Nabeul'),
    (N'H. SOUSSE',           N'HAMMAM SOUSSE',       N'Sousse'),
    (N'JENDOUBA',            N'JENDOUBA',            N'Jendouba'),
    (N'JERBA',               N'JERBA',               N'Médenine'),
    (N'KAIROUAN',            N'KAIROUAN',            N'Kairouan'),
    (N'KASSERINE',           N'KASSERINE',           N'Kasserine'),
    (N'KEBILI',              N'KEBILI',              N'Kébili'),
    (N'LA MARSA',            N'LA MARSA',            N'Tunis'),
    (N'LE KEF',              N'LE KEF',              N'Le Kef'),
    (N'M. BOURGUIBA',        N'MENZEL BOURGUIBA',    N'Bizerte'),
    (N'M. TEMIME',           N'MENZEL TEMIME',       N'Nabeul'),
    (N'MAHDIA',              N'MAHDIA',              N'Mahdia'),
    (N'MANOUBA',             N'MANOUBA',             N'La Manouba'),
    (N'MARSA',               N'LA MARSA',            N'Tunis'),
    (N'MEDENINE',            N'MEDENINE',            N'Médenine'),
    (N'MENZEL TEMIME',       N'MENZEL TEMIME',       N'Nabeul'),
    (N'ML BOURGUIBA',        N'MENZEL BOURGUIBA',    N'Bizerte'),
    (N'MOKNINE',             N'MOKNINE',             N'Monastir'),
    (N'MONASTIR',            N'MONASTIR',            N'Monastir'),
    (N'NABEUL',              N'NABEUL',              N'Nabeul'),
    (N'SFAX',                N'SFAX',                N'Sfax'),
    (N'SFAX NORD',           N'SFAX NORD',           N'Sfax'),
    (N'SFAX SUD',            N'SFAX SUD',            N'Sfax'),
    (N'SIDI BOUZID',         N'SIDI BOUZID',         N'Sidi Bouzid'),
    (N'SILIANA',             N'SILIANA',             N'Siliana'),
    (N'SOUSSE',              N'SOUSSE',              N'Sousse'),
    (N'TATAOUINE',           N'TATAOUINE',           N'Tataouine'),
    (N'TOZEUR',              N'TOZEUR',              N'Tozeur'),
    (N'TUNIS',               N'TUNIS',               N'Tunis'),
    (N'TUNIS SUD',           N'TUNIS SUD',           N'Tunis'),
    (N'ZAGHOUAN',            N'ZAGHOUAN',            N'Zaghouan')
) v(Nom_Brut, District_Std, Gouvernorat_Std)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Stg_Ref_District r WHERE r.Nom_Brut = v.Nom_Brut);
GO
-- TUNIS SUD -> Tunis : rattachement à confirmer.

/* ---------------------------------------------------------------------
   4. Les 24 gouvernorats dans le référentiel du groupe (si absents)
      Zone = 7 régions ; Code_ISO = norme ISO 3166-2:TN
   --------------------------------------------------------------------- */
INSERT INTO dbo.Stg_Ref_Gouvernorat (Nom_Brut, Gouvernorat_Std, Zone, Code_ISO)
SELECT v.Gouvernorat, v.Gouvernorat, v.Zone, v.Code_ISO
FROM (VALUES
    (N'Tunis',         N'Grand Tunis',    N'TN-11'),
    (N'Ariana',        N'Grand Tunis',    N'TN-12'),
    (N'Ben Arous',     N'Grand Tunis',    N'TN-13'),
    (N'La Manouba',    N'Grand Tunis',    N'TN-14'),
    (N'Nabeul',        N'Nord-Est',       N'TN-21'),
    (N'Zaghouan',      N'Nord-Est',       N'TN-22'),
    (N'Bizerte',       N'Nord-Est',       N'TN-23'),
    (N'Béja',          N'Nord-Ouest',     N'TN-31'),
    (N'Jendouba',      N'Nord-Ouest',     N'TN-32'),
    (N'Le Kef',        N'Nord-Ouest',     N'TN-33'),
    (N'Siliana',       N'Nord-Ouest',     N'TN-34'),
    (N'Kairouan',      N'Centre-Ouest',   N'TN-41'),
    (N'Kasserine',     N'Centre-Ouest',   N'TN-42'),
    (N'Sidi Bouzid',   N'Centre-Ouest',   N'TN-43'),
    (N'Sousse',        N'Centre-Est',     N'TN-51'),
    (N'Monastir',      N'Centre-Est',     N'TN-52'),
    (N'Mahdia',        N'Centre-Est',     N'TN-53'),
    (N'Sfax',          N'Centre-Est',     N'TN-61'),
    (N'Gafsa',         N'Sud-Ouest',      N'TN-71'),
    (N'Tozeur',        N'Sud-Ouest',      N'TN-72'),
    (N'Kébili',        N'Sud-Ouest',      N'TN-73'),
    (N'Gabès',         N'Sud-Est',        N'TN-81'),
    (N'Médenine',      N'Sud-Est',        N'TN-82'),
    (N'Tataouine',     N'Sud-Est',        N'TN-83')
) v(Gouvernorat, Zone, Code_ISO)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Stg_Ref_Gouvernorat r
                  WHERE r.Gouvernorat_Std = v.Gouvernorat);
GO

/* ---------------------------------------------------------------------
   5. Vidage du staging : même effet que la version du groupe (toutes les
      tables Stg_ sauf les référentiels Stg_Ref_), mais les nouvelles
      tables comme Stg_Branchements sont prises en compte automatiquement.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Truncate_Staging AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX) = N'';
    SELECT @sql += N'TRUNCATE TABLE dbo.' + QUOTENAME(name) + N';'
    FROM sys.tables
    WHERE schema_id = SCHEMA_ID(N'dbo')
      AND name LIKE N'Stg[_]%'
      AND name NOT LIKE N'Stg[_]Ref[_]%';
    EXEC sys.sp_executesql @sql;
END;
GO

/* ---------------------------------------------------------------------
   6. Vérification : résultat attendu 1 / 1 / 42 / 38 / 24
   --------------------------------------------------------------------- */
SELECT
    CASE WHEN COL_LENGTH(N'dbo.Stg_Abonnes', N'District') IS NOT NULL
         THEN 1 ELSE 0 END                                       AS stg_abonnes_ok,
    CASE WHEN OBJECT_ID(N'dbo.Stg_Branchements', N'U') IS NOT NULL
         THEN 1 ELSE 0 END                                       AS stg_branchements_ok,
    (SELECT COUNT(*) FROM dbo.Stg_Ref_District)                  AS libelles_42,
    (SELECT COUNT(DISTINCT District_Std) FROM dbo.Stg_Ref_District) AS districts_38,
    (SELECT COUNT(DISTINCT Gouvernorat_Std) FROM dbo.Stg_Ref_Gouvernorat) AS gouvernorats_24;
GO
