unit AH.Core.Contexte;

  interface

    uses

      System.SysUtils, System.Variants;

    const

      /// <summary>Nombre maximum de joueurs humains autour de la table (règle maison).</summary>
      NombreMaxJoueursHumains = 8;
      /// <summary>
      /// Nombre maximum d'investigateurs en jeu (règle maison), qu'ils soient répartis entre
      /// plusieurs joueurs humains ou cumulés par un seul.
      /// </summary>
      NombreMaxInvestigateurs = 8;

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
          FInvestigateurs : TArray<TInvestigateurJoue>;
          FNiveauTerreur : Integer;
          FNombrePortailsOuverts : Integer;
          FNombreSignesDesAnciens : Integer;
          FEchelleDestin : Integer;
          /// <summary>
          /// Nombre total de cases de l'échelle du destin du Grand Ancien affronté cette partie
          /// (varie selon le Grand Ancien : imprimé sur sa feuille). Vaut 0 tant qu'il n'a pas
          /// été renseigné, ce qui doit se produire lors de la révélation du Grand Ancien
          /// pendant la préparation, avant toute résolution d'un nœud ntCondition sur
          /// EchelleDestinPleine.
          /// </summary>
          FTailleEchelleDestin : Integer;
          FNomGrandAncien : string;
          FTourCourant : Integer;
          FIndexInvestigateurCourant : Integer;
          FIndexPremierInvestigateur : Integer;
        public
          /// <param name="ANomsJoueursHumains">
          /// Prénoms des joueurs humains autour de la table. Entre 1 et NombreMaxJoueursHumains (8) éléments.
          /// </param>
          /// <param name="AInvestigateurs">
          /// Investigateurs en jeu, déjà ordonnés (ordre horaire des joueurs humains depuis le premier
          /// joueur, investigateurs d'un même joueur consécutifs). Entre 1 et NombreMaxInvestigateurs (8)
          /// éléments. Chaque IndexJoueurHumain doit être un index valide de ANomsJoueursHumains.
          /// </param>
          /// <exception cref="EArgumentOutOfRangeException">
          /// EArgumentOutOfRangeException levée si le nombre de joueurs humains ou d'investigateurs est hors de l'intervalle [1;8],
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

          /// <summary>
          /// Indique si la dernière case de l'échelle du destin est occupée (le Grand Ancien se réveille).
          /// </summary>
          /// <exception cref="EInvalidOpException">
          /// Levée si TailleEchelleDestin n'a pas encore été renseigné (n'a pas dû être résolu lors
          /// de la révélation du Grand Ancien avant cet appel — erreur d'ordonnancement du contenu).
          /// </exception>
          function EchelleDestinPleine : Boolean;

          /// <summary>Investigateur actuellement actif dans une boucle ntBouclePorInvestigateur.</summary>
          function InvestigateurCourant : TInvestigateurJoue;

          /// <summary>Nom de l'investigateur actuellement actif.</summary>
          function NomInvestigateurCourant  : string;

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
          /// <param name="ANomChamp">Nom du champ ciblé (ex. "NiveauTerreur", "TailleEchelleDestin"). Insensible à la casse.</param>
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

          /// <summary>Copie des prénoms des joueurs humains, dans l'ordre fourni à la création.</summary>
          function NomsJoueursHumains: TArray<string>;

          /// <summary>Copie des investigateurs en jeu, dans l'ordre de résolution des phases.</summary>
          function Investigateurs: TArray<TInvestigateurJoue>;          /// <summary>Index (base 0) de l'investigateur courant. Exposé pour la sauvegarde d'historique du moteur.</summary>

          /// <summary>
          /// Fait passer le marqueur Premier Joueur au joueur humain suivant dans l'ordre horaire —
          /// concrètement, au premier investigateur (dans l'ordre de jeu) contrôlé par ce joueur suivant.
          /// À appeler une fois par tour, à la fin de la phase du Mythe.
          /// </summary>
          procedure PasserMarqueurPremierJoueur;

          /// <summary>Maximum de monstres pouvant s'accumuler en Périphérie (règle page 18) : 8 - NombreInvestigateurs, jamais négatif.</summary>
          function LimitePeripherie : Integer;

          property IndexPremierInvestigateur : Integer read FIndexPremierInvestigateur write FIndexPremierInvestigateur;
          property IndexInvestigateurCourant : Integer read FIndexInvestigateurCourant write FIndexInvestigateurCourant;
          property NiveauTerreur : Integer read FNiveauTerreur write FNiveauTerreur;
          property NombrePortailsOuverts : Integer read FNombrePortailsOuverts write FNombrePortailsOuverts;
          property NombreSignesDesAnciens : Integer read FNombreSignesDesAnciens write FNombreSignesDesAnciens;
          property EchelleDestin : Integer read FEchelleDestin write FEchelleDestin;
          /// <summary>
          /// Nombre total de cases de l'échelle du destin du Grand Ancien affronté cette partie.
          /// À renseigner lors de sa révélation (valeur imprimée sur sa feuille) ; vaut 0 tant que non renseigné.
          /// </summary>
          property TailleEchelleDestin : Integer read FTailleEchelleDestin write FTailleEchelleDestin;
          property TourCourant : Integer read FTourCourant write FTourCourant;
          /// <summary>Nom du Grand Ancien affronté cette partie, renseigné lors de sa révélation. Vide tant que non renseigné.</summary>
          property NomGrandAncien : string read FNomGrandAncien write FNomGrandAncien;
      end;

  implementation

    uses

      System.Math;

    { TContextePartie }

    constructor TContextePartie.Create(const ANomsJoueursHumains: TArray<string>;
                                       const AInvestigateurs: TArray<TInvestigateurJoue>);
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

    function TContextePartie.NombreJoueursHumains: Integer;
      begin
        Result := Length(FNomsJoueursHumains);
      end;

    function TContextePartie.NombreInvestigateurs: Integer;
      begin
        Result := Length(FInvestigateurs);
      end;

    function TContextePartie.LimiteMonstres: Integer;
      begin
        Result := NombreInvestigateurs + 3;
      end;

    function TContextePartie.SeuilReveilPortailsOuverts: Integer;
      begin
        // Table page 19
        case NombreInvestigateurs of
          1..2 : Result := 8;
          3..4 : Result := 7;
          5..6 : Result := 6;
          7..8 : Result := 5;
        else
          raise EInvalidOpException.CreateFmt(
            'Nombre d''investigateurs hors limite (%d) : la validation du constructeur aurait dû l''empêcher.',
            [NombreInvestigateurs]);
        end;
      end;

    function TContextePartie.ArkhamEnvahie: Boolean;
      begin
        Result := FNiveauTerreur >= 10;
      end;

    function TContextePartie.EchelleDestinPleine: Boolean;
      begin
        if FTailleEchelleDestin <= 0 then
          raise EInvalidOpException.Create(
            'La taille de l''échelle du destin du Grand Ancien n''a pas encore été renseignée ' +
            '(le nœud ntSaisie "TailleEchelleDestin" doit être résolu lors de la révélation du Grand Ancien, avant tout appel à EchelleDestinPleine).');
        Result := FEchelleDestin >= FTailleEchelleDestin;
      end;

    function TContextePartie.InvestigateurCourant: TInvestigateurJoue;
      begin
        Result := FInvestigateurs[FIndexInvestigateurCourant];
      end;

    function TContextePartie.NomInvestigateurCourant: string;
      begin
        Result := InvestigateurCourant.NomInvestigateur;
      end;

    function TContextePartie.NomJoueurHumainCourant: string;
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

    procedure TContextePartie.AffecterChamp(const ANomChamp: string; const AValeur: Variant);
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
              else
                if SameText(ANomChamp, 'TailleEchelleDestin') then
                  FTailleEchelleDestin := AValeur
                else
                  if SameText(ANomChamp, 'NomGrandAncien') then
                    FNomGrandAncien := AValeur
                  else raise EArgumentException.CreateFmt(
                         'Champ de contexte inconnu ou non modifiable via ntSaisie : "%s".',
                         [ANomChamp]);
      end;

    function TContextePartie.LireChamp(const ANomChamp: string): Variant;
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
                if SameText(ANomChamp, 'TailleEchelleDestin') then
                  Result := FTailleEchelleDestin
                else
                  if SameText(ANomChamp, 'ArkhamEnvahie') then
                    Result := ArkhamEnvahie
                  else
                    if SameText(ANomChamp, 'EchelleDestinPleine') then
                      Result := EchelleDestinPleine
                    else
                      if SameText(ANomChamp, 'SeuilReveilPortailsOuvertsAtteint') then
                        Result := FNombrePortailsOuverts >= SeuilReveilPortailsOuverts
                      else
                        if SameText(ANomChamp, 'NomGrandAncien') then
                          Result := FNomGrandAncien
                        else
                          if SameText(ANomChamp, 'CinqInvestigateursOuPlus') then
                            Result := NombreInvestigateurs >= 5
                          else
                            if SameText(ANomChamp, 'PlusAucunPortailOuvert') then
                              Result := FNombrePortailsOuverts = 0
                            else
                              if SameText(ANomChamp, 'SixSignesDesAnciensAtteint') then
                                Result := FNombreSignesDesAnciens >= 6
                              else
                                raise EArgumentException.CreateFmt(
                                  'Champ de contexte inconnu : "%s".',
                                  [ANomChamp]);
      end;

    function TContextePartie.NomsJoueursHumains : TArray<string>;
      begin
        Result := Copy(FNomsJoueursHumains);
      end;

    function TContextePartie.Investigateurs : TArray<TInvestigateurJoue>;
      begin
        Result := Copy(FInvestigateurs);
      end;

    procedure TContextePartie.PasserMarqueurPremierJoueur;
      var
        IndexJoueurHumainSuivant : Integer;
        i : Integer;
      begin
        IndexJoueurHumainSuivant :=
          (FInvestigateurs[FIndexPremierInvestigateur].IndexJoueurHumain + 1) mod NombreJoueursHumains;

        for i := 0 to High(FInvestigateurs) do
          if FInvestigateurs[i].IndexJoueurHumain = IndexJoueurHumainSuivant then
            begin
              FIndexPremierInvestigateur := i;
              Exit;
            end;
      end;

    function TContextePartie.LimitePeripherie : Integer;
      begin
        Result := Max(8 - NombreInvestigateurs, 0);
      end;

end.
