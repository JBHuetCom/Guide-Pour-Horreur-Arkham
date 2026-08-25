unit AH.Core.ConstructeurPartie;

  interface

    uses

      System.Generics.Collections,
      AH.Core.Contexte;

    type
      /// <summary>
      /// Logique de construction et d'édition, indépendante de toute UI, de la liste ordonnée
      /// des investigateurs d'une partie en cours de configuration. Sépare la logique métier
      /// (ordre de jeu, suppression en cascade) de l'assistant de configuration
      /// (AH.UI.FrmNouvellePartie) pour la rendre testable sans dépendance à la VCL.
      /// </summary>
      TConstructeurPartie = class
        public
          /// <summary>
          /// Reconstruit la liste des investigateurs dans l'ordre de jeu attendu par
          /// TContextePartie.Create : joueurs humains dans l'ordre de ANomsJoueursHumains,
          /// investigateurs d'un même joueur consécutifs dans leur ordre d'apparition dans
          /// AInvestigateurs.
          /// </summary>
          /// <param name="ANomsJoueursHumains">Joueurs humains, dans l'ordre de jeu (le premier est le premier joueur).</param>
          /// <param name="AInvestigateurs">Investigateurs déjà saisis, dans un ordre quelconque.</param>
          /// <returns>Les mêmes investigateurs, réordonnés.</returns>
          class function OrdonnerParJoueur(const ANomsJoueursHumains : TArray<string>;
            const AInvestigateurs : TArray<TInvestigateurJoue>) : TArray<TInvestigateurJoue>; static;

          /// <summary>
          /// Retire de AInvestigateurs tous les investigateurs contrôlés par le joueur humain
          /// d'index AIndexJoueurSupprime, et décale d'une unité vers le bas l'IndexJoueurHumain
          /// de tous les investigateurs contrôlés par un joueur humain situé après lui — pour
          /// rester cohérent une fois ce joueur retiré de la liste des joueurs humains.
          /// </summary>
          /// <param name="AInvestigateurs">Liste modifiée en place.</param>
          /// <param name="AIndexJoueurSupprime">Index (base 0) du joueur humain retiré.</param>
          /// <returns>Le nombre d'investigateurs retirés (utile pour avertir l'utilisateur avant confirmation).</returns>
          class function SupprimerJoueurEtRepercuter(AInvestigateurs : TList<TInvestigateurJoue>;
            AIndexJoueurSupprime : Integer) : Integer; static;

          /// <param name="AInvestigateurs">Investigateurs déjà saisis.</param>
          /// <param name="ANomInvestigateur">Nom à vérifier, comparé sans tenir compte de la casse.</param>
          /// <returns>True si un investigateur de ce nom existe déjà dans AInvestigateurs.</returns>
          class function NomDejaUtilise(const AInvestigateurs : TArray<TInvestigateurJoue>;
            const ANomInvestigateur : string) : Boolean; static;
      end;

  implementation

    uses

      System.SysUtils;

    { TConstructeurPartie }

    class function TConstructeurPartie.OrdonnerParJoueur(const ANomsJoueursHumains : TArray<string>;
                                                         const AInvestigateurs : TArray<TInvestigateurJoue>) : TArray<TInvestigateurJoue>;
      var
        Resultat : TList<TInvestigateurJoue>;
        IndexJoueur : Integer;
        Investigateur : TInvestigateurJoue;
      begin
        Resultat := TList<TInvestigateurJoue>.Create;
        try
          for IndexJoueur := 0 to High(ANomsJoueursHumains) do
            for Investigateur in AInvestigateurs do
              if Investigateur.IndexJoueurHumain = IndexJoueur then
                Resultat.Add(Investigateur);
          Result := Resultat.ToArray;
        finally
          Resultat.Free;
        end;
      end;

    class function TConstructeurPartie.SupprimerJoueurEtRepercuter(AInvestigateurs : TList<TInvestigateurJoue>;
                                                                   AIndexJoueurSupprime : Integer) : Integer;
      var
        i : Integer;
        Investigateur : TInvestigateurJoue;
      begin
        Result := 0;
        for i := AInvestigateurs.Count - 1 downto 0 do
        begin
          if AInvestigateurs[i].IndexJoueurHumain = AIndexJoueurSupprime then
            begin
              AInvestigateurs.Delete(i);
              Inc(Result);
            end
          else if AInvestigateurs[i].IndexJoueurHumain > AIndexJoueurSupprime then
            begin
              Investigateur := AInvestigateurs[i];
              Investigateur.IndexJoueurHumain := Investigateur.IndexJoueurHumain - 1;
              AInvestigateurs[i] := Investigateur;
            end;
        end;
      end;

    class function TConstructeurPartie.NomDejaUtilise(const AInvestigateurs : TArray<TInvestigateurJoue>;
                                                      const ANomInvestigateur : string) : Boolean;
      var
        Investigateur: TInvestigateurJoue;
      begin
        Result := False;
        for Investigateur in AInvestigateurs do
          if SameText(Investigateur.NomInvestigateur, ANomInvestigateur) then
            Exit(True);
      end;

end.
