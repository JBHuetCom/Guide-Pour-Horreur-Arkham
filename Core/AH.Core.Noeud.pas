unit AH.Core.Noeud;

  interface

    uses
      System.Generics.Collections,
      AH.Core.Types;

    type
      TNoeudEtape = class;

      /// <summary>
      /// État partagé d'une branche. L'état possède exclusivement le nœud cible.
      /// Il est détruit automatiquement lorsque le dernier TBrancheEtape qui le
      /// référence est finalisé.
      /// </summary>
      IBrancheEtapeState = interface
        ['{FD2E037B-6F78-4B39-A6C7-1CB81D0D3D2C}']

        /// <summary>Retourne la valeur déclenchante de la branche.</summary>
        /// <returns>Valeur de contexte utilisée pour identifier la branche sélectionnée.</returns>
        function GetTriggerValue: Variant;

        /// <summary>Retourne le libellé affichable de la branche.</summary>
        /// <returns>Libellé de la branche ou EmptyStr lorsqu'aucun libellé n'est défini.</returns>
        function GetLabelText: string;

        /// <summary>Retourne le nœud cible possédé par l'état.</summary>
        /// <returns>Nœud cible ou nil si la branche ne possède pas de nœud.</returns>
        function GetNode: TNoeudEtape;
      end;

    /// <summary>
    /// Représente une branche conditionnelle de l'arbre de contenu.
    /// Les copies du record partagent le même état interne et ne clonent jamais
    /// implicitement le sous-arbre. Le clonage profond est exclusivement réalisé
    /// par TNoeudEtape.Clone.
    /// </summary>
    TBrancheEtape = record
      type
        /// <summary>
        /// Implémentation interne de l'état d'une branche.
        /// L'instance possède exclusivement FNode.
        /// </summary>
        TBrancheEtapeState = class(TInterfacedObject, IBrancheEtapeState)
          private
            FTriggerValue: Variant;
            FLabelText: string;
            FNode: TNoeudEtape;
          public
            /// <summary>
            /// Crée l'état d'une branche et enregistre le nœud dont il devient propriétaire.
            /// </summary>
            /// <param name="ATriggerValue">
            /// Valeur déclenchante de la branche.
            /// </param>
            /// <param name="ALabelText">
            /// Libellé de la branche.
            /// </param>
            /// <param name="ANode">
            /// Nœud cible possédé par l'état après la construction réussie.
            /// </param>
            constructor Create(const ATriggerValue: Variant;
              const ALabelText: string; ANode: TNoeudEtape);

            /// <summary>
            /// Détruit le nœud cible possédé par l'état.
            /// </summary>
            destructor Destroy; override;

            /// <summary>
            /// Retourne la valeur déclenchante de la branche.
            /// </summary>
            function GetTriggerValue: Variant;

            /// <summary>
            /// Retourne le libellé de la branche.
            /// </summary>
            function GetLabelText: string;

            /// <summary>
            /// Retourne le nœud cible de la branche.
            /// </summary>
            function GetNode: TNoeudEtape;
        end;
      private
        FState: IBrancheEtapeState;

        /// <summary>
        /// Retourne la valeur déclenchante de l'état interne.
        /// </summary>
        /// <returns>
        /// Valeur déclenchante ou Unassigned pour une branche non initialisée.
        /// </returns>
        function GetValeurDeclenchante: Variant;

        /// <summary>
        /// Retourne le libellé de l'état interne.
        /// </summary>
        /// <returns>
        /// Libellé de la branche ou EmptyStr pour une branche non initialisée.
        /// </returns>
        function GetLibelle: string;

        /// <summary>
        /// Retourne le nœud possédé par l'état interne.
        /// </summary>
        /// <returns>
        /// Nœud cible ou nil pour une branche non initialisée.
        /// </returns>
        function GetNoeud: TNoeudEtape;
      public
        /// <summary>
        /// Initialise le record sans état interne.
        /// </summary>
        /// <param name="ADestination">
        /// Instance du record à initialiser.
        /// </param>
        class operator Initialize(out ADestination : TBrancheEtape);

        /// <summary>
        /// Libère la référence vers l'état interne.
        /// Si cette référence est la dernière, l'état détruit automatiquement le
        /// nœud cible qu'il possède.
        /// </summary>
        /// <param name="ADestination">
        /// Instance du record en cours de finalisation.
        /// </param>
        class operator Finalize(var ADestination : TBrancheEtape);

        /// <summary>
        /// Copie une branche sans cloner son sous-arbre.
        /// La source et la destination partagent le même état interne.
        /// </summary>
        /// <param name="ADestination">
        /// Branche de destination.
        /// </param>
        /// <param name="ASource">
        /// Branche source qui reste inchangée.
        /// </param>
        class operator Assign(var ADestination : TBrancheEtape; const [ref] ASource : TBrancheEtape);

        /// <summary>
        /// Crée une branche et transfère la propriété de son nœud cible à l'état interne.
        /// Après un retour normal, l'appelant ne doit plus libérer ANoeud.
        /// </summary>
        /// <param name="ATriggerValue">Valeur de contexte déclenchant la branche.</param>
        /// <param name="ALabelText">Libellé associé à la branche.</param>
        /// <param name="ANode">Nœud cible dont la propriété est transférée à la branche.</param>
        /// <returns>Nouvelle branche possédant ANode.</returns>
        /// <exception cref="System.SysUtils.EOutOfMemory">
        /// Peut être levée si l'état interne ne peut pas être créé. Dans ce cas, l'appelant conserve la propriété de ANode.
        /// </exception>
        class function Create(const ATriggerValue : Variant; const ALabelText : string; ANode : TNoeudEtape) : TBrancheEtape; static;

        /// <summary>Valeur utilisée pour sélectionner cette branche.</summary>
        property ValeurDeclenchante : Variant read GetValeurDeclenchante;

        /// <summary>Libellé associé à cette branche.</summary>
        property Libelle : string read GetLibelle;

        /// <summary>Nœud cible détenu par l'état interne de la branche.</summary>
        property Noeud : TNoeudEtape read GetNoeud;
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
          /// <exception cref="EInvalidOpException">Levée si TypeNoeud n'est ni ntSequence ni ntBouclePorInvestigateur.</exception>
          procedure AjouterEnfant(AEnfant : TNoeudEtape);

          /// <summary>
          /// Ajoute une branche au nœud et prend possession de son nœud cible.
          /// Après un retour normal, l'appelant ne doit plus libérer ANoeud.
          /// En cas d'exception, cette méthode garantit la libération de ANoeud.
          /// </summary>
          /// <param name="ATriggerValue">Valeur de contexte qui sélectionne la branche.</param>
          /// <param name="ALabelText">Libellé associé à la branche.</param>
          /// <param name="ANode">Nœud cible dont la propriété est transférée.</param>
          /// <exception cref="System.SysUtils.EInvalidOp">Levée si le type du nœud ne peut pas contenir de branches.</exception>
          procedure AjouterBranche(const ATriggerValue : Variant; const ALabelText : string; ANode : TNoeudEtape);

          /// <summary>Crée une copie profonde du nœud, de ses enfants et de ses branches.</summary>
          /// <returns>Une nouvelle instance indépendante dont l'appelant devient propriétaire.</returns>
          /// <exception cref="System.SysUtils.EInvalidOp">
          /// Peut être levée si l'arbre contient une référence circulaire ou un état incompatible avec un clonage récursif.
          /// </exception>
          function Clone : TNoeudEtape;

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
      System.SysUtils, System.TypInfo, System.Variants;

    {$REGION 'TNoeudEtape'}

    function TNoeudEtape.Clone : TNoeudEtape;
      var
        ChildIndex: Integer;
        BrancheIndex: Integer;
        SourceEnfant: TNoeudEtape;
        SourceBranche: TBrancheEtape;
        ClonedBrancheNode: TNoeudEtape;
      begin
        Result := TNoeudEtape.Create(FId, FTypeNoeud);
        try
          Result.FTitre         := Self.FTitre;
          Result.FTexte         := Self.FTexte;
          Result.FIllustration  := Self.FIllustration;
          Result.FChampContexte := Self.FChampContexte;

          if Assigned(FEnfants) then
            for ChildIndex := 0 to FEnfants.Count - 1 do
              begin
                SourceEnfant := FEnfants[ChildIndex];
                Result.AjouterEnfant(SourceEnfant.Clone);
              end;

          if Assigned(FBranches) then
            for BrancheIndex := 0 to FBranches.Count - 1 do
              begin
                SourceBranche := FBranches[BrancheIndex];
                ClonedBrancheNode := nil;

                if Assigned(SourceBranche.Noeud) then
                  ClonedBrancheNode := SourceBranche.Noeud.Clone;

                Result.AjouterBranche(
                  SourceBranche.ValeurDeclenchante,
                  SourceBranche.Libelle,
                  ClonedBrancheNode);
              end;
        except
          Result.Free;

          raise;
        end;
      end;

    constructor TNoeudEtape.Create(const AId : string; ATypeNoeud : TTypeNoeud);
      begin
        inherited Create;

        FId := AId;
        FTypeNoeud := ATypeNoeud;

        if ATypeNoeud in [ntSequence, ntBouclePorInvestigateur] then
          FEnfants := TObjectList<TNoeudEtape>.Create(True)
        else
          FEnfants := nil;

        if ATypeNoeud in [ntCondition, ntChoix] then
          FBranches := TList<TBrancheEtape>.Create
        else
          FBranches := nil;
      end;

    destructor TNoeudEtape.Destroy;
      var
        Branche : TBrancheEtape;
      begin
        FEnfants.Free;
        FBranches.Free;

        inherited;
      end;

    procedure TNoeudEtape.AjouterEnfant(AEnfant : TNoeudEtape);
      begin
        if not Assigned(AEnfant) then
          raise EArgumentNilException.Create('Un enfant ajouté à une étape ne peut pas être nil.');

            if not (FTypeNoeud in [ntSequence, ntBouclePorInvestigateur]) then
          raise EInvalidOpException.CreateFmt(
            'Le nœud "%s" (%s) ne peut pas recevoir d''enfants directs.',
            [FId, GetEnumName(TypeInfo(TTypeNoeud), Ord(FTypeNoeud))]);

        FEnfants.Add(AEnfant);
      end;

    procedure TNoeudEtape.AjouterBranche(const ATriggerValue : Variant; const ALabelText : string; ANode : TNoeudEtape);
      var
        NewBranche: TBrancheEtape;
      begin
        try
          if not (FTypeNoeud in [ntCondition, ntChoix]) then
            raise EInvalidOpException.CreateFmt(
              'Le nœud "%s" (%s) ne peut pas recevoir de branches.',
              [FId, GetEnumName(TypeInfo(TTypeNoeud), Ord(FTypeNoeud))]);

          NewBranche := TBrancheEtape.Create(ATriggerValue, ALabelText, ANode);

          // La propriété est désormais dans NewBranche. Le pointeur local ne doit
          // plus être libéré dans le gestionnaire d'exception ci-dessous.
          ANode := nil;

          FBranches.Add(NewBranche);
        except
          ANode.Free;

          raise;
        end;
      end;

    {$ENDREGION}

    {$REGION 'TBrancheEtape'}

    class operator TBrancheEtape.Assign(var ADestination : TBrancheEtape; const [ref] ASource : TBrancheEtape);
      begin
        if @ADestination = @ASource then
          Exit;

        ADestination.FState := ASource.FState;
      end;

    class function TBrancheEtape.Create(const ATriggerValue : Variant; const ALabelText : string; ANode : TNoeudEtape) : TBrancheEtape;
      begin
        Result.FState := TBrancheEtapeState.Create(ATriggerValue, ALabelText, ANode);
      end;

    class operator TBrancheEtape.Finalize(var ADestination : TBrancheEtape);
      begin
        ADestination.FState := nil;
      end;

    function TBrancheEtape.GetLibelle : string;
      begin
        if not Assigned(FState) then
          Exit(EmptyStr);

        Result := FState.GetLabelText;
      end;

    function TBrancheEtape.GetNoeud : TNoeudEtape;
      begin
        if not Assigned(FState) then
          Exit(nil);

        Result := FState.GetNode;
      end;

    function TBrancheEtape.GetValeurDeclenchante : Variant;
      begin
        if not Assigned(FState) then
          Exit(Unassigned);

        Result := FState.GetTriggerValue;
      end;

    class operator TBrancheEtape.Initialize(out ADestination : TBrancheEtape);
      begin
        ADestination.FState := nil;
      end;

    {$ENDREGION}

    {$REGION 'TBrancheEtape.TBrancheEtapeState'}

    constructor TBrancheEtape.TBrancheEtapeState.Create(const ATriggerValue : Variant; const ALabelText : string; ANode : TNoeudEtape);
      begin
        inherited Create;

        // Les affectations potentiellement gérées sont réalisées avant le transfert
        // effectif de propriété du nœud.
        FTriggerValue := ATriggerValue;
        FLabelText := ALabelText;
        FNode := ANode;
      end;

    destructor TBrancheEtape.TBrancheEtapeState.Destroy;
      begin
        FNode.Free;

        inherited;
      end;

    function TBrancheEtape.TBrancheEtapeState.GetLabelText : string;
      begin
        Result := FLabelText;
      end;

    function TBrancheEtape.TBrancheEtapeState.GetNode : TNoeudEtape;
      begin
        Result := FNode;
      end;

    function TBrancheEtape.TBrancheEtapeState.GetTriggerValue : Variant;
      begin
        Result := FTriggerValue;
      end;

    {$ENDREGION}

end.
