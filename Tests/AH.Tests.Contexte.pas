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
          procedure Create_AvecNeufJoueursHumains_LeveEArgumentOutOfRangeException;

          [Test]
          procedure Create_AvecNeufInvestigateurs_LeveEArgumentOutOfRangeException;

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
          procedure EchelleDestinPleine_SansTailleRenseignee_LeveEInvalidOpException;

          [Test]
          procedure EchelleDestinPleine_AvantTaille_RetourneFalse;

          [Test]
          procedure EchelleDestinPleine_ATaille_RetourneTrue;

          [Test]
          procedure EchelleDestinPleine_TaillesDifferentesSelonGrandAncien_ChacuneRespectee;

          [Test]
          procedure AffecterChamp_TailleEchelleDestin_MetAJourLeChampCorrespondant;

          [Test]
          procedure PasserMarqueurPremierJoueur_DeuxJoueursDeuxInvestigateursChacun_PasseAuPremierInvestigateurDuJoueurSuivant;

          [Test]
          procedure PasserMarqueurPremierJoueur_DernierJoueur_ReboucleSurLePremier;

          [TestCase('4 investigateurs', '4,4')]
          [TestCase('8 investigateurs', '8,0')]
          [TestCase('1 investigateur', '1,7')]
          procedure LimitePeripherie_RespecteLaTableDuLivret(ANombreInvestigateurs, ALimiteAttendue: Integer);

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
              TContextePartie.Create([],
                                     [Investigateur('Amanda', 0)])
                             .Free;
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.Create_AvecNeufJoueursHumains_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create(['J1', 'J2', 'J3', 'J4', 'J5', 'J6', 'J7', 'J8', 'J9'],
                                     [Investigateur('Amanda', 0)])
                             .Free;
            end,
          EArgumentOutOfRangeException);
      end;

    procedure TTestContextePartie.Create_AvecNeufInvestigateurs_LeveEArgumentOutOfRangeException;
      begin
        Assert.WillRaise(
          procedure
            begin
              TContextePartie.Create(['Alice'],
                                     [Investigateur('Inv1', 0), Investigateur('Inv2', 0), Investigateur('Inv3', 0),
                                     Investigateur('Inv4', 0), Investigateur('Inv5', 0), Investigateur('Inv6', 0),
                                     Investigateur('Inv7', 0), Investigateur('Inv8', 0), Investigateur('Inv9', 0)])
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

    procedure TTestContextePartie.EchelleDestinPleine_SansTailleRenseignee_LeveEInvalidOpException;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'],
                                           [Investigateur('Amanda', 0)]);
        try
          Assert.WillRaise(
            procedure
              begin
                Contexte.EchelleDestinPleine;
              end,
            EInvalidOpException);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.EchelleDestinPleine_AvantTaille_RetourneFalse;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'],
                                           [Investigateur('Amanda', 0)]);
        try
          Contexte.TailleEchelleDestin := 10; // ex. Yig
          Contexte.EchelleDestin := 9;
          Assert.IsFalse(Contexte.EchelleDestinPleine);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.EchelleDestinPleine_ATaille_RetourneTrue;
      var
        Contexte: TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'],
                                           [Investigateur('Amanda', 0)]);
        try
          Contexte.TailleEchelleDestin := 10;
          Contexte.EchelleDestin := 10;
          Assert.IsTrue(Contexte.EchelleDestinPleine);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.EchelleDestinPleine_TaillesDifferentesSelonGrandAncien_ChacuneRespectee;
      var
        ContexteYig, ContexteAutre : TContextePartie;
      begin
        // Deux Grands Anciens différents doivent pouvoir avoir des tailles d'échelle différentes
        // dans deux parties distinctes — c'est précisément ce que corrige le passage d'une
        // constante globale à un champ d'instance.
        ContexteYig := TContextePartie.Create(['Alice'],
                                              [Investigateur('Amanda', 0)]);
        ContexteAutre := TContextePartie.Create(['Bob'],
                                                [Investigateur('Harvey', 0)]);
        try
          ContexteYig.TailleEchelleDestin := 10;
          ContexteYig.EchelleDestin := 10;

          ContexteAutre.TailleEchelleDestin := 15;
          ContexteAutre.EchelleDestin := 10;

          Assert.IsTrue(ContexteYig.EchelleDestinPleine);
          Assert.IsFalse(ContexteAutre.EchelleDestinPleine);
        finally
          ContexteYig.Free;
          ContexteAutre.Free;
        end;
      end;

    procedure TTestContextePartie.AffecterChamp_TailleEchelleDestin_MetAJourLeChampCorrespondant;
      var
        Contexte : TContextePartie;
      begin
        Contexte := TContextePartie.Create(['Alice'],
                                           [Investigateur('Amanda', 0)]);
        try
          Contexte.AffecterChamp('TailleEchelleDestin', 12);
          Assert.AreEqual(12, Contexte.TailleEchelleDestin);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.PasserMarqueurPremierJoueur_DeuxJoueursDeuxInvestigateursChacun_PasseAuPremierInvestigateurDuJoueurSuivant;
      var
        Contexte : TContextePartie;
      begin
        // Alice : Amanda(0), Harvey(0) ; Bob : Jenny(1), Kate(1). Premier joueur initial : Alice (index 0 par défaut).
        Contexte := TContextePartie.Create(
          ['Alice', 'Bob'],
          [Investigateur('Amanda', 0), Investigateur('Harvey', 0), Investigateur('Jenny', 1), Investigateur('Kate', 1)]);
        try
          Contexte.PasserMarqueurPremierJoueur;
          Contexte.RevenirAuPremierInvestigateur;

          Assert.AreEqual('Jenny', Contexte.NomInvestigateurCourant);
          Assert.AreEqual('Bob', Contexte.NomJoueurHumainCourant);
        finally
          Contexte.Free;
        end;
      end;

    procedure TTestContextePartie.PasserMarqueurPremierJoueur_DernierJoueur_ReboucleSurLePremier;
      var
        Contexte : TContextePartie;
      begin
        Contexte := TContextePartie.Create(
          ['Alice', 'Bob'],
          [Investigateur('Amanda', 0), Investigateur('Jenny', 1)]);
        try
          Contexte.PasserMarqueurPremierJoueur; // Alice -> Bob
          Contexte.PasserMarqueurPremierJoueur; // Bob -> Alice
          Contexte.RevenirAuPremierInvestigateur;

          Assert.AreEqual('Amanda', Contexte.NomInvestigateurCourant);
        finally
          Contexte.Free;
        end;
      end;

    [TestCase('4 investigateurs', '4,4')]
    [TestCase('8 investigateurs', '8,0')]
    [TestCase('1 investigateur', '1,7')]
    procedure TTestContextePartie.LimitePeripherie_RespecteLaTableDuLivret(ANombreInvestigateurs, ALimiteAttendue: Integer);
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
          Assert.AreEqual(ALimiteAttendue, Contexte.LimitePeripherie);
        finally
          Contexte.Free;
        end;
      end;

  initialization
    TDUnitX.RegisterTestFixture(TTestContextePartie);

end.
