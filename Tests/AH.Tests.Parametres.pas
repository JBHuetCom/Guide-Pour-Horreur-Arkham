unit AH.Tests.Parametres;

  interface

    uses
      DUnitX.TestFramework, AH.Core.Parametres;

    type

      [TestFixture]
      TTestParametresApplication = class
      private
        FCheminTemp : string;
      public
        [Setup]
        procedure Setup;
        [TearDown]
        procedure TearDown;

        [Test]
        procedure Create_ValeursParDefaut_AfficherConseilsEstVrai;

        [Test]
        procedure ChargerDepuisFichier_FichierInexistant_ConserveLesValeursParDefaut;

        [Test]
        procedure SauvegarderPuisCharger_RestitueLaValeurEcrite;
      end;

  implementation

    uses
      System.IOUtils, System.SysUtils;

    procedure TTestParametresApplication.Setup;
      begin
        FCheminTemp := TPath.Combine(TPath.GetTempPath, 'ah_parametres_test.json');
      end;

    procedure TTestParametresApplication.TearDown;
      begin
        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);

        FCheminTemp := EmptyStr;
      end;

    procedure TTestParametresApplication.Create_ValeursParDefaut_AfficherConseilsEstVrai;
      var
        Parametres : TParametresApplication;
      begin
        Parametres := TParametresApplication.Create;
        try
          Assert.IsTrue(Parametres.AfficherConseils);
        finally
          Parametres.Free;
        end;
      end;

    procedure TTestParametresApplication.ChargerDepuisFichier_FichierInexistant_ConserveLesValeursParDefaut;
      var
        Parametres : TParametresApplication;
      begin
        Parametres := TParametresApplication.Create;
        try
          Parametres.ChargerDepuisFichier('chemin_inexistant.json');
          Assert.IsTrue(Parametres.AfficherConseils);
        finally
          Parametres.Free;
        end;
      end;

    procedure TTestParametresApplication.SauvegarderPuisCharger_RestitueLaValeurEcrite;
      var
        Ecrivain, Lecteur : TParametresApplication;
      begin
        Ecrivain := TParametresApplication.Create;
        try
          Ecrivain.AfficherConseils := False;
          Ecrivain.SauvegarderDansFichier(FCheminTemp);
        finally
          Ecrivain.Free;
        end;

        Lecteur := TParametresApplication.Create;
        try
          Lecteur.ChargerDepuisFichier(FCheminTemp);
          Assert.IsFalse(Lecteur.AfficherConseils);
        finally
          Lecteur.Free;
        end;
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestParametresApplication);

end.
