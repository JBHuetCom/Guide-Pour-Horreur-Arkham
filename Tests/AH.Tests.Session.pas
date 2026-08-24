unit AH.Tests.Session;

  interface

    uses

      DUnitX.TestFramework,
      AH.Core.Session, AH.Core.Contexte, AH.Core.Noeud, AH.Core.Moteur, AH.Core.Types;

    type

      [TestFixture]
      TTestGestionnaireSession = class
      private
        FCheminTemp: string;
        function Investigateur(const ANom: string; AIndexJoueur: Integer): TInvestigateurJoue;
        function ConstruireArbreMixte: TNoeudEtape;
      public
        [Setup]
        procedure Setup;
        [TearDown]
        procedure TearDown;

        [Test]
        procedure SauvegarderPuisCharger_ChampsScalaires_RestituesIdentiques;

        [Test]
        procedure SauvegarderPuisCharger_InvestigateursEtJoueurs_RestituesIdentiques;

        [Test]
        procedure SauvegarderPuisCharger_ReponsesMixtesTexteEtEntier_RestitueesIdentiques;

        [Test]
        procedure RecreerContexte_ProduitUnContextePartieAvecLesMemesValeurs;

        [Test]
        procedure RestaurerPosition_SurArbreMixte_RamèneAuMemeNoeudEtPermetDeContinuer;

        [Test]
        procedure Journal_Precedent_AnnuleLaDerniereReponseEtLeCompteur;

        [Test]
        procedure ChargerDepuisFichier_FichierInexistant_LeveEFileNotFoundException;
      end;

  implementation

    uses
      System.SysUtils, System.IOUtils, System.Variants;

    function TTestGestionnaireSession.Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;
      begin
        Result.NomInvestigateur := ANom;
        Result.IndexJoueurHumain := AIndexJoueur;
      end;

    function TTestGestionnaireSession.ConstruireArbreMixte : TNoeudEtape;
      var
        Racine, Etape1, Choix, BrancheOui, BrancheNon, Saisie, EtapeFinale : TNoeudEtape;
        Branche : TBrancheEtape;
      begin
        // racine (ntSequence) : Etape1 (ntInstruction) -> Choix (ntChoix: oui/non) -> Saisie (ntSaisie) -> EtapeFinale (ntInstruction)
        Racine := TNoeudEtape.Create('racine', ntSequence);

        Etape1 := TNoeudEtape.Create('etape1', ntInstruction);
        Etape1.Texte := 'Première étape';
        Racine.AjouterEnfant(Etape1);

        Choix := TNoeudEtape.Create('choix', ntChoix);
        BrancheOui := TNoeudEtape.Create('branche_oui', ntInstruction);
        BrancheOui.Texte := 'Branche oui';
        Branche.ValeurDeclenchante := 'oui';
        Branche.Noeud := BrancheOui;
        Choix.AjouterBranche(Branche);
        BrancheNon := TNoeudEtape.Create('branche_non', ntInstruction);
        BrancheNon.Texte := 'Branche non';
        Branche.ValeurDeclenchante := 'non';
        Branche.Noeud := BrancheNon;
        Choix.AjouterBranche(Branche);
        Racine.AjouterEnfant(Choix);

        Saisie := TNoeudEtape.Create('saisie', ntSaisie);
        Saisie.ChampContexte := 'NiveauTerreur';
        Saisie.Texte := 'Indiquez le niveau de Terreur';
        Racine.AjouterEnfant(Saisie);

        EtapeFinale := TNoeudEtape.Create('etape_finale', ntInstruction);
        EtapeFinale.Texte := 'Dernière étape';
        Racine.AjouterEnfant(EtapeFinale);

        Result := Racine;
      end;

    procedure TTestGestionnaireSession.Setup;
      begin
        FCheminTemp := TPath.Combine(TPath.GetTempPath, 'ah_session_test.json');
      end;

    procedure TTestGestionnaireSession.TearDown;
      begin
        if TFile.Exists(FCheminTemp) then
          TFile.Delete(FCheminTemp);
      end;

    procedure TTestGestionnaireSession.SauvegarderPuisCharger_ChampsScalaires_RestituesIdentiques;
      var
        Session, SessionRechargee : TSessionPartie;
      begin
        with Session do
          begin
            SetLength(ReponsesEnregistrees, 0);
            NomsJoueursHumains := ['Alice'];
            Investigateurs := [Investigateur('Amanda', 0)];
            NiveauTerreur := 4;
            NombrePortailsOuverts := 2;
            NombreSignesDesAnciens := 1;
            EchelleDestin := 6;
            TailleEchelleDestin := 10;
            TourCourant := 7;
            IndexInvestigateurCourant := 0;
            FichierContenuActif := 'tour';
            NombreEtapesTraversees := 3;
          end;

        TGestionnaireSession.SauvegarderDansFichier(Session, FCheminTemp);
        SessionRechargee := TGestionnaireSession.ChargerDepuisFichier(FCheminTemp);

        with SessionRechargee do
          begin
            Assert.AreEqual(4, NiveauTerreur);
            Assert.AreEqual(2, NombrePortailsOuverts);
            Assert.AreEqual(1, NombreSignesDesAnciens);
            Assert.AreEqual(6, EchelleDestin);
            Assert.AreEqual(10, TailleEchelleDestin);
            Assert.AreEqual(7, TourCourant);
            Assert.AreEqual('tour', FichierContenuActif);
            Assert.AreEqual(3, NombreEtapesTraversees);
          end;
      end;

    procedure TTestGestionnaireSession.SauvegarderPuisCharger_InvestigateursEtJoueurs_RestituesIdentiques;
      var
        Session, SessionRechargee : TSessionPartie;
      begin
        with Session do
          begin
            NomsJoueursHumains := ['Alice', 'Bob'];
            Investigateurs := [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Michael', 1)];
            FichierContenuActif := 'preparation';
          end;

        TGestionnaireSession.SauvegarderDansFichier(Session, FCheminTemp);
        SessionRechargee := TGestionnaireSession.ChargerDepuisFichier(FCheminTemp);

        with SessionRechargee do
          begin
            Assert.AreEqual(2, Length(NomsJoueursHumains));
            Assert.AreEqual('Bob', NomsJoueursHumains[1]);
            Assert.AreEqual(3, Length(Investigateurs));
            Assert.AreEqual('Michael', Investigateurs[2].NomInvestigateur);
            Assert.AreEqual(1, Investigateurs[2].IndexJoueurHumain);
          end;
      end;

    procedure TTestGestionnaireSession.SauvegarderPuisCharger_ReponsesMixtesTexteEtEntier_RestitueesIdentiques;
      var
        Session, SessionRechargee : TSessionPartie;
      begin
        SetLength(Session.ReponsesEnregistrees, 2);
        with Session do
          begin
            NomsJoueursHumains := ['Alice'];
            Investigateurs := [Investigateur('Amanda', 0)];
            FichierContenuActif := 'tour';
            NombreEtapesTraversees := 2;
            ReponsesEnregistrees[0] := 'oui';
            ReponsesEnregistrees[1] := 5;
          end;

        TGestionnaireSession.SauvegarderDansFichier(Session, FCheminTemp);
        SessionRechargee := TGestionnaireSession.ChargerDepuisFichier(FCheminTemp);

        with SessionRechargee do
          begin
            Assert.AreEqual(2, Length(ReponsesEnregistrees));
            Assert.AreEqual('oui', VarToStr(ReponsesEnregistrees[0]));
            Assert.AreEqual(5, Integer(ReponsesEnregistrees[1]));
          end;
      end;

    procedure TTestGestionnaireSession.RecreerContexte_ProduitUnContextePartieAvecLesMemesValeurs;
      var
        Session : TSessionPartie;
        Contexte : TContextePartie;
      begin
        with Session do
          begin
            NomsJoueursHumains := ['Alice'];
            Investigateurs := [Investigateur('Amanda', 0)];
            NiveauTerreur := 3;
            NombrePortailsOuverts := 1;
            TailleEchelleDestin := 10;
            EchelleDestin := 4;
            IndexInvestigateurCourant := 0;
          end;

        Contexte := TGestionnaireSession.RecreerContexte(Session);

        try
              Assert.AreEqual(3, Contexte.NiveauTerreur);
              Assert.AreEqual(1, Contexte.NombrePortailsOuverts);
              Assert.AreEqual(10, Contexte.TailleEchelleDestin);
              Assert.AreEqual(4, Contexte.EchelleDestin);
              Contexte.NomInvestigateurCourant;
              Assert.AreEqual('Amanda', Contexte.NomInvestigateurCourant);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestGestionnaireSession.RestaurerPosition_SurArbreMixte_RamèneAuMemeNoeudEtPermetDeContinuer;
      var
        Racine1, Racine2 : TNoeudEtape;
        Contexte1, Contexte2 : TContextePartie;
        MoteurBrut1, MoteurBrut2 : TMoteurSequenceur;
        Moteur1, Moteur2 : TMoteurSequenceurJournalise;
        Session : TSessionPartie;
        NoeudApresRestauration, Suite1, Suite2 : TNoeudEtape;
      begin
        // Partie "originale" : on avance jusqu'au nœud "saisie" (après avoir répondu au choix), puis on sauvegarde.
        Racine1 := ConstruireArbreMixte;
        Contexte1 := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
        MoteurBrut1 := TMoteurSequenceur.Create(Racine1, Contexte1);
        Moteur1 := TMoteurSequenceurJournalise.Create(MoteurBrut1);
        try
          Moteur1.Suivant; // etape1
          Moteur1.Suivant; // choix
          Moteur1.EnregistrerReponse('oui');
          Moteur1.Suivant; // branche_oui
          Moteur1.Suivant; // saisie (en attente de réponse)

          Assert.AreEqual('saisie', Moteur1.NoeudCourant.Id);

          Session := Moteur1.CapturerSession(Contexte1, 'test');
        finally
          Moteur1.Free;
          MoteurBrut1.Free;
          Contexte1.Free;
          Racine1.Free;
        end;

        // Reprise : arbre et contexte fraîchement recréés, comme après relance de l'application.
        Racine2 := ConstruireArbreMixte;
        Contexte2 := TGestionnaireSession.RecreerContexte(Session);
        MoteurBrut2 := TMoteurSequenceur.Create(Racine2, Contexte2);
        Moteur2 := TMoteurSequenceurJournalise.Create(MoteurBrut2);
        try
          TGestionnaireSession.RestaurerPosition(Moteur2, Session);
          NoeudApresRestauration := Moteur2.NoeudCourant;

          Assert.AreEqual('saisie', NoeudApresRestauration.Id);

          // La partie peut continuer normalement depuis la position restaurée.
          Moteur2.EnregistrerReponse(5);
          Suite1 := Moteur2.Suivant;
          Assert.AreEqual('etape_finale', Suite1.Id);
          Suite2 := Moteur2.Suivant;
          Assert.IsNull(Suite2);
        finally
          Moteur2.Free;
          MoteurBrut2.Free;
          Contexte2.Free;
          Racine2.Free;
        end;
      end;

    procedure TTestGestionnaireSession.Journal_Precedent_AnnuleLaDerniereReponseEtLeCompteur;
      var
        Racine : TNoeudEtape;
        Contexte : TContextePartie;
        MoteurBrut : TMoteurSequenceur;
        Moteur : TMoteurSequenceurJournalise;
        Session : TSessionPartie;
      begin
        Racine := ConstruireArbreMixte;
        Contexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
        MoteurBrut := TMoteurSequenceur.Create(Racine, Contexte);
        Moteur := TMoteurSequenceurJournalise.Create(MoteurBrut);
        try
          Moteur.Suivant; // etape1
          Moteur.Suivant; // choix
          Moteur.EnregistrerReponse('oui');
          Moteur.Suivant; // branche_oui

          Moteur.Precedent; // retour sur "choix", la réponse 'oui' doit être retirée du journal

          Session := Moteur.CapturerSession(Contexte, 'test');
          Assert.AreEqual(2, Session.NombreEtapesTraversees); // etape1, choix — plus branche_oui
          Assert.AreEqual(0, Length(Session.ReponsesEnregistrees));
        finally
          Moteur.Free;
          MoteurBrut.Free;
          Contexte.Free;
          Racine.Free;
        end;
      end;

    procedure TTestGestionnaireSession.ChargerDepuisFichier_FichierInexistant_LeveEFileNotFoundException;
      begin
        Assert.WillRaise(
          procedure begin TGestionnaireSession.ChargerDepuisFichier('chemin_inexistant.json'); end,
          EFileNotFoundException);
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestGestionnaireSession);

end.
