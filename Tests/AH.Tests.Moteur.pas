unit AH.Tests.Moteur;

  interface

    uses
      DUnitX.TestFramework,
      AH.Core.Moteur, AH.Core.Contexte, AH.Core.Noeud, AH.Core.Types;

    type

      [TestFixture]
      TTestMoteurSequenceur = class
      private
        FContexte : TContextePartie;
        FRacine : TNoeudEtape;
        FMoteur : TMoteurSequenceur;

        function Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;

        /// <summary>Construit une racine ntSequence à deux instructions, pour les cas simples.</summary>
        function ConstruireSequenceDeuxInstructions : TNoeudEtape;
      public
        [TearDown]
        procedure TearDown;

        [Test]
        procedure Suivant_AvecUnJoueurHumain_AvecUnInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
        [Test]
        procedure Suivant_AvecUnJoueurHumain_AvecDeuxInvestigateurs_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
        [Test]
        procedure Suivant_AvecDeuxJoueursHumains_AvecDeuxInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
        [Test]
        procedure Suivant_AvecDeuxJoueursHumains_AvecQuatreInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;

        [Test]
        procedure Suivant_ApresDerniereInstruction_RetourneNil;

        [Test]
        procedure Suivant_SurNtCondition_ResoutAutomatiquementSansExposerLeNoeudCondition;

        [Test]
        procedure Suivant_SurNtChoixSansReponse_LeveEInvalidOpException;

        [Test]
        procedure Suivant_SurNtChoixApresReponse_DescendDansLaBrancheChoisie;

        [Test]
        procedure Suivant_SurNtBouclePorInvestigateur_RepeteLesEnfantsParInvestigateurEtEnchaineLesInvestigateursDUnMemeJoueur;

        [Test]
        procedure Precedent_ApresUnSuivant_RestitueLeNoeudPrecedent;

        [Test]
        procedure Precedent_SansHistorique_RetourneNil;

        [Test]
        procedure EstDansBouclePorInvestigateur_DistingueEtapeGeneraleEtEtapeDansLaBoucle;

        [Test]
        procedure Suivant_SurNtSaisieAvecValeurForcee_AffecteLeChampSansExposerLeNoeud;

        [Test]
        procedure PeutReculer_AuDebutPuisApresUnSuivant_RefleteLHistorique;

        [Test]
        procedure Create_AvecRacineDeTypeNtChoix_NePasPlanterEtResoudreCorrectement;
      end;

  implementation

    uses
      System.SysUtils, System.Variants;

    function TTestMoteurSequenceur.Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;
      begin
        Result.NomInvestigateur := ANom;
        Result.IndexJoueurHumain := AIndexJoueur;
      end;

    function TTestMoteurSequenceur.ConstruireSequenceDeuxInstructions : TNoeudEtape;
      var
        Racine, Etape1, Etape2 : TNoeudEtape;
      begin
        Racine := TNoeudEtape.Create('racine', ntSequence);
        Etape1 := TNoeudEtape.Create('etape1', ntInstruction);
        Etape1.Texte := 'Première étape';
        Etape2 := TNoeudEtape.Create('etape2', ntInstruction);
        Etape2.Texte := 'Deuxième étape';
        Racine.AjouterEnfant(Etape1);
        Racine.AjouterEnfant(Etape2);
        Result := Racine;
      end;

    procedure TTestMoteurSequenceur.TearDown;
      begin
        FMoteur.Free;
        FRacine.Free;
        FContexte.Free;
      end;

    procedure TTestMoteurSequenceur.Suivant_AvecDeuxJoueursHumains_AvecDeuxInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
      var
        Premier, Second : TNoeudEtape;
      begin
        FContexte := TContextePartie.Create(['Alice', 'Bob'],
                                            [Investigateur('Amanda', 0), Investigateur('Michael', 1)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Premier := FMoteur.Suivant;
        Second := FMoteur.Suivant;

        Assert.AreEqual('etape1', Premier.Id);
        Assert.AreEqual('etape2', Second.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_AvecDeuxJoueursHumains_AvecQuatreInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
      var
        Premier, Second : TNoeudEtape;
      begin
        FContexte := TContextePartie.Create(['Alice', 'Bob'],
                                            [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Jenny', 0), Investigateur('Michael', 1)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Premier := FMoteur.Suivant;
        Second := FMoteur.Suivant;

        Assert.AreEqual('etape1', Premier.Id);
        Assert.AreEqual('etape2', Second.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_AvecUnJoueurHumain_AvecDeuxInvestigateurs_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
      var
        Premier, Second : TNoeudEtape;
      begin
        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0), Investigateur('Harvey', 0)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Premier := FMoteur.Suivant;
        Second := FMoteur.Suivant;

        Assert.AreEqual('etape1', Premier.Id);
        Assert.AreEqual('etape2', Second.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_AvecUnJoueurHumain_AvecUnInvestigateur_SurSequenceDeDeuxInstructions_LesRetourneDansLOrdre;
      var
        Premier, Second : TNoeudEtape;
      begin
        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Premier := FMoteur.Suivant;
        Second := FMoteur.Suivant;

        Assert.AreEqual('etape1', Premier.Id);
        Assert.AreEqual('etape2', Second.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_ApresDerniereInstruction_RetourneNil;
      begin
        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        FMoteur.Suivant; // etape1
        FMoteur.Suivant; // etape2
        Assert.IsNull(FMoteur.Suivant); // Arbre épuisé
      end;

    procedure TTestMoteurSequenceur.Suivant_SurNtCondition_ResoutAutomatiquementSansExposerLeNoeudCondition;
      var
        Racine, Condition, BrancheVraie, BrancheFausse : TNoeudEtape;
        Resultat : TNoeudEtape;
      begin
        Racine := TNoeudEtape.Create('racine', ntSequence);
        Condition := TNoeudEtape.Create('condition', ntCondition);
        Condition.ChampContexte := 'ArkhamEnvahie';

        BrancheVraie := TNoeudEtape.Create('envahie', ntInstruction);
        BrancheVraie.Texte := 'Arkham est envahie';

        Condition.AjouterBranche(True, EmptyStr, BrancheVraie);

        BrancheFausse := TNoeudEtape.Create('calme', ntInstruction);
        BrancheFausse.Texte := 'Arkham est calme';

        Condition.AjouterBranche(False, EmptyStr, BrancheFausse);

        Racine.AjouterEnfant(Condition);
        FRacine := Racine;

        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FContexte.NiveauTerreur := 10; // ArkhamEnvahie = True
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Resultat := FMoteur.Suivant;

        Assert.AreEqual('envahie', Resultat.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_SurNtChoixSansReponse_LeveEInvalidOpException;
      var
        Racine, Choix, Branche1 : TNoeudEtape;
      begin
        Racine := TNoeudEtape.Create('racine', ntSequence);
        Choix := TNoeudEtape.Create('choix', ntChoix);
        Branche1 := TNoeudEtape.Create('option1', ntInstruction);
        Branche1.Texte := 'Option 1';

        Choix.AjouterBranche('option1', 'Option 1', Branche1);

        Racine.AjouterEnfant(Choix);
        FRacine := Racine;

        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);
        FMoteur.Suivant; // Retourne le nœud "choix", en attente de réponse

        Assert.WillRaise(
          procedure
            begin
              FMoteur.Suivant;
            end,
          EInvalidOpException);
      end;

    procedure TTestMoteurSequenceur.Suivant_SurNtChoixApresReponse_DescendDansLaBrancheChoisie;
      var
        Racine, Choix, Branche1, Branche2 : TNoeudEtape;
        Resultat : TNoeudEtape;
      begin
        Racine := TNoeudEtape.Create('racine', ntSequence);
        Choix := TNoeudEtape.Create('choix', ntChoix);

        Branche1 := TNoeudEtape.Create('option1', ntInstruction);
        Branche1.Texte := 'Option 1';

        Choix.AjouterBranche('option1', 'Option 1', Branche1);

        Branche2 := TNoeudEtape.Create('option2', ntInstruction);
        Branche2.Texte := 'Option 2';

        Choix.AjouterBranche('option2', 'Option 2', Branche2);

        Racine.AjouterEnfant(Choix);
        FRacine := Racine;

        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        FMoteur.Suivant; // Retourne "choix"
        FMoteur.EnregistrerReponse('option2');
        Resultat := FMoteur.Suivant;

        Assert.AreEqual('option2', Resultat.Id);
      end;

    procedure TTestMoteurSequenceur.Suivant_SurNtBouclePorInvestigateur_RepeteLesEnfantsParInvestigateurEtEnchaineLesInvestigateursDUnMemeJoueur;
      var
        Racine, Boucle, Etape : TNoeudEtape;
      begin
        Racine := TNoeudEtape.Create('racine', ntSequence);
        Boucle := TNoeudEtape.Create('boucle', ntBouclePorInvestigateur);
        Etape := TNoeudEtape.Create('etape_investigateur', ntInstruction);
        Etape.Texte := 'Restaurez vos cartes déchargées';
        Boucle.AjouterEnfant(Etape);
        Racine.AjouterEnfant(Boucle);
        FRacine := Racine;

        // Alice contrôle Amanda ET Harvey (2 investigateurs), Bob contrôle Jenny (1 investigateur).
        // Ordre de jeu attendu : Amanda, Harvey (Alice), puis Jenny (Bob).
        FContexte := TContextePartie.Create(
          ['Alice', 'Bob'],
          [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Jenny', 1)]);
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        FMoteur.Suivant;
        Assert.AreEqual('Amanda', FContexte.NomInvestigateurCourant);
        Assert.AreEqual('Alice', FContexte.NomJoueurHumainCourant);

        FMoteur.Suivant;
        Assert.AreEqual('Harvey', FContexte.NomInvestigateurCourant);
        Assert.AreEqual('Alice', FContexte.NomJoueurHumainCourant);

        FMoteur.Suivant;
        Assert.AreEqual('Jenny', FContexte.NomInvestigateurCourant);
        Assert.AreEqual('Bob', FContexte.NomJoueurHumainCourant);

        Assert.IsNull(FMoteur.Suivant); // Boucle épuisée après le troisième investigateur
      end;

    procedure TTestMoteurSequenceur.Precedent_ApresUnSuivant_RestitueLeNoeudPrecedent;
      var
        Premier : TNoeudEtape;
      begin
        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Premier := FMoteur.Suivant;  // etape1
        FMoteur.Suivant;             // etape2

        Assert.AreEqual(Premier.Id, FMoteur.Precedent.Id);
      end;

    procedure TTestMoteurSequenceur.Precedent_SansHistorique_RetourneNil;
      begin
        FContexte := TContextePartie.Create(['Alice'],
                                            [Investigateur('Amanda', 0)]);
        FRacine := ConstruireSequenceDeuxInstructions;
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Assert.IsNull(FMoteur.Precedent);
      end;


      procedure TTestMoteurSequenceur.EstDansBouclePorInvestigateur_DistingueEtapeGeneraleEtEtapeDansLaBoucle;
        var
          Racine, HorsBoucle, Boucle, DansBoucle : TNoeudEtape;
        begin
          Racine := TNoeudEtape.Create('racine', ntSequence);
          HorsBoucle := TNoeudEtape.Create('hors_boucle', ntInstruction);
          HorsBoucle.Texte := 'Étape générale';
          Racine.AjouterEnfant(HorsBoucle);

          Boucle := TNoeudEtape.Create('boucle', ntBouclePorInvestigateur);
          DansBoucle := TNoeudEtape.Create('dans_boucle', ntInstruction);
          DansBoucle.Texte := 'Étape par investigateur';
          Boucle.AjouterEnfant(DansBoucle);
          Racine.AjouterEnfant(Boucle);
          FRacine := Racine;

          FContexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
          FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

          FMoteur.Suivant; // hors_boucle
          Assert.IsFalse(FMoteur.EstDansBouclePorInvestigateur);

          FMoteur.Suivant; // dans_boucle
          Assert.IsTrue(FMoteur.EstDansBouclePorInvestigateur);
        end;

      procedure TTestMoteurSequenceur.Suivant_SurNtSaisieAvecValeurForcee_AffecteLeChampSansExposerLeNoeud;
        var
          Racine, Saisie, EtapeSuivante : TNoeudEtape;
        begin
          Racine := TNoeudEtape.Create('racine', ntSequence);
          Saisie := TNoeudEtape.Create('saisie_forcee', ntSaisie);
          Saisie.ChampContexte := 'NiveauTerreur';
          Saisie.ValeurForcee := 3;
          Saisie.PossedeValeurForcee := True;
          Racine.AjouterEnfant(Saisie);

          EtapeSuivante := TNoeudEtape.Create('etape_suivante', ntInstruction);
          EtapeSuivante.Texte := 'Après';
          Racine.AjouterEnfant(EtapeSuivante);
          FRacine := Racine;

          FContexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
          FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

          Assert.AreEqual('etape_suivante', FMoteur.Suivant.Id); // saisie_forcee sauté, jamais affiché
          Assert.AreEqual(3, FContexte.NiveauTerreur);
        end;

      procedure TTestMoteurSequenceur.PeutReculer_AuDebutPuisApresUnSuivant_RefleteLHistorique;
        begin
          FContexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
          FRacine := ConstruireSequenceDeuxInstructions;
          FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

          Assert.IsFalse(FMoteur.PeutReculer);
          FMoteur.Suivant;
          Assert.IsTrue(FMoteur.PeutReculer);
        end;

    procedure TTestMoteurSequenceur.Create_AvecRacineDeTypeNtChoix_NePasPlanterEtResoudreCorrectement;
      var
        Racine, BrancheA : TNoeudEtape;
        Resultat : TNoeudEtape;
      begin
        // Reproduit fin_de_partie.json : une racine directement de type ntChoix (pas ntSequence),
        // ce qui provoquait une violation d'accès (Enfants est nil pour ntChoix).
        Racine := TNoeudEtape.Create('racine_choix', ntChoix);
        BrancheA := TNoeudEtape.Create('branche_a', ntInstruction);
        BrancheA.Texte := 'Option A';
        Racine.AjouterBranche('a', 'Option A', BrancheA);
        FRacine := Racine;

        FContexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
        FMoteur := TMoteurSequenceur.Create(FRacine, FContexte);

        Resultat := FMoteur.Suivant;
        Assert.AreEqual('racine_choix', Resultat.Id);

        FMoteur.EnregistrerReponse('a');
        Resultat := FMoteur.Suivant;
        Assert.AreEqual('branche_a', Resultat.Id);

        Assert.IsNull(FMoteur.Suivant);
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestMoteurSequenceur);

end.
