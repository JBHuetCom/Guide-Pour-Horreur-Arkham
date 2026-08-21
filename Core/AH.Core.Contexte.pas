unit AH.Core.Contexte;

  interface

    uses
      System.SysUtils, System.Variants;

    const
      /// <summary>Nombre de cases de l'échelle du destin (règle page 19, feuille Grand Ancien).</summary>
      EchelleDestinTailleMax = 13;
      /// <summary>Nombre maximum de joueurs humains autour de la table (règle maison).</summary>
      NombreMaxJoueursHumains = 6;
      /// <summary>
      /// Nombre maximum d'investigateurs en jeu (règle maison), qu'ils soient répartis entre
      /// plusieurs joueurs humains ou cumulés par un seul.
      /// </summary>
      NombreMaxInvestigateurs = 6;

    type

      /// <summary>Association entre un investigateur en jeu et le joueur humain qui le contrôle.</summary>
      TInvestigateurJoue = record
        NomInvestigateur : string;
        /// <summary>Index (base 0) du joueur humain contrôleur, dans la liste fournie à TContextePartie.Create.</summary>
        IndexJoueurHumain : Integer;
      end;

      /// <summary>
      /// État global d'une partie en cours, limité aux compteurs nécessaires aux branchements
      /// de règles gérés par l'application (mode "Guide assisté"). Distingue les joueurs humains
      /// (qui valident les étapes) des investigateurs (unités de jeu physiques, sur lesquelles
      /// portent les règles de mouvement/rencontres/limites) : un même joueur humain peut
      /// contrôler plusieurs investigateurs.
      /// </summary>
      TContextePartie = class
        private
          FNomsJoueursHumains : TArray<string>;
          /// <summary>
          /// Investigateurs en jeu, dans l'ordre de résolution des phases I à IV : ordre horaire
          /// des joueurs humains depuis le premier joueur, et pour un même joueur humain, ses
          /// investigateurs consécutifs dans cet ordre. Cet ordre est déterminé par l'appelant
          /// (assistant de configuration de partie), pas recalculé ici.
          /// </summary>
          FInvestigateurs : TArray<TInvestigateurJoue>;
          FNiveauTerreur : Integer;
          FNombrePortailsOuverts : Integer;
          FNombreSignesDesAnciens : Integer;
          FEchelleDestin : Integer;
          FTourCourant : Integer;
          FIndexInvestigateurCourant : Integer;
          FIndexPremierInvestigateur : Integer;
        public
          /// <param name="ANomsJoueursHumains">
          /// Prénoms des joueurs humains autour de la table. Entre 1 et NombreMaxJoueursHumains (6) éléments.
          /// </param>
          /// <param name="AInvestigateurs">
          /// Investigateurs en jeu, déjà ordonnés (voir remarque sur le champ FInvestigateurs). Entre 1 et
          /// NombreMaxInvestigateurs (6) éléments. Chaque IndexJoueurHumain doit être un index valide de
          /// ANomsJoueursHumains.
          /// </param>
          /// <exception cref="EArgumentOutOfRangeException">
          /// Levée si le nombre de joueurs humains ou d'investigateurs est hors de l'intervalle [1;6],
          /// ou si un IndexJoueurHumain référence un joueur humain inexistant.
          /// </exception>
          constructor Create(const ANomsJoueursHumains : TArray<string>; const AInvestigateurs : TArray<TInvestigateurJoue>);

          function NombreJoueursHumains : Integer;
          function NombreInvestigateurs : Integer;

          /// <summary>Limite de monstres autorisée à Arkham (règle page 17) : NombreInvestigateurs + 3.</summary>
          function LimiteMonstres : Integer;

          /// <summary>
          /// Nombre de portails ouverts simultanément déclenchant le réveil du Grand Ancien (règle
          /// page 19, table bornée au maximum de 6 investigateurs autorisé par la règle maison).
          /// </summary>
          function SeuilReveilPortailsOuverts : Integer;

          /// <summary>Indique si le niveau de terreur a atteint la valeur maximale de l'échelle (10).</summary>
          function ArkhamEnvahie : Boolean;

          /// <summary>Indique si la dernière case de l'échelle du destin est occupée (le Grand Ancien se réveille).</summary>
          function EchelleDestinPleine : Boolean;

          /// <summary>Investigateur actuellement actif dans une boucle ntBouclePorInvestigateur.</summary>
          function InvestigateurCourant : TInvestigateurJoue;

          /// <summary>Nom de l'investigateur actuellement actif.</summary>
          function NomInvestigateurCourant : string;

          /// <summary>Prénom du joueur humain qui contrôle l'investigateur actuellement actif.</summary>
          function NomJoueurHumainCourant : string;

          /// <summary>Fait passer l'index de l'investigateur courant au suivant dans l'ordre de jeu, en bouclant.</summary>
          procedure PasserAlInvestigateurSuivant;

          /// <summary>Repositionne l'investigateur courant sur le premier de l'ordre de jeu (début de chaque phase).</summary>
          procedure RevenirAuPremierInvestigateur;

          /// <summary>
          /// Affecte par nom un champ modifiable du contexte, utilisé par le moteur pour résoudre
          /// les nœuds ntSaisie sans connaître statiquement la liste des champs.
          /// </summary>
          /// <param name="ANomChamp">Nom du champ ciblé (ex. "NiveauTerreur"). Insensible à la casse.</param>
          /// <param name="AValeur">Valeur à affecter, convertie selon le type réel du champ.</param>
          /// <exception cref="EArgumentException">
          /// Levée si ANomChamp ne correspond à aucun champ modifiable connu.
          /// </exception>
          procedure AffecterChamp(const ANomChamp : string; const AValeur : Variant);

          /// <summary>
          /// Lit par nom un champ du contexte, utilisé par TEvaluateurCondition pour résoudre
          /// les nœuds ntCondition sans connaître statiquement la liste des champs.
          /// </summary>
          /// <param name="ANomChamp">Nom du champ interrogé (ex. "ArkhamEnvahie"). Insensible à la casse.</param>
          /// <returns>La valeur courante du champ, sous forme de Variant.</returns>
          /// <exception cref="EArgumentException">
          /// Levée si ANomChamp ne correspond à aucun champ connu.
          /// </exception>
          function LireChamp(const ANomChamp : string) : Variant;

          /// <summary>Index (base 0) de l'investigateur courant. Exposé pour la sauvegarde d'historique du moteur.</summary>
          property IndexInvestigateurCourant : Integer read FIndexInvestigateurCourant write FIndexInvestigateurCourant;
          property NiveauTerreur : Integer read FNiveauTerreur write FNiveauTerreur;
          property NombrePortailsOuverts : Integer read FNombrePortailsOuverts write FNombrePortailsOuverts;
          property NombreSignesDesAnciens : Integer read FNombreSignesDesAnciens write FNombreSignesDesAnciens;
          property EchelleDestin : Integer read FEchelleDestin write FEchelleDestin;
          property TourCourant : Integer read FTourCourant write FTourCourant;
      end;

  implementation

    { TContextePartie }

    constructor TContextePartie.Create(const ANomsJoueursHumains : TArray<string>;
                                       const AInvestigateurs : TArray<TInvestigateurJoue>);
      var
        Investigateur: TInvestigateurJoue;
      begin
        inherited Create;

        if (Length(ANomsJoueursHumains) < 1)
          or (Length(ANomsJoueursHumains) > NombreMaxJoueursHumains)
        then
          raise EArgumentOutOfRangeException.CreateFmt(
            'Le nombre de joueurs humains doit être compris entre 1 et %d (valeur reçue : %d).',
            [NombreMaxJoueursHumains, Length(ANomsJoueursHumains)]);

        if (Length(AInvestigateurs) < 1)
          or (Length(AInvestigateurs) > NombreMaxInvestigateurs)
        then
          raise EArgumentOutOfRangeException.CreateFmt(
            'Le nombre d''investigateurs doit être compris entre 1 et %d (valeur reçue : %d).',
            [NombreMaxInvestigateurs, Length(AInvestigateurs)]);

        for Investigateur in AInvestigateurs do
          if (Investigateur.IndexJoueurHumain < 0)
            or (Investigateur.IndexJoueurHumain >= Length(ANomsJoueursHumains))
          then
            raise EArgumentOutOfRangeException.CreateFmt(
              'L''investigateur "%s" référence un joueur humain inexistant (index %d).',
              [Investigateur.NomInvestigateur, Investigateur.IndexJoueurHumain]);

        FNomsJoueursHumains := Copy(ANomsJoueursHumains);
        FInvestigateurs := Copy(AInvestigateurs);
        FTourCourant := 1;
      end;

    function TContextePartie.NombreJoueursHumains : Integer;
      begin
        Result := Length(FNomsJoueursHumains);
      end;

    function TContextePartie.NombreInvestigateurs : Integer;
      begin
        Result := Length(FInvestigateurs);
      end;

    function TContextePartie.LimiteMonstres : Integer;
      begin
        Result := NombreInvestigateurs + 3;
      end;

    function TContextePartie.SeuilReveilPortailsOuverts : Integer;
      begin
        // Table page 19, bornée au maximum de 6 investigateurs autorisé par la règle maison
        // (les cas 7-8 joueurs du livret original sont structurellement inatteignables ici).
        case NombreInvestigateurs of
          1..2: Result := 8;
          3..4: Result := 7;
          5..6: Result := 6;
        else
          raise EInvalidOpException.CreateFmt(
            'Nombre d''investigateurs hors limite (%d) : la validation du constructeur aurait dû l''empêcher.',
            [NombreInvestigateurs]);
        end;
      end;

    function TContextePartie.ArkhamEnvahie : Boolean;
      begin
        Result := FNiveauTerreur >= 10;
      end;

    function TContextePartie.EchelleDestinPleine : Boolean;
      begin
        Result := FEchelleDestin >= EchelleDestinTailleMax;
      end;

    function TContextePartie.InvestigateurCourant : TInvestigateurJoue;
      begin
        Result := FInvestigateurs[FIndexInvestigateurCourant];
      end;

    function TContextePartie.NomInvestigateurCourant : string;
      begin
        Result := InvestigateurCourant.NomInvestigateur;
      end;

    function TContextePartie.NomJoueurHumainCourant : string;
      begin
        Result := FNomsJoueursHumains[InvestigateurCourant.IndexJoueurHumain];
      end;

    procedure TContextePartie.PasserAlInvestigateurSuivant;
      begin
        FIndexInvestigateurCourant := (FIndexInvestigateurCourant + 1) mod NombreInvestigateurs;
      end;

    procedure TContextePartie.RevenirAuPremierInvestigateur;
      begin
        FIndexInvestigateurCourant := FIndexPremierInvestigateur;
      end;

    procedure TContextePartie.AffecterChamp(const ANomChamp : string; const AValeur : Variant);
      begin
        if SameText(ANomChamp, 'NiveauTerreur') then
          FNiveauTerreur := AValeur
        else
          if SameText(ANomChamp, 'NombrePortailsOuverts') then
            FNombrePortailsOuverts := AValeur
          else
            if SameText(ANomChamp, 'NombreSignesDesAnciens') then
              FNombreSignesDesAnciens := AValeur
            else
              if SameText(ANomChamp, 'EchelleDestin') then
                FEchelleDestin := AValeur
              else raise EArgumentException.CreateFmt(
                     'Champ de contexte inconnu ou non modifiable via ntSaisie : "%s".',
                     [ANomChamp]);
      end;

    function TContextePartie.LireChamp(const ANomChamp : string) : Variant;
      begin
        if SameText(ANomChamp, 'NiveauTerreur') then
          Result := FNiveauTerreur
        else
          if SameText(ANomChamp, 'NombrePortailsOuverts') then
            Result := FNombrePortailsOuverts
          else
            if SameText(ANomChamp, 'NombreSignesDesAnciens') then
              Result := FNombreSignesDesAnciens
            else
              if SameText(ANomChamp, 'EchelleDestin') then
                Result := FEchelleDestin
              else
                if SameText(ANomChamp, 'ArkhamEnvahie') then
                  Result := ArkhamEnvahie
                else
                  if SameText(ANomChamp, 'EchelleDestinPleine') then
                    Result := EchelleDestinPleine
                  else
                    if SameText(ANomChamp, 'SeuilReveilPortailsOuvertsAtteint') then
                      Result := FNombrePortailsOuverts >= SeuilReveilPortailsOuverts
                    else raise EArgumentException.CreateFmt(
                           'Champ de contexte inconnu : "%s".',
                           [ANomChamp]);
      end;

end.
