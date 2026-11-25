/* ============================================================================
   Etape1_Fasralii_nappes_gda_branchements.sql
   Projet DS1 SONEDE BI - script personnel de Fasralii (relancable)
   A executer APRES SONEDE_SQL_Scripts.sql, sur la base SA_SONEDE.

   Convention du groupe : tables Stg_ tout en NVARCHAR, aucune contrainte,
   plus Source_File et Load_Date. Typage et nettoyage au chargement du DW.
   usp_Truncate_Staging vide automatiquement toute table Stg_ (hors Stg_Ref_).

   Fichiers deja couverts par une table existante (rien a creer) :
     - evolution-du-volume-produit...xlsx -> Stg_Production
         Annee <- Annee ; Source_Eau <- Source ;
         Volume <- Volume_produit_million_m3 ; Unite <- 'million m3' (constante)

   Tables creees ici (5) :
     - Stg_Exploitation_Souterraine  <- exploitation-totale...souterraines-mm3.xlsx
     - Stg_GDA_AEP                   <- gda-eau-potable-2018.xlsx
     - Stg_Nappe_Profonde            <- nappe-profonde.xlsx
     - Stg_Nappe_Superficielle       <- nappe-superficielle.xlsx
     - Stg_Branchements              <- nombre_branchement-_2020.xls
   ============================================================================ */
USE SA_SONEDE;
GO

IF OBJECT_ID('dbo.Stg_Exploitation_Souterraine', 'U') IS NULL
CREATE TABLE dbo.Stg_Exploitation_Souterraine (
    Annee                       NVARCHAR(255),
    Exploitation_Profonde_Mm3   NVARCHAR(255),
    Exploitation_Phreatique_Mm3 NVARCHAR(255),
    Total_Mm3                   NVARCHAR(255),
    Source_File                 NVARCHAR(200),
    Load_Date                   DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID('dbo.Stg_GDA_AEP', 'U') IS NULL
CREATE TABLE dbo.Stg_GDA_AEP (
    Annee                       NVARCHAR(255),   -- constante 2018 (colonne ajoutee par le package)
    Gouvernorat                 NVARCHAR(255),   -- libelle arabe brut
    Collectif                   NVARCHAR(255),   -- nom arabe brut du collectif
    Nb_Familles                 NVARCHAR(255),
    Nb_Connexions_Individuelles NVARCHAR(255),
    Nb_Institutions_Publiques   NVARCHAR(255),
    Nb_Systemes_Arretes         NVARCHAR(255),
    Source_File                 NVARCHAR(200),
    Load_Date                   DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID('dbo.Stg_Nappe_Profonde', 'U') IS NULL
CREATE TABLE dbo.Stg_Nappe_Profonde (
    Annee            NVARCHAR(255),
    Gouvernorat      NVARCHAR(255),              -- 'Nabeul' (colonne ajoutee par le package)
    Delegation       NVARCHAR(255),
    Nb_Puits         NVARCHAR(255),
    Ressources_Mm3   NVARCHAR(255),
    Exploitation_Mm3 NVARCHAR(255),
    Source_File      NVARCHAR(200),
    Load_Date        DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID('dbo.Stg_Nappe_Superficielle', 'U') IS NULL
CREATE TABLE dbo.Stg_Nappe_Superficielle (
    Annee               NVARCHAR(255),
    Gouvernorat         NVARCHAR(255),           -- 'Bizerte' (colonne ajoutee par le package)
    Nom_Nappe_Brut      NVARCHAR(255),           -- nom arabe avec le code colle
    Delegation          NVARCHAR(255),
    Puits_Electricite   NVARCHAR(255),
    Puits_Gazoil        NVARCHAR(255),
    Puits_Equipes_Total NVARCHAR(255),
    Puits_Non_Equipes   NVARCHAR(255),
    Puits_Total         NVARCHAR(255),
    Ressources_Mm3      NVARCHAR(255),
    Exploitation_Mm3    NVARCHAR(255),
    Salinite_Brut       NVARCHAR(255),           -- texte brut : '1 - 3', '7-0,5'...
    Source_File         NVARCHAR(200),
    Load_Date           DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID('dbo.Stg_Branchements', 'U') IS NULL
CREATE TABLE dbo.Stg_Branchements (
    Annee       NVARCHAR(255),                   -- constante 2020 (colonne ajoutee par le package)
    District    NVARCHAR(255),                   -- 1re colonne du fichier, sans en-tete
    Nb_Entrep   NVARCHAR(255),
    Nb_Sonede   NVARCHAR(255),
    Nb_Total    NVARCHAR(255),
    Source_File NVARCHAR(200),
    Load_Date   DATETIME2 DEFAULT SYSDATETIME()
);
GO

/* ---------------------------- Verification ---------------------------------
   Resultats attendus apres le script commun + ce script, sans autre script
   Etape1 : 21 / 5 / 14 / 9
   --------------------------------------------------------------------------- */
SELECT 'SA_SONEDE : tables' AS Controle, COUNT(*) AS Resultat
FROM SA_SONEDE.sys.tables
UNION ALL
SELECT 'Tables de Fasralii (attendu 5)', COUNT(*)
FROM SA_SONEDE.sys.tables
WHERE name IN ('Stg_Exploitation_Souterraine','Stg_GDA_AEP','Stg_Nappe_Profonde',
               'Stg_Nappe_Superficielle','Stg_Branchements')
UNION ALL
SELECT 'Colonnes Stg_Nappe_Superficielle (attendu 14)', COUNT(*)
FROM SA_SONEDE.sys.columns WHERE object_id = OBJECT_ID('dbo.Stg_Nappe_Superficielle')
UNION ALL
SELECT 'Colonnes Stg_GDA_AEP (attendu 9)', COUNT(*)
FROM SA_SONEDE.sys.columns WHERE object_id = OBJECT_ID('dbo.Stg_GDA_AEP');
GO