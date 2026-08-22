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
        FGestionnaire.Free;
        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);
      end;

    procedure TTestGestionnaireCapacites.EcrireFichierTemp(const AContenu : string);
      begin
        TFile.WriteAllText(FCheminTemp, AContenu);
      end;

    procedure TTestGestionnaireCapacites.ChargerDepuisFichier_DomaineInconnu_LeveECapacitesInvalidesException;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe","Domaine":"Inexistant","Description":"..."}]}');
        Assert.WillRaise(
          procedure
            begin
              FGestionnaire.ChargerDepuisFichier(FCheminTemp);
            end,
          ECapacitesInvalidesException);
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_InvestigateurConnu_RetourneTrueEtLaDescription;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe","Domaine":"Enquete","Description":"Pioche une carte de plus"}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsTrue(FGestionnaire.TryObtenirCapacite('Amanda Sharpe', Capacite));
        Assert.AreEqual('Pioche une carte de plus', Capacite.Description);
        Assert.AreEqual(Ord(dcEnquete), Ord(Capacite.Domaine));
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_RechercheInsensibleALaCasse_RetourneTrue;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe","Domaine":"Enquete","Description":"..."}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsTrue(FGestionnaire.TryObtenirCapacite('AMANDA SHARPE', Capacite));
      end;

    procedure TTestGestionnaireCapacites.TryObtenirCapacite_InvestigateurInconnu_RetourneFalse;
      var
        Capacite: TCapaciteInvestigateur;
      begin
        EcrireFichierTemp(
          '{"Capacites":[{"NomInvestigateur":"Amanda Sharpe","Domaine":"Enquete","Description":"..."}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.IsFalse(FGestionnaire.TryObtenirCapacite('Harvey Walters', Capacite));
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestGestionnaireCapacites);

end.
