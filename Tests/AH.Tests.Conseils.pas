unit AH.Tests.Conseils;

  interface

    uses
      DUnitX.TestFramework,
      AH.Core.Conseils;

    type

      [TestFixture]
      TTestGestionnaireConseils = class
        private
          FCheminTemp: string;
          FGestionnaire: TGestionnaireConseils;
          procedure EcrireFichierTemp(const AContenu : string);
        public
          [Setup]
          procedure Setup;
          [TearDown]
          procedure TearDown;

          [Test]
          procedure ChargerDepuisFichier_FichierInexistant_LeveEFileNotFoundException;

          [Test]
          procedure ChargerDepuisFichier_JSONSansIdEtape_LeveEConseilsInvalidesException;

          [Test]
          procedure ConseilsPour_EtapeAvecDeuxConseils_LesRetourneDansLOrdreDuFichier;

          [Test]
          procedure ConseilsPour_EtapeInconnue_RetourneTableauVide;
      end;

  implementation

    uses
      System.SysUtils, System.IOUtils;

    procedure TTestGestionnaireConseils.Setup;
      begin
        FCheminTemp := TPath.Combine(TPath.GetTempPath, 'ah_conseils_test.json');
        FGestionnaire := TGestionnaireConseils.Create;
      end;

    procedure TTestGestionnaireConseils.TearDown;
      begin
        FGestionnaire.Free;
        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);
      end;

    procedure TTestGestionnaireConseils.EcrireFichierTemp(const AContenu: string);
      begin
        TFile.WriteAllText(FCheminTemp, AContenu);
      end;

    procedure TTestGestionnaireConseils.ChargerDepuisFichier_FichierInexistant_LeveEFileNotFoundException;
      begin
        Assert.WillRaise(
          procedure
            begin
              FGestionnaire.ChargerDepuisFichier('chemin_inexistant.json');
            end,
          EFileNotFoundException);
      end;

    procedure TTestGestionnaireConseils.ChargerDepuisFichier_JSONSansIdEtape_LeveEConseilsInvalidesException;
      begin
        EcrireFichierTemp('{"Conseils":[{"Texte":"Un conseil sans IdEtape"}]}');
        Assert.WillRaise(
          procedure
            begin
              FGestionnaire.ChargerDepuisFichier(FCheminTemp);
            end,
          EConseilsInvalidesException);
      end;

    procedure TTestGestionnaireConseils.ConseilsPour_EtapeAvecDeuxConseils_LesRetourneDansLOrdreDuFichier;
      var
        Resultat : TArray<TConseil>;
      begin
        EcrireFichierTemp(
          '{"Conseils":[' +
          '{"IdEtape":"etape1","Texte":"Premier conseil","Source":"Test"},' +
          '{"IdEtape":"etape1","Texte":"Second conseil","Source":"Test"}' +
          ']}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Resultat := FGestionnaire.ConseilsPour('etape1');

        Assert.AreEqual(2, Length(Resultat));
        Assert.AreEqual('Premier conseil', Resultat[0].Texte);
        Assert.AreEqual('Second conseil', Resultat[1].Texte);
      end;

    procedure TTestGestionnaireConseils.ConseilsPour_EtapeInconnue_RetourneTableauVide;
      begin
        EcrireFichierTemp('{"Conseils":[{"IdEtape":"etape1","Texte":"Un conseil"}]}');
        FGestionnaire.ChargerDepuisFichier(FCheminTemp);

        Assert.AreEqual(0, Length(FGestionnaire.ConseilsPour('etape_inconnue')));
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestGestionnaireConseils);

end.
