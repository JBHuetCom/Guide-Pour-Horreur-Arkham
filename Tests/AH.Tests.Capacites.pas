unit AH.Tests.Capacites;

  interface

    uses
      DUnitX.TestFramework, AH.Core.Capacites;

    type

      [TestFixture]
      TTestGestionnaireCapacites = class
        private
          FCheminTemp : string;
          FGestionnaire : TGestionnaireCapacites;
          procedure EcrireFichierTemp(const AContenu : string);
        public
          [Setup]
          procedure Setup;
          [TearDown]
          procedure TearDown;

          [Test]
          procedure ChargerDepuisFichier_DomaineInconnu_LeveECapacitesInvalidesException;

          [Test]
          procedure TryObtenirCapacite_InvestigateurConnu_RetourneTrueEtLaDescription;

          [Test]
          procedure TryObtenirCapacite_RechercheInsensibleALaCasse_RetourneTrue;

          [Test]
          procedure TryObtenirCapacite_InvestigateurInconnu_RetourneFalse;

          [Test]
          procedure NomsConnus_DeuxCapacitesChargees_RetourneLesDeuxNomsDansLeurCasseDOrigine;

      end;

  implementation

    uses
      System.SysUtils, System.IOUtils;

    procedure TTestGestionnaireCapacites.Setup;
      begin
        FCheminTemp := TPath.Combine(TPath.GetTempPath, 'ah_capacites_test.json');
        FGestionnaire := TGestionnaireCapacites.Create;
      end;

    procedure TTestGestionnaireCapacites.TearDown;
      begin
        FreeAndNil(FGestionnaire);

        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);

        FCheminTemp := EmptyStr;
      end;

    procedure TTestGestionnaireCapacites.EcrireFichierTemp(const AContenu : string);
      begin
        TFile.WriteAllText(FCheminTemp, AContenu);
      end;

    procedure TTestGestionnaireCapacites.ChargerDepuisFichier_DomaineInconnu_LeveECapacitesInvalidesException;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe (l''étudiante)","Domaine":"Inexistant","Description":"..."}]}');
        try
          FGestionnaire.ChargerDepuisFichier(FCheminTemp);

          Assert.Fail(
            'ECapacitesInvalidesException était attendue pour un domaine inconnu.');
        except
          on E: ECapacitesInvalidesException do
            // L'exception attendue confirme que la validation du domaine est active.
          else
            raise;
        end;
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_InvestigateurConnu_RetourneTrueEtLaDescription;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe (l''étudiante)","Domaine":"Enquête","Description":"Pioche une carte de plus"}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsTrue(FGestionnaire.TryObtenirCapacite('Amanda Sharpe (l''étudiante)', Capacite));
        Assert.AreEqual('Pioche une carte de plus', Capacite.Description);
        Assert.AreEqual(Ord(dcEnquete), Ord(Capacite.Domaine));
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_RechercheInsensibleALaCasse_RetourneTrue;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe (l''étudiante)","Domaine":"Enquête","Description":"..."}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);
        FGestionnaire.TryObtenirCapacite('AMANDA SHARPE (L''ÉTUDIANTE)', Capacite);
        Assert.IsTrue(FGestionnaire.TryObtenirCapacite('AMANDA SHARPE (L''ÉTUDIANTE)', Capacite));
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_InvestigateurInconnu_RetourneFalse;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe (l''étudiante)","Domaine":"Enquête","Description":"..."}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirCapacite('Harvey Walters', Capacite));
      end;

    procedure TTestGestionnaireCapacites.NomsConnus_DeuxCapacitesChargees_RetourneLesDeuxNomsDansLeurCasseDOrigine;
      var
        Noms : TArray<string>;
      begin
        EcrireFichierTemp(
          '{"Capacites":[' +
          '{"NomInvestigateur":"Amanda Sharpe (l''étudiante)","Domaine":"Enquête","Description":"..."},' +
          '{"NomInvestigateur":"Dexter Drake (le magicien)","Domaine":"Magie","Description":"..."}' +
          ']}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Noms := FGestionnaire.NomsConnus;

        Assert.AreEqual(2, Length(Noms));
        Assert.IsTrue((Noms[0] = 'Amanda Sharpe (l''étudiante)') or (Noms[1] = 'Amanda Sharpe (l''étudiante)'));
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestGestionnaireCapacites);

end.
