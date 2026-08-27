unit AH.Tests.ConstructeurPartie;

  interface

    uses

      DUnitX.TestFramework,
      AH.Core.ConstructeurPartie, AH.Core.Contexte;

    type

      [TestFixture]
      TTestConstructeurPartie = class
        private
          function Investigateur(const ANom: string; AIndexJoueur: Integer): TInvestigateurJoue;
        public
          [Test]
          procedure OrdonnerParJoueur_InvestigateursMelanges_RegroupesParJoueurDansLOrdreDeSaisie;

          [Test]
          procedure OrdonnerParJoueur_AucunInvestigateurPourUnJoueur_NeGenerePasDErreur;

          [Test]
          procedure SupprimerJoueurEtRepercuter_JoueurDuMilieu_RetireSesInvestigateursEtDecaleLesSuivants;

          [Test]
          procedure SupprimerJoueurEtRepercuter_AucunInvestigateurTouche_RetourneZero;

          [Test]
          procedure NomDejaUtilise_NomExistantCasseDifferente_RetourneTrue;

          [Test]
          procedure NomDejaUtilise_NomAbsent_RetourneFalse;

          [Test]
          procedure PlacerJoueurEnPremier_JoueurDuMilieu_ReordonneEtRepercuteSurLesInvestigateurs;

          [Test]
          procedure PlacerJoueurEnPremier_DejaPremier_NeChangeRien;

          [Test]
          procedure PlacerJoueurEnPremier_IndexHorsLimites_LeveEArgumentOutOfRangeException;
      end;

  implementation

    uses

      system.SysUtils, System.Generics.Collections;

    function TTestConstructeurPartie.Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;
      begin
        Result.NomInvestigateur := ANom;
        Result.IndexJoueurHumain := AIndexJoueur;
      end;

    procedure TTestConstructeurPartie.OrdonnerParJoueur_InvestigateursMelanges_RegroupesParJoueurDansLOrdreDeSaisie;
      var
        Investigateurs, Resultat: TArray<TInvestigateurJoue>;
      begin
        // Saisis dans un ordre "mélangé" : Michael (Bob) ajouté avant Harvey (Alice).
        Investigateurs := [
          Investigateur('Amanda', 0),
          Investigateur('Michael', 1),
          Investigateur('Harvey', 0)
        ];

        Resultat := TConstructeurPartie.OrdonnerParJoueur(['Alice', 'Bob'], Investigateurs);

        Assert.AreEqual(3, Length(Resultat));
        Assert.AreEqual('Amanda', Resultat[0].NomInvestigateur);
        Assert.AreEqual('Harvey', Resultat[1].NomInvestigateur);
        Assert.AreEqual('Michael', Resultat[2].NomInvestigateur);
      end;

    procedure TTestConstructeurPartie.OrdonnerParJoueur_AucunInvestigateurPourUnJoueur_NeGenerePasDErreur;
      var
        Resultat : TArray<TInvestigateurJoue>;
      begin
        Resultat := TConstructeurPartie.OrdonnerParJoueur(['Alice', 'Bob', 'Chloé'], [Investigateur('Amanda', 0)]);

        Assert.AreEqual(1, Length(Resultat));
        Assert.AreEqual('Amanda', Resultat[0].NomInvestigateur);
      end;

    procedure TTestConstructeurPartie.SupprimerJoueurEtRepercuter_JoueurDuMilieu_RetireSesInvestigateursEtDecaleLesSuivants;
      var
        Investigateurs : TList<TInvestigateurJoue>;
        NombreRetires : Integer;
      begin
        // Alice(0), Bob(1), Chloé(2) ; on retire Bob (index 1).
        Investigateurs := TList<TInvestigateurJoue>.Create;
        try
          Investigateurs.Add(Investigateur('Amanda', 0));   // Alice
          Investigateurs.Add(Investigateur('Michael', 1));  // Bob
          Investigateurs.Add(Investigateur('Jenny', 2));    // Chloé

          NombreRetires := TConstructeurPartie.SupprimerJoueurEtRepercuter(Investigateurs, 1);

          Assert.AreEqual(1, NombreRetires);
          Assert.AreEqual(2, Investigateurs.Count);
          Assert.AreEqual('Amanda', Investigateurs[0].NomInvestigateur);
          Assert.AreEqual(0, Investigateurs[0].IndexJoueurHumain);
          Assert.AreEqual('Jenny', Investigateurs[1].NomInvestigateur);
          Assert.AreEqual(1, Investigateurs[1].IndexJoueurHumain); // décalé de 2 vers 1
        finally
          Investigateurs.Free;
        end;
      end;

    procedure TTestConstructeurPartie.SupprimerJoueurEtRepercuter_AucunInvestigateurTouche_RetourneZero;
      var
        Investigateurs : TList<TInvestigateurJoue>;
      begin
        Investigateurs := TList<TInvestigateurJoue>.Create;
        try
          Investigateurs.Add(Investigateur('Amanda', 0));

          Assert.AreEqual(0, TConstructeurPartie.SupprimerJoueurEtRepercuter(Investigateurs, 1));
          Assert.AreEqual(1, Investigateurs.Count);
        finally
          Investigateurs.Free;
        end;
      end;

    procedure TTestConstructeurPartie.NomDejaUtilise_NomExistantCasseDifferente_RetourneTrue;
      begin
        Assert.IsTrue(TConstructeurPartie.NomDejaUtilise([Investigateur('Amanda Sharpe', 0)], 'AMANDA SHARPE'));
      end;

    procedure TTestConstructeurPartie.NomDejaUtilise_NomAbsent_RetourneFalse;
      begin
        Assert.IsFalse(TConstructeurPartie.NomDejaUtilise([Investigateur('Amanda Sharpe', 0)], 'Harvey Walters'));
      end;

    procedure TTestConstructeurPartie.PlacerJoueurEnPremier_JoueurDuMilieu_ReordonneEtRepercuteSurLesInvestigateurs;
      var
        Noms : TList<string>;
        Investigateurs : TList<TInvestigateurJoue>;
      begin
        // Alice(0), Bob(1), Chloé(2) ; Bob (index 1) devient premier.
        Noms := TList<string>.Create;
        Investigateurs := TList<TInvestigateurJoue>.Create;
        try
          Noms.AddRange(['Alice', 'Bob', 'Chloé']);
          Investigateurs.Add(Investigateur('Amanda', 0));   // Alice
          Investigateurs.Add(Investigateur('Michael', 1));  // Bob
          Investigateurs.Add(Investigateur('Jenny', 2));    // Chloé

          TConstructeurPartie.PlacerJoueurEnPremier(Noms, Investigateurs, 1);

          Assert.AreEqual('Bob', Noms[0]);
          Assert.AreEqual('Alice', Noms[1]);
          Assert.AreEqual('Chloé', Noms[2]);

          Assert.AreEqual(0, Investigateurs[1].IndexJoueurHumain); // Michael (Bob) → premier
          Assert.AreEqual(1, Investigateurs[0].IndexJoueurHumain); // Amanda (Alice) → deuxième
          Assert.AreEqual(2, Investigateurs[2].IndexJoueurHumain); // Jenny (Chloé) → inchangé
        finally
          Investigateurs.Free;
          Noms.Free;
        end;
      end;

    procedure TTestConstructeurPartie.PlacerJoueurEnPremier_DejaPremier_NeChangeRien;
      var
        Noms: TList<string>;
        Investigateurs: TList<TInvestigateurJoue>;
      begin
        Noms := TList<string>.Create;
        Investigateurs := TList<TInvestigateurJoue>.Create;
        try
          Noms.AddRange(['Alice', 'Bob']);
          Investigateurs.Add(Investigateur('Amanda', 0));

          TConstructeurPartie.PlacerJoueurEnPremier(Noms, Investigateurs, 0);

          Assert.AreEqual('Alice', Noms[0]);
          Assert.AreEqual(0, Investigateurs[0].IndexJoueurHumain);
        finally
          Investigateurs.Free;
          Noms.Free;
        end;
      end;

    procedure TTestConstructeurPartie.PlacerJoueurEnPremier_IndexHorsLimites_LeveEArgumentOutOfRangeException;
      var
        Noms: TList<string>;
        Investigateurs: TList<TInvestigateurJoue>;
      begin
        Noms := TList<string>.Create;
        Investigateurs := TList<TInvestigateurJoue>.Create;
        try
          Noms.Add('Alice');
          Assert.WillRaise(
            procedure
             begin
               TConstructeurPartie.PlacerJoueurEnPremier(Noms, Investigateurs, 5);
             end,
            EArgumentOutOfRangeException);
        finally
          Investigateurs.Free;
          Noms.Free;
        end;
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestConstructeurPartie);

end.
