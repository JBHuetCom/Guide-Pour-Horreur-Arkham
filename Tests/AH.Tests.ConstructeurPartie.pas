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
      end;

  implementation

    uses
      System.Generics.Collections;

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

  initialization
    TDUnitX.RegisterTestFixture(TTestConstructeurPartie);

end.
