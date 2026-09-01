unit AH.Core.Moteur;

  interface

    uses
      System.Generics.Collections, System.Variants,
      AH.Core.Noeud, AH.Core.Contexte;

    type

      /// <summary>
      /// Position du parcours à l'intérieur d'un nœud conteneur (ntSequence ou ntBouclePorInvestigateur) :
      /// index du prochain enfant à visiter, et nombre de passages restants pour une boucle par investigateur.
      /// </summary>
      TFrameParcours = record
        Noeud : TNoeudEtape;
        IndexProchainEnfant : Integer;
        InvestigateursRestants : Integer; // Non significatif hors ntBouclePorInvestigateur.
      end;

      /// <summary>Instantané de l'état de parcours, capturé avant chaque Suivant pour permettre Precedent.</summary>
      TInstantane = record
        NoeudCourant : TNoeudEtape;
        Pile : TArray<TFrameParcours>;
        BrancheChoisieEnAttente : TNoeudEtape;
        IndexInvestigateurCourant : Integer;
        EnAttenteReponse : Boolean;
      end;

      /// <summary>
      /// Séquenceur d'étapes : parcourt l'arbre TNoeudEtape en profondeur, résout automatiquement
      /// les nœuds ntCondition et les répétitions de ntBouclePorInvestigateur, et expose à l'appelant
      /// UI uniquement les nœuds nécessitant une interaction humaine (ntInstruction, ntChoix, ntSaisie).
      /// </summary>
      TMoteurSequenceur = class
        private
          FRacine : TNoeudEtape;
          FContexte : TContextePartie;
          FPile : TList<TFrameParcours>;
          FHistorique : TStack<TInstantane>;
          FNoeudCourant : TNoeudEtape;
          FBrancheChoisieEnAttente : TNoeudEtape;
          FEnAttenteReponse : Boolean;

          procedure PousserFrame(ANoeud : TNoeudEtape; AInvestigateursRestants : Integer);
          function TraiterNoeud(ANoeud : TNoeudEtape) : TNoeudEtape;
          function AvancerJusquInteractif : TNoeudEtape;
          function CapturerInstantane : TInstantane;
          procedure RestaurerInstantane(const AInstantane : TInstantane);
        public
          /// <param name="ARacine">Arbre de contenu chargé. Conservé par référence, non libéré par ce moteur.</param>
          /// <param name="AContexte">Contexte de partie utilisé pour résoudre les nœuds ntCondition et ntSaisie. Conservé par référence.</param>
          constructor Create(ARacine : TNoeudEtape; AContexte : TContextePartie);
          destructor Destroy; override;

          /// <summary>
          /// Avance jusqu'au prochain nœud nécessitant une interaction utilisateur, en résolvant
          /// silencieusement tous les nœuds automatiques rencontrés en chemin.
          /// </summary>
          /// <returns>Le nœud à afficher, ou nil si l'arbre est entièrement épuisé (fin de séquence).</returns>
          /// <exception cref="EInvalidOpException">
          /// Levée si le nœud courant est un ntChoix ou ntSaisie n'ayant pas encore reçu de réponse.
          /// </exception>
          function Suivant : TNoeudEtape;

          /// <summary>Revient à l'état affiché avant le dernier appel à Suivant.</summary>
          /// <returns>Le nœud précédemment affiché, ou nil si l'historique est vide (déjà à la racine).</returns>
          function Precedent : TNoeudEtape;

          /// <summary>
          /// Indique si le nœud actuellement affiché se trouve à l'intérieur d'une boucle par
          /// investigateur active (donc si FContexte.NomInvestigateurCourant/NomJoueurHumainCourant
          /// sont pertinents pour cette étape). False pour toute étape hors d'une telle boucle
          /// (ex. la révélation du Grand Ancien, qui concerne le groupe entier).
          /// </summary>
          function EstDansBouclePorInvestigateur : Boolean;

          /// <summary>Indique si Precedent peut faire reculer la navigation (False juste après le chargement d'un nouvel arbre).</summary>
          function PeutReculer: Boolean;

          /// <summary>
          /// Enregistre la réponse de l'utilisateur pour le nœud courant (ntChoix ou ntSaisie),
          /// préalable obligatoire à l'appel de Suivant pour ces deux types de nœud.
          /// </summary>
          /// <param name="AValeur">
          /// Pour ntChoix : ValeurDeclenchante de la branche sélectionnée. Pour ntSaisie : valeur saisie,
          /// affectée au champ de contexte désigné par NoeudCourant.ChampContexte.
          /// </param>
          /// <exception cref="EInvalidOpException">
          /// Levée si le nœud courant n'est ni ntChoix ni ntSaisie, ou si aucun nœud courant n'existe.
          /// </exception>
          /// <exception cref="EArgumentException">
          /// Levée (cas ntChoix) si AValeur ne correspond à aucune branche déclarée du nœud courant.
          /// </exception>
          procedure EnregistrerReponse(const AValeur : Variant);

          /// <summary>
          /// Titres (non vides) des nœuds conteneurs actuellement actifs sur la pile de navigation, du
          /// plus englobant au plus proche du nœud courant — ex. ["Phase II : Mouvement"]. Permet à
          /// l'UI d'afficher ces titres tant que leurs enfants sont en cours de parcours, alors que le
          /// moteur ne retourne jamais directement un nœud conteneur à l'appelant.
          /// </summary>
          function TitresPhaseActifs : TArray<string>;

          property NoeudCourant : TNoeudEtape read FNoeudCourant;
      end;

  implementation

    uses
      System.SysUtils,
      AH.Core.EvaluateurCondition, AH.Core.Types;

    {$REGION 'TMoteurSequenceur'}

    constructor TMoteurSequenceur.Create(ARacine : TNoeudEtape; AContexte : TContextePartie);
      begin
        inherited Create;

        FRacine := ARacine;
        FContexte := AContexte;
        FPile := TList<TFrameParcours>.Create;
        FHistorique := TStack<TInstantane>.Create;

        if FRacine.TypeNoeud in [ntSequence, ntBouclePorInvestigateur] then
          PousserFrame(FRacine, 1)
        else
          // La racine n'est pas un conteneur (ex. fin_de_partie.json, dont la racine est un
          // ntChoix) : Enfants y vaut nil, PousserFrame planterait dessus. On la traite comme
          // n'importe quel nœud rencontré en cours de route, via la résolution habituelle
          // (TraiterNoeud, invoquée par AvancerJusquInteractif dès le premier Suivant).
          FBrancheChoisieEnAttente := FRacine;
      end;

    destructor TMoteurSequenceur.Destroy;
      begin
        FPile.Free;
        FHistorique.Free;

        inherited;
      end;

    procedure TMoteurSequenceur.PousserFrame(ANoeud : TNoeudEtape; AInvestigateursRestants : Integer);
      var
        Frame : TFrameParcours;
      begin
        Frame.Noeud := ANoeud;
        Frame.IndexProchainEnfant := 0;
        Frame.InvestigateursRestants := AInvestigateursRestants;
        FPile.Add(Frame);
      end;

    function TMoteurSequenceur.TraiterNoeud(ANoeud : TNoeudEtape) : TNoeudEtape;
      var
        NoeudResolu : TNoeudEtape;
      begin
        NoeudResolu := ANoeud;
        while NoeudResolu.TypeNoeud = ntCondition do
          NoeudResolu := TEvaluateurCondition.ResoudreBranche(NoeudResolu, FContexte);

        case NoeudResolu.TypeNoeud of
          ntSequence:
            begin
              PousserFrame(NoeudResolu, 0);
              Result := nil;
            end;
          ntBouclePorInvestigateur:
            begin
              FContexte.RevenirAuPremierInvestigateur;
              PousserFrame(NoeudResolu, FContexte.NombreInvestigateurs);
              Result := nil;
            end;
          ntSaisie:
            if NoeudResolu.PossedeValeurForcee then
              begin
                FContexte.AffecterChamp(NoeudResolu.ChampContexte, NoeudResolu.ValeurForcee);
                Result := nil; // Auto-résolu : la boucle d'AvancerJusquInteractif passe au frère suivant.
              end
            else
              Result := NoeudResolu;
        else
          Result := NoeudResolu;
        end;
      end;

  function TMoteurSequenceur.AvancerJusquInteractif : TNoeudEtape;
    var
      Frame : TFrameParcours;
      EnfantSuivant, Trouve : TNoeudEtape;
    begin
      // Reprise après réponse à un ntChoix : la branche choisie doit être visitée avant
      // de reprendre le parcours normal de la pile.
      if Assigned(FBrancheChoisieEnAttente) then
        begin
          EnfantSuivant := FBrancheChoisieEnAttente;
          FBrancheChoisieEnAttente := nil;
          Trouve := TraiterNoeud(EnfantSuivant);
          if Assigned(Trouve) then
            Exit(Trouve);
        end;

      while FPile.Count > 0 do
        begin
          Frame := FPile[FPile.Count - 1];
          if Frame.IndexProchainEnfant < Frame.Noeud.Enfants.Count then
            begin
              EnfantSuivant := Frame.Noeud.Enfants[Frame.IndexProchainEnfant];
              Frame.IndexProchainEnfant := Frame.IndexProchainEnfant + 1;
              FPile[FPile.Count - 1] := Frame;
              Trouve := TraiterNoeud(EnfantSuivant);
              if Assigned(Trouve) then
                Exit(Trouve);

              // Sinon TraiterNoeud a poussé une frame : la boucle continue et y redescend.
            end
          else
          begin
            if (Frame.Noeud.TypeNoeud = ntBouclePorInvestigateur)
               and (Frame.InvestigateursRestants > 1)
            then
              begin
                Frame.InvestigateursRestants := Frame.InvestigateursRestants - 1;
                Frame.IndexProchainEnfant := 0;
                FPile[FPile.Count - 1] := Frame;
                FContexte.PasserAlInvestigateurSuivant;
              end
            else
              FPile.Delete(FPile.Count - 1);
          end;
        end;
      Result := nil; // Pile vide : arbre entièrement parcouru.
    end;

  function TMoteurSequenceur.CapturerInstantane: TInstantane;
    begin
      with Result do
        begin
          NoeudCourant := FNoeudCourant;
          Pile := FPile.ToArray;
          BrancheChoisieEnAttente := FBrancheChoisieEnAttente;
          IndexInvestigateurCourant := FContexte.IndexInvestigateurCourant;
          EnAttenteReponse := FEnAttenteReponse;
        end;
    end;

  procedure TMoteurSequenceur.RestaurerInstantane(const AInstantane: TInstantane);
    begin
      FNoeudCourant := AInstantane.NoeudCourant;
      FPile.Clear;
      FPile.AddRange(AInstantane.Pile);
      FBrancheChoisieEnAttente := AInstantane.BrancheChoisieEnAttente;
      FContexte.IndexInvestigateurCourant := AInstantane.IndexInvestigateurCourant;
      FEnAttenteReponse := AInstantane.EnAttenteReponse;
    end;

  function TMoteurSequenceur.Suivant : TNoeudEtape;
    begin
      if FEnAttenteReponse then
        raise EInvalidOpException.CreateFmt(
          'Le nœud "%s" attend une réponse (EnregistrerReponse) avant de pouvoir avancer.',
          [FNoeudCourant.Id]);

      FHistorique.Push(CapturerInstantane);
      Result := AvancerJusquInteractif;
      FNoeudCourant := Result;
      FEnAttenteReponse := Assigned(Result) and (Result.TypeNoeud in [ntChoix, ntSaisie]);
    end;

  function TMoteurSequenceur.Precedent: TNoeudEtape;
    begin
      if FHistorique.Count = 0 then
        Exit(nil);

      RestaurerInstantane(FHistorique.Pop);
      Result := FNoeudCourant;
    end;

  procedure TMoteurSequenceur.EnregistrerReponse(const AValeur : Variant);
    var
      Branche : TBrancheEtape;
      BrancheTrouvee : Boolean;
    begin
      if not Assigned(FNoeudCourant) then
        raise EInvalidOpException.Create('Aucune étape courante en attente de réponse.');

      case FNoeudCourant.TypeNoeud of
        ntSaisie:
          FContexte.AffecterChamp(FNoeudCourant.ChampContexte, AValeur);
        ntChoix:
          begin
            BrancheTrouvee := False;
            for Branche in FNoeudCourant.Branches do
              if Branche.ValeurDeclenchante = AValeur then
                begin
                  FBrancheChoisieEnAttente := Branche.Noeud;
                  BrancheTrouvee := True;
                  Break;
                end;
            if not BrancheTrouvee then
              raise EArgumentException.CreateFmt(
                'Aucune branche du nœud "%s" ne correspond à la réponse fournie.',
                [FNoeudCourant.Id]);
          end;
      else
        raise EInvalidOpException.CreateFmt(
          'Le nœud "%s" n''attend pas de réponse (EnregistrerReponse réservé à ntChoix et ntSaisie).',
          [FNoeudCourant.Id]);
      end;

      FEnAttenteReponse := False;
    end;

    function TMoteurSequenceur.EstDansBouclePorInvestigateur : Boolean;
      var
        i : Integer;
      begin
        Result := False;
        for i := 0 to FPile.Count - 1 do
          if FPile[i].Noeud.TypeNoeud = ntBouclePorInvestigateur then
            Exit(True);
      end;

    function TMoteurSequenceur.PeutReculer: Boolean;
      begin
        Result := (FHistorique.Count > 0);
      end;

    function TMoteurSequenceur.TitresPhaseActifs : TArray<string>;
      var
        Resultat : TList<string>;
        i : Integer;
      begin
        Resultat := TList<string>.Create;
        try
          for i := 0 to FPile.Count - 1 do
            if FPile[i].Noeud.Titre <> EmptyStr then
              Resultat.Add(FPile[i].Noeud.Titre);
          Result := Resultat.ToArray;
        finally
          Resultat.Free;
        end;
      end;

  {$ENDREGION}

end.
