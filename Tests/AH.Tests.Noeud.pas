unit AH.Tests.Noeud;

    interface

    uses

      DUnitX.TestFramework,
      AH.Core.Noeud, AH.Core.Types;

    type

      [TestFixture]
      TTestNoeudEtape = class
        public
          [Test]
          procedure AjouterEnfant_SurNtInstruction_LeveEInvalidOpException;

          [Test]
          procedure AjouterEnfant_AvecNil_LeveEArgumentNilException;

          [Test]
          procedure AjouterEnfant_SurNtSequence_AjouteCorrectement;

          [Test]
          procedure AjouterBranche_SurNtInstruction_LeveEInvalidOpException;

          [Test]
          procedure AjouterBranche_SurNtChoix_ExposeValeurDeclenchanteLibelleEtNoeud;

          [Test]
          procedure Destroy_NoeudAvecPlusieursBranches_NePlanteEtNeFuitePas;

          [Test]
          procedure TBrancheEtape_SeuleReferenceHorsPortee_LibereLeNoeudPossede;

          [Test]
          procedure Clone_CopieTousLesChampsScalaires;

          [Test]
          procedure Clone_ProduitUneCopieIndependanteDesEnfants;

          [Test]
          procedure Clone_ProduitUneCopieIndependanteDesBranches;
      end;

  implementation

    uses

      System.SysUtils;

    { TTestNoeudEtape }

    procedure TTestNoeudEtape.AjouterEnfant_SurNtInstruction_LeveEInvalidOpException;
      var
        Parent, Enfant : TNoeudEtape;
      begin
        Parent := TNoeudEtape.Create('parent', ntInstruction);
        Enfant := TNoeudEtape.Create('enfant', ntInstruction);
        try
          Assert.WillRaise(
            procedure begin Parent.AjouterEnfant(Enfant); end,
            EInvalidOpException);
        finally
          Enfant.Free; // AjouterEnfant a levé avant toute prise de possession : à l'appelant de libérer.
          Parent.Free;
        end;
      end;

    procedure TTestNoeudEtape.AjouterEnfant_AvecNil_LeveEArgumentNilException;
      var
        Parent : TNoeudEtape;
      begin
        Parent := TNoeudEtape.Create('parent', ntSequence);
        try
          Assert.WillRaise(
            procedure begin Parent.AjouterEnfant(nil); end,
            EArgumentNilException);
        finally
          Parent.Free;
        end;
      end;

    procedure TTestNoeudEtape.AjouterEnfant_SurNtSequence_AjouteCorrectement;
      var
        Parent, Enfant : TNoeudEtape;
      begin
        Parent := TNoeudEtape.Create('parent', ntSequence);
        Enfant := TNoeudEtape.Create('enfant', ntInstruction);
        Parent.AjouterEnfant(Enfant); // Parent devient propriétaire de Enfant, libéré via Parent.Free.

        Assert.AreEqual(1, Parent.Enfants.Count);
        Assert.AreEqual('enfant', Parent.Enfants[0].Id);

        Parent.Free;
      end;

    procedure TTestNoeudEtape.AjouterBranche_SurNtInstruction_LeveEInvalidOpException;
      var
        Parent, Cible : TNoeudEtape;
      begin
        Parent := TNoeudEtape.Create('parent', ntInstruction);
        Cible := TNoeudEtape.Create('cible', ntInstruction);
        try
          Assert.WillRaise(
            procedure begin Parent.AjouterBranche('v', 'L', Cible); end,
            EInvalidOpException);
        finally
          // D'après la doc de AjouterBranche, en cas d'exception la méthode garantit elle-même la
          // libération de Cible : ne pas la libérer une seconde fois ici sous peine de double libération.
          Parent.Free;
        end;
      end;

    procedure TTestNoeudEtape.AjouterBranche_SurNtChoix_ExposeValeurDeclenchanteLibelleEtNoeud;
      var
        Parent, Cible : TNoeudEtape;
      begin
        Parent := TNoeudEtape.Create('parent', ntChoix);
        Cible := TNoeudEtape.Create('cible', ntInstruction);
        Parent.AjouterBranche('oui', 'Oui', Cible);

        Assert.AreEqual(1, Parent.Branches.Count);
        Assert.AreEqual('oui', string(Parent.Branches[0].ValeurDeclenchante));
        Assert.AreEqual('Oui', Parent.Branches[0].Libelle);
        Assert.AreEqual('cible', Parent.Branches[0].Noeud.Id);

        Parent.Free; // Libère aussi Cible, désormais possédé par la branche.
      end;

    procedure TTestNoeudEtape.Destroy_NoeudAvecPlusieursBranches_NePlanteEtNeFuitePas;
      var
        Racine, BrancheA, BrancheB : TNoeudEtape;
      begin
        // Ne vérifie pas de fuite par une assertion explicite (le test runner DUnitX+FastMM le fait
        // automatiquement à la fin du test) : si TNoeudEtape.Destroy ne finalise pas correctement
        // chaque TBrancheEtape de FBranches, ce test sera signalé en fuite mémoire.
        Racine := TNoeudEtape.Create('racine', ntChoix);
        BrancheA := TNoeudEtape.Create('a', ntInstruction);
        BrancheA.Texte := 'A';
        Racine.AjouterBranche('a', 'Option A', BrancheA);

        BrancheB := TNoeudEtape.Create('b', ntInstruction);
        BrancheB.Texte := 'B';
        Racine.AjouterBranche('b', 'Option B', BrancheB);

        Racine.Free;
        Assert.Pass;
      end;

    procedure TTestNoeudEtape.TBrancheEtape_SeuleReferenceHorsPortee_LibereLeNoeudPossede;
      var
        Noeud : TNoeudEtape;
        Branche : TBrancheEtape;
      begin
        // Même principe : la fuite éventuelle (si le nœud n'est jamais libéré faute de compte de
        // références correct) sera signalée par le test runner, pas par une assertion ici.
        Noeud := TNoeudEtape.Create('isole', ntInstruction);
        Branche := TBrancheEtape.Create('v', 'L', Noeud);

        Assert.AreEqual('isole', Branche.Noeud.Id);
      end;

    procedure TTestNoeudEtape.Clone_CopieTousLesChampsScalaires;
      var
        Original, Copie : TNoeudEtape;
      begin
        Original := TNoeudEtape.Create('original', ntSaisie);
        Original.Titre := 'Un titre';
        Original.Texte := 'Un texte';
        Original.TexteListe := ['Ligne 1', 'Ligne 2'];
        Original.Illustration := 'image.png';
        Original.ChampContexte := 'NiveauTerreur';
        Original.ValeurForcee := 3;
        Original.PossedeValeurForcee := True;

        Copie := Original.Clone;
        try
          Assert.AreEqual('original', Copie.Id);
          Assert.AreEqual('Un titre', Copie.Titre);
          Assert.AreEqual('Un texte', Copie.Texte);
          Assert.AreEqual(2, Length(Copie.TexteListe));
          Assert.AreEqual('Ligne 2', Copie.TexteListe[1]);
          Assert.AreEqual('image.png', Copie.Illustration);
          Assert.AreEqual('NiveauTerreur', Copie.ChampContexte);
          Assert.IsTrue(Copie.PossedeValeurForcee);
          Assert.AreEqual(3, Integer(Copie.ValeurForcee));
        finally
          Copie.Free;
          Original.Free;
        end;
      end;

    procedure TTestNoeudEtape.Clone_ProduitUneCopieIndependanteDesEnfants;
      var
        Original, Copie : TNoeudEtape;
      begin
        Original := TNoeudEtape.Create('racine', ntSequence);
        Original.AjouterEnfant(TNoeudEtape.Create('enfant', ntInstruction));

        Copie := Original.Clone;
        try
          // Un même Id d'enfant des deux côtés, mais ce ne doit pas être la même instance :
          // modifier l'un ne doit pas affecter l'autre.
          Copie.Enfants[0].Texte := 'Modifié dans la copie';

          Assert.AreNotEqual('Modifié dans la copie', Original.Enfants[0].Texte);
        finally
          Copie.Free;
          Original.Free;
        end;
      end;

    procedure TTestNoeudEtape.Clone_ProduitUneCopieIndependanteDesBranches;
      var
        Original, Copie : TNoeudEtape;
      begin
        Original := TNoeudEtape.Create('racine', ntChoix);
        Original.AjouterBranche('a', 'Option A', TNoeudEtape.Create('cible', ntInstruction));

        Copie := Original.Clone;
        try
          Copie.Branches[0].Noeud.Texte := 'Modifié dans la copie';

          Assert.AreNotEqual('Modifié dans la copie', Original.Branches[0].Noeud.Texte);
        finally
          Copie.Free;
          Original.Free;
        end;
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestNoeudEtape);

end.
