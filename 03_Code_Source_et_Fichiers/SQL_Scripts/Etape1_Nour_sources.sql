/*
   PROJET SONEDE BI — PHASE 3, ETAPE 1
   Auteur : Nour

   Objectif :
   Adapter les tables de Staging aux 6 fichiers Excel
   de Nour, sans modifier le script commun.

   Base de données : SA_SONEDE
   */

USE SA_SONEDE;
GO
/* 
   1. STAGING - TARIFS VARIABLES DE L'EAU
   Fichier personnel de Nour
   */

IF OBJECT_ID(N'dbo.Stg_Nour_Tarif_Variable', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Nour_Tarif_Variable (
        Annee NVARCHAR(20),
        Tranche_Consommation NVARCHAR(100),
        Tarif_Millimes_M3 NVARCHAR(50),
        Source_File NVARCHAR(200),
        Load_Date DATETIME2 DEFAULT SYSDATETIME()
    );
END;
GO
/* 2. Staging des redevances fixes par trimestre */

IF OBJECT_ID(N'dbo.Stg_Nour_Redevances', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Nour_Redevances (
        Diametre_Compteur NVARCHAR(30),
        Redevance_Dinars NVARCHAR(30),
        Source_File NVARCHAR(200),
        Load_Date DATETIME2 DEFAULT SYSDATETIME()
    );
END;
GO
/* 3. Staging de la desserte en eau potable */

IF OBJECT_ID(N'dbo.Stg_Nour_Desserte', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Stg_Nour_Desserte (
        Annee NVARCHAR(20),
        Gouvernorat NVARCHAR(100),
        Type_Population NVARCHAR(100),
        Desserte_Milliers_Habitants NVARCHAR(50),
        Source_File NVARCHAR(200),
        Load_Date DATETIME2 DEFAULT SYSDATETIME()
    );
END;
GO
