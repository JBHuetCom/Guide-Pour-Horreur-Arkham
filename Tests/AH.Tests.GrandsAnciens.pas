unit AH.Tests.GrandsAnciens;

  interface

    uses

      DUnitX.TestFramework,
      AH.Core.GrandsAnciens;

    type

      [TestFixture]
      TTestGestionnaireGrandsAnciens = class
        private
          FCheminTemp : string;
          FGestionnaire : TGestionnaireGrandsAnciens;
          procedure EcrireFichierTemp(const AContenu : string);
        public
          [Setup]
          procedure Setup;
          [TearDown]
          procedure TearDown;

          [Test]
          procedure ChargerDepuisFichier_SansNom_LeveEGrandsAnciensInvalidesException;

          [Test]
          procedure ChargerDepuisFichier_SansTableauRacine_LeveEGrandsAnciensInvalidesException;

          [Test]
          procedure TryObtenirGrandAncien_NomConnuCasseDifferente_RetourneTrueEtLesChamps;

          [Test]
          procedure TryObtenirGrandAncien_NomInconnu_RetourneFalse;

          [Test]
          procedure TryObtenirRegleEtape_EtapeDeclaree_RetourneTrueEtLeTexte;

          [Test]
          procedure TryObtenirRegleEtape_EtapeNonDeclaree_RetourneFalse;

          [Test]
          procedure TryObtenirRegleEtape_GrandAncienSansEtapes_RetourneFalse;

          [Test]
          procedure TryObtenirRegleEtape_GrandAncienInconnu_RetourneFalse;
      end;

  implementation

    uses

      System.SysUtils, System.IOUtils;

    procedure TTestGestionnaireGrandsAnciens.Setup;
      begin
        FCheminTemp := TPath.Combine(TPath.GetTempPath, 'ah_grands_anciens_test.json');
        FGestionnaire := TGestionnaireGrandsAnciens.Create;
      end;

    procedure TTestGestionnaireGrandsAnciens.TearDown;
      begin
        FGestionnaire.Free;
        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);
      end;

    procedure TTestGestionnaireGrandsAnciens.EcrireFichierTemp(const AContenu : string);
      begin
        TFile.WriteAllText(FCheminTemp, AContenu);
      end;

    procedure TTestGestionnaireGrandsAnciens.ChargerDepuisFichier_SansNom_LeveEGrandsAnciensInvalidesException;
      begin
        EcrireFichierTemp('{"GrandsAnciens":[{"TailleEchelleDestin":10}]}');
        Assert.WillRaise(
          procedure
            begin
              FGestionnaire.ChargerDepuisFichier(FCheminTemp);
            end,
          EGrandsAnciensInvalidesException);
      end;

    procedure TTestGestionnaireGrandsAnciens.ChargerDepuisFichier_SansTableauRacine_LeveEGrandsAnciensInvalidesException;
      begin
        EcrireFichierTemp('{"AutreChose":[]}');
        Assert.WillRaise(
          procedure
            begin
              FGestionnaire.ChargerDepuisFichier(FCheminTemp);
            end,
          EGrandsAnciensInvalidesException);
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirGrandAncien_NomConnuCasseDifferente_RetourneTrueEtLesChamps;
      var
        GrandAncien : TGrandAncien;
      begin
        EcrireFichierTemp(
          '{"GrandsAnciens":[{"Nom":"Yig","TailleEchelleDestin":10,' +
          '"Regles":{"EnSommeil":"...","Bataille":{"Combat":-3}}}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsTrue(FGestionnaire.TryObtenirGrandAncien('YIG', GrandAncien));
        Assert.AreEqual('Yig', GrandAncien.Nom);
        Assert.AreEqual(10, GrandAncien.TailleEchelleDestin);
        Assert.AreEqual(-3, GrandAncien.Bataille.Combat);
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirGrandAncien_NomInconnu_RetourneFalse;
      var
        GrandAncien : TGrandAncien;
      begin
        EcrireFichierTemp('{"GrandsAnciens":[{"Nom":"Yig","TailleEchelleDestin":10}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirGrandAncien('Cthulhu', GrandAncien));
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirRegleEtape_EtapeDeclaree_RetourneTrueEtLeTexte;
      var
        Texte : string;
      begin
        EcrireFichierTemp(
          '{"GrandsAnciens":[{"Nom":"Yig","TailleEchelleDestin":10,' +
          '"Regles":{"Etapes":{"bf04_capacites_debut_bataille":"Chaque Investigateur est Maudit."}}}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsTrue(FGestionnaire.TryObtenirRegleEtape('Yig', 'bf04_capacites_debut_bataille', Texte));
        Assert.AreEqual('Chaque Investigateur est Maudit.', Texte);
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirRegleEtape_EtapeNonDeclaree_RetourneFalse;
      var
        Texte : string;
      begin
        EcrireFichierTemp(
          '{"GrandsAnciens":[{"Nom":"Yig","TailleEchelleDestin":10,' +
          '"Regles":{"Etapes":{"bf04_capacites_debut_bataille":"..."}}}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirRegleEtape('Yig', 'phase5_evenement', Texte));
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirRegleEtape_GrandAncienSansEtapes_RetourneFalse;
      var
        Texte : string;
      begin
        EcrireFichierTemp('{"GrandsAnciens":[{"Nom":"Azatoth","TailleEchelleDestin":14}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirRegleEtape('Azatoth', 'bf04_capacites_debut_bataille', Texte));
      end;

    procedure TTestGestionnaireGrandsAnciens.TryObtenirRegleEtape_GrandAncienInconnu_RetourneFalse;
      var
        Texte : string;
      begin
        EcrireFichierTemp('{"GrandsAnciens":[{"Nom":"Yig","TailleEchelleDestin":10}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirRegleEtape('Cthulhu', 'bf04_capacites_debut_bataille', Texte));
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestGestionnaireGrandsAnciens);

end.
