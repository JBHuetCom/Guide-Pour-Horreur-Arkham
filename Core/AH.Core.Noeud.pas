unit AH.Core.Noeud;

  interface

    uses
      System.Generics.Collections,
      AH.Core.Types;

    type
      TNoeudEtape = class;

      /// <summary>
      /// Une branche associe une valeur déclenchante (comparée au champ de contexte désigné
      /// pour ntCondition, ou identifiant de bouton pour ntChoix) à un sous-arbre à parcourir
      /// si elle est retenue.
      /// </summary>
      TBrancheEtape = record
        ValeurDeclenchante : Variant;
        Libelle : string; // Utilisé uniquement par ntChoix, pour l'intitulé du bouton affiché.
        Noeud : TNoeudEtape;
      end;

      /// <summary>
      /// Nœud de l'arbre de contenu d'une partie. La possession des enfants et des branches
      /// est exclusive : détruire un nœud détruit récursivement tout son sous-arbre.
      /// </summary>
      TNoeudEtape = class
        private
          FId : string;
          FTypeNoeud : TTypeNoeud;
          FTitre : string;
          FTexte : string;
          FIllustration : string;
          FChampContexte : string;
          FEnfants : TObjectList<TNoeudEtape>;
          FBranches : TList<TBrancheEtape>;
        public
          /// <param name="AId">Identifiant unique du nœud, utilisé pour le diagnostic et les tests.</param>
          /// <param name="ATypeNoeud">Nature du nœud, détermine son mode de résolution par le moteur.</param>
          constructor Create(const AId : string; ATypeNoeud : TTypeNoeud);
          destructor Destroy; override;

          /// <summary>Ajoute un enfant en fin de liste. Le nœud devient propriétaire de AEnfant.</summary>
          /// <param name="AEnfant">Sous-nœud à ajouter.</param>
          /// <exception cref="EInvalidOpException">
          /// Levée si TypeNoeud n'est ni ntSequence ni ntBouclePorInvestigateur.
          /// </exception>
          procedure AjouterEnfant(AEnfant : TNoeudEtape);

          /// <summary>Ajoute une branche. Le nœud devient propriétaire de ABranche.Noeud.</summary>
          /// <param name="ABranche">Branche à ajouter.</param>
          /// <exception cref="EInvalidOpException">
          /// Levée si TypeNoeud n'est ni ntCondition ni ntChoix.
          /// </exception>
          procedure AjouterBranche(const ABranche : TBrancheEtape);

          property Id : string read FId;
          property TypeNoeud : TTypeNoeud read FTypeNoeud;
          property Titre : string read FTitre write FTitre;
          property Texte : string read FTexte write FTexte;
          property Illustration : string read FIllustration write FIllustration;
          /// <summary>
          /// Pour ntCondition : nom du champ de TContextePartie évalué pour choisir la branche.
          /// Pour ntSaisie : nom du champ de TContextePartie renseigné par la réponse utilisateur.
          /// Sans effet pour les autres types de nœud.
          /// </summary>
          property ChampContexte : string read FChampContexte write FChampContexte;
          property Enfants : TObjectList<TNoeudEtape> read FEnfants;
          property Branches : TList<TBrancheEtape> read FBranches;
      end;

  implementation

    uses
      System.SysUtils, System.TypInfo;

    { TNoeudEtape }

    constructor TNoeudEtape.Create(const AId : string; ATypeNoeud : TTypeNoeud);
      begin
        inherited Create;
        FId := AId;
        FTypeNoeud := ATypeNoeud;
        if ATypeNoeud in [ntSequence, ntBouclePorInvestigateur] then
          FEnfants := TObjectList<TNoeudEtape>.Create(True);
        if ATypeNoeud in [ntCondition, ntChoix] then
          FBranches := TList<TBrancheEtape>.Create;
      end;

    destructor TNoeudEtape.Destroy;
      var
        Branche: TBrancheEtape;
      begin
        FEnfants.Free;
        if Assigned(FBranches) then
          begin
            for Branche in FBranches do
              Branche.Noeud.Free;
            FBranches.Free;
          end;
        inherited;
      end;

    procedure TNoeudEtape.AjouterEnfant(AEnfant : TNoeudEtape);
      begin
        if not (FTypeNoeud in [ntSequence, ntBouclePorInvestigateur]) then
          raise EInvalidOpException.CreateFmt(
            'Le nœud "%s" (%s) ne peut pas recevoir d''enfants directs.',
            [FId, GetEnumName(TypeInfo(TTypeNoeud), Ord(FTypeNoeud))]);
        FEnfants.Add(AEnfant);
      end;

    procedure TNoeudEtape.AjouterBranche(const ABranche : TBrancheEtape);
      begin
        if not (FTypeNoeud in [ntCondition, ntChoix]) then
          raise EInvalidOpException.CreateFmt(
            'Le nœud "%s" (%s) ne peut pas recevoir de branches.',
            [FId, GetEnumName(TypeInfo(TTypeNoeud), Ord(FTypeNoeud))]);
        FBranches.Add(ABranche);
      end;

end.
