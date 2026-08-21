unit AH.Tests.Contexte;

  interface

    uses
      DUnitX.TestFramework,
      AH.Core.Contexte;

    type

      [TestFixture]
      TTestContextePartie = class
        private
          function Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;
        public
          [Test]
          procedure Create_AvecZeroJoueurHumain_LeveEArgumentOutOfRangeException;

          [Test]
          procedure Create_AvecSeptJoueursHumains_LeveEArgumentOutOfRangeException;

          [Test]
          procedure Create_AvecSeptInvestigateurs_LeveEArgumentOutOfRangeException;

          [Test]
          procedure Create_AvecIndexJoueurHumainInvalide_LeveEArgumentOutOfRangeException;

          [Test]
          [TestCase('4 investigateurs', '4,7,7')]
          [TestCase('6 investigateurs', '6,6,9')]
          [TestCase('1 investigateur', '1,8,4')]
          procedure SeuilsDependantDuNombreDInvestigateurs_RespectentLesTablesDuLivret(
            ANombreInvestigateurs, ASeuilPortailsAttendu, ALimiteMonstresAttendue : Integer);

          [Test]
          procedure UnJoueurHumainControlantPlusieursInvestigateurs_LesSeuilsSuiventLesInvestigateursPasLesHumains;

          [Test]
          procedure PasserAlInvestigateurSuivant_SurDernierInvestigateur_ReboucleSurLePremier;

          [Test]
          procedure NomJoueurHumainCourant_RefleteLeControleurDeLInvestigateurCourant;

          [Test]
          procedure EchelleDestinPleine_AvantMax_RetourneFalse;

          [Test]
          procedure EchelleDestinPleine_AMax_RetourneTrue;
      end;

  implementation

    uses
      System.SysUtils;

    function TTestContextePartie.Investigateur(const ANom : string; AIndexJoueur : Integer) : TInvestigateurJoue;
      begin
        Result.NomInvestigateur := ANom;
        Result.IndexJoueurHumain := AIndexJoueur;
      end;

    procedure TTestContextePartie.Create_AvecZeroJoueurHumain_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create([], [Investigateur('Amanda', 0)]).Free;
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.Create_AvecSeptJoueursHumains_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create(['A', 'B', 'C', 'D', 'E', 'F', 'G'],
                                     [Investigateur('Amanda', 0)])
                             .Free;
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.Create_AvecSeptInvestigateurs_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create(['Alice'],
                                     [Investigateur('Inv1', 0), Investigateur('Inv2', 0), Investigateur('Inv3', 0),
                                     Investigateur('Inv4', 0), Investigateur('Inv5', 0), Investigateur('Inv6', 0),
                                     Investigateur('Inv7', 0)])
                             .Free;
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.Create_AvecIndexJoueurHumainInvalide_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create(['Alice'],
                                     [Investigateur('Amanda', 1)])
                             .Free; // Index 1 inexistant
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.SeuilsDependantDuNombreDInvestigateurs_RespectentLesTablesDuLivret(
                                    ANombreInvestigateurs, ASeuilPortailsAttendu, ALimiteMonstresAttendue : Integer);
      var
        Investigateurs : TArray<TInvestigateurJoue>;
        i : Integer;
        Contexte : TContextePartie;
      begin
        SetLength(Investigateurs, ANombreInvestigateurs);
        for i := 0 to ANombreInvestigateurs - 1 do
          Investigateurs[i] := Investigateur(Format('Inv%d', [i + 1]), 0);

        Contexte := TContextePartie.Create(['Alice'], Investigateurs);
        try
          Assert.AreEqual(ASeuilPortailsAttendu, Contexte.SeuilReveilPortailsOuverts);
          Assert.AreEqual(ALimiteMonstresAttendue, Contexte.LimiteMonstres);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.UnJoueurHumainControlantPlusieursInvestigateurs_LesSeuilsSuiventLesInvestigateursPasLesHumains;
      var
        Contexte : TContextePartie;
      begin
        // 2 joueurs humains, 4 investigateurs (Alice en contrôle 3, Bob 1) :
        // les seuils doivent correspondre à 4 investigateurs, pas à 2 joueurs humains.
        Contexte := TContextePartie.Create(['Alice', 'Bob'],
                                           [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Jenny', 0), Investigateur('Michael', 1)]);
        try
          Assert.AreEqual(2, Contexte.NombreJoueursHumains);
          Assert.AreEqual(4, Contexte.NombreInvestigateurs);
          Assert.AreEqual(7, Contexte.LimiteMonstres);              // 4 + 3
          Assert.AreEqual(7, Contexte.SeuilReveilPortailsOuverts);  // table 3-4 investigateurs
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.PasserAlInvestigateurSuivant_SurDernierInvestigateur_ReboucleSurLePremier;
      var
        Contexte : TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'],
                                           [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Jenny', 0)]);
        try
          Contexte.IndexInvestigateurCourant := 2; // Dernier investigateur (Jenny)
          Contexte.PasserAlInvestigateurSuivant;
          Assert.AreEqual('Amanda', Contexte.NomInvestigateurCourant);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.NomJoueurHumainCourant_RefleteLeControleurDeLInvestigateurCourant;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice', 'Bob'],
                                           [Investigateur('Amanda', 0), Investigateur('Michael', 1)]);
        try
          Contexte.IndexInvestigateurCourant := 1; // Michael, contrôlé par Bob
          Assert.AreEqual('Michael', Contexte.NomInvestigateurCourant);
          Assert.AreEqual('Bob', Contexte.NomJoueurHumainCourant);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.EchelleDestinPleine_AvantMax_RetourneFalse;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
        try
          Contexte.EchelleDestin := EchelleDestinTailleMax - 1;
          Assert.IsFalse(Contexte.EchelleDestinPleine);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.EchelleDestinPleine_AMax_RetourneTrue;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'], [Investigateur('Amanda', 0)]);
        try
          Contexte.EchelleDestin := EchelleDestinTailleMax;
          Assert.IsTrue(Contexte.EchelleDestinPleine);
        finally
          Contexte.Free;
        end;
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestContextePartie);

end.
