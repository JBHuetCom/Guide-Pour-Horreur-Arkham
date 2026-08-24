unit AH.Core.Session;

  interface

    uses

      System.SysUtils, System.Variants, System.Generics.Collections,
      AH.Core.Types, AH.Core.Contexte, AH.Core.Noeud, AH.Core.Moteur;

    type

      ESessionInvalideException = class(Exception);

      /// <summary>
      /// Photographie complète d'une partie en cours, suffisante pour la reconstruire à
      /// l'identique : état de TContextePartie, identification du fichier de contenu actif, et
      /// position exacte de navigation au sein de ce fichier (rejouée par
      /// TGestionnaireSession.RestaurerPosition).
      /// </summary>
      TSessionPartie = record
        NomsJoueursHumains : TArray<string>;
        Investigateurs : TArray<TInvestigateurJoue>;
        NiveauTerreur : Integer;
        NombrePortailsOuverts : Integer;
        NombreSignesDesAnciens : Integer;
        EchelleDestin : Integer;
        TailleEchelleDestin : Integer;
        TourCourant : Integer;
        IndexInvestigateurCourant : Integer;
        /// <summary>
        /// Identifie le fichier de contenu actif au moment de la sauvegarde (ex. "preparation",
        /// "tour", "bataille_finale", "fin_de_partie"). Charge libre, propre à l'application
        /// appelante : cette unité ne charge elle-même aucun fichier de contenu.
        /// </summary>
        FichierContenuActif : string;
        /// <summary>Nombre total d'appels réussis à Suivant effectués dans le fichier actif depuis son chargement.</summary>
        NombreEtapesTraversees : Integer;
        /// <summary>
        /// Valeurs fournies à EnregistrerReponse, dans l'ordre, pour chaque nœud ntChoix/ntSaisie
        /// déjà répondu parmi les NombreEtapesTraversees premières étapes (le nœud courant, s'il
        /// attend encore une réponse, n'y figure pas).
        /// </summary>
        ReponsesEnregistrees : TArray<Variant>;
      end;

      /// <summary>
      /// Décore un TMoteurSequenceur pour journaliser automatiquement chaque étape traversée et
      /// chaque réponse fournie, afin de pouvoir reconstituer un TSessionPartie à tout moment sans
      /// faire porter cette responsabilité à l'appelant (UI). Toute navigation doit passer par ce
      /// décorateur plutôt que directement par le TMoteurSequenceur sous-jacent, sous peine de
      /// désynchroniser le journal.
      /// </summary>
      TMoteurSequenceurJournalise = class
        private
          FMoteur : TMoteurSequenceur;
          FNombreEtapesTraversees : Integer;
          FReponsesEnregistrees : TList<Variant>;
          function GetNoeudCourant : TNoeudEtape;
        public
          /// <param name="AMoteur">Moteur à décorer. Conservé par référence, non libéré par ce décorateur.</param>
          constructor Create(AMoteur : TMoteurSequenceur);
          destructor Destroy; override;

          /// <summary>Équivalent journalisé de TMoteurSequenceur.Suivant.</summary>
          function Suivant : TNoeudEtape;

          /// <summary>
          /// Équivalent journalisé de TMoteurSequenceur.Precedent : dépile la dernière étape du
          /// journal (et sa réponse éventuelle) en même temps que le moteur sous-jacent recule.
          /// </summary>
          function Precedent : TNoeudEtape;

          /// <summary>Équivalent journalisé de TMoteurSequenceur.EnregistrerReponse.</summary>
          procedure EnregistrerReponse(const AValeur : Variant);

          /// <summary>
          /// Construit l'instantané de session correspondant à l'état courant du contexte et à la
          /// position actuelle de navigation.
          /// </summary>
          /// <param name="AContexte">Contexte de partie associé à ce moteur (mêmes valeurs que celles passées à TMoteurSequenceur.Create).</param>
          /// <param name="AFichierContenuActif">Identifiant du fichier de contenu actif, à des fins de restauration ultérieure.</param>
          function CapturerSession(AContexte : TContextePartie; const AFichierContenuActif : string): TSessionPartie;

          property NoeudCourant : TNoeudEtape read GetNoeudCourant;
      end;

      /// <summary>
      /// Sérialise/désérialise un TSessionPartie en JSON (via SuperObject), reconstruit un
      /// TContextePartie à partir d'une session chargée, et rejoue la position de navigation
      /// exacte sur un moteur fraîchement créé pour le fichier de contenu correspondant.
      /// </summary>
      TGestionnaireSession = class
        public
          /// <param name="ASession">Session à sauvegarder.</param>
          /// <param name="ACheminFichier">Chemin du fichier .json à écrire (créé s'il n'existe pas, écrasé sinon).</param>
          class procedure SauvegarderDansFichier(const ASession : TSessionPartie; const ACheminFichier : string);

          /// <param name="ACheminFichier">Chemin d'un fichier .json produit par SauvegarderDansFichier.</param>
          /// <exception cref="EFileNotFoundException">Levée si ACheminFichier n'existe pas.</exception>
          /// <exception cref="ESessionInvalideException">Levée si le JSON est malformé ou incomplet.</exception>
          class function ChargerDepuisFichier(const ACheminFichier : string): TSessionPartie;

          /// <param name="ASession">Session dont l'état de partie doit être restauré.</param>
          /// <returns>Un TContextePartie neuf, dans l'état exact enregistré dans ASession. L'appelant en devient propriétaire.</returns>
          class function RecreerContexte(const ASession : TSessionPartie): TContextePartie;

          /// <summary>
          /// Rejoue, sur AMoteur fraîchement créé (contenu déjà chargé, position au tout début),
          /// exactement la séquence d'appels Suivant/EnregistrerReponse enregistrée dans ASession,
          /// pour ramener AMoteur à la position exacte où la partie avait été sauvegardée.
          /// </summary>
          /// <param name="AMoteur">Moteur journalisé fraîchement créé sur le contenu correspondant à ASession.FichierContenuActif, pas encore avancé.</param>
          /// <param name="ASession">Session contenant la position à restaurer.</param>
          /// <exception cref="ESessionInvalideException">
          /// Levée si le contenu rechargé a divergé de celui utilisé à la sauvegarde (nombre d'étapes
          /// ou de réponses insuffisant), signe que les fichiers JSON de contenu ont changé entre-temps.
          /// </exception>
          class procedure RestaurerPosition(AMoteur : TMoteurSequenceurJournalise; const ASession : TSessionPartie);
      end;

  implementation

    uses

      SuperObject;

    {$REGION 'TMoteurSequenceurJournalise'}

    constructor TMoteurSequenceurJournalise.Create(AMoteur : TMoteurSequenceur);
      begin
        inherited Create;
        FMoteur := AMoteur;
        FReponsesEnregistrees := TList<Variant>.Create;
      end;

    destructor TMoteurSequenceurJournalise.Destroy;
      begin
        FReponsesEnregistrees.Free;

        inherited;
      end;

    function TMoteurSequenceurJournalise.GetNoeudCourant : TNoeudEtape;
      begin
        Result := FMoteur.NoeudCourant;
      end;

    function TMoteurSequenceurJournalise.Suivant : TNoeudEtape;
      begin
        Result := FMoteur.Suivant;
        if Assigned(Result) then
          Inc(FNombreEtapesTraversees);
      end;

    function TMoteurSequenceurJournalise.Precedent : TNoeudEtape;
      var
        NoeudQuitte : TNoeudEtape;
      begin
        NoeudQuitte := FMoteur.NoeudCourant;
        Result := FMoteur.Precedent;
        if Assigned(Result) then
          begin
            Dec(FNombreEtapesTraversees);
            if Assigned(NoeudQuitte)
               and (NoeudQuitte.TypeNoeud in [ntChoix, ntSaisie])
               and (FReponsesEnregistrees.Count > 0)
            then
              FReponsesEnregistrees.Delete(FReponsesEnregistrees.Count - 1);
          end;
      end;

    procedure TMoteurSequenceurJournalise.EnregistrerReponse(const AValeur : Variant);
      begin
        FMoteur.EnregistrerReponse(AValeur);
        FReponsesEnregistrees.Add(AValeur);
      end;

    function TMoteurSequenceurJournalise.CapturerSession(AContexte : TContextePartie;
                                                         const AFichierContenuActif: string) : TSessionPartie;
      begin
        with Result do
          begin
            NomsJoueursHumains        := AContexte.NomsJoueursHumains;
            Investigateurs            := AContexte.Investigateurs;
            NiveauTerreur             := AContexte.NiveauTerreur;
            NombrePortailsOuverts     := AContexte.NombrePortailsOuverts;
            NombreSignesDesAnciens    := AContexte.NombreSignesDesAnciens;
            EchelleDestin             := AContexte.EchelleDestin;
            TailleEchelleDestin       := AContexte.TailleEchelleDestin;
            TourCourant               := AContexte.TourCourant;
            IndexInvestigateurCourant := AContexte.IndexInvestigateurCourant;
            FichierContenuActif       := AFichierContenuActif;
            NombreEtapesTraversees    := FNombreEtapesTraversees;
            ReponsesEnregistrees      := FReponsesEnregistrees.ToArray;
          end;
      end;

    {$ENDREGION}

    {$REGION 'GestionnaireSession'}

    /// <summary>Sérialise une valeur Variant hétérogène (chaîne ou entier dans cette application) en un couple (Type, Valeur) textuel.</summary>
    procedure EcrireValeurVariant(const AEntree : ISuperObject; const AValeur : Variant);
      begin
        case VarType(AValeur) and varTypeMask of
          varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64 :
            AEntree.S['Type'] := 'Entier';
          varDouble, varSingle, varCurrency:
            AEntree.S['Type'] := 'Reel';
          varBoolean:
            AEntree.S['Type'] := 'Booleen';
          else
            AEntree.S['Type'] := 'Texte';
        end;
        AEntree.S['Valeur'] := VarToStr(AValeur);
      end;

    function LireValeurVariant(const AEntree: ISuperObject): Variant;
      var
        TypeValeur : string;
      begin
        TypeValeur := AEntree.S['Type'];
        if SameText(TypeValeur, 'Entier') then
          Result := StrToInt64(AEntree.S['Valeur'])
        else
          if SameText(TypeValeur, 'Reel') then
            Result := StrToFloat(AEntree.S['Valeur'])
          else
            if SameText(TypeValeur, 'Booleen') then
              Result := StrToBool(AEntree.S['Valeur'])
            else
              Result := AEntree.S['Valeur'];
      end;

    class procedure TGestionnaireSession.SauvegarderDansFichier(const ASession : TSessionPartie;
                                                                const ACheminFichier : string);
      var
        Racine, EntreeInvestigateur, EntreeReponse : ISuperObject;
        Nom : string;
        Investigateur : TInvestigateurJoue;
        Valeur : Variant;
      begin
        Racine := SO;

        Racine.O['NomsJoueursHumains'] := TSuperObject.Create(stArray);
        for Nom in ASession.NomsJoueursHumains do
          Racine.A['NomsJoueursHumains'].Add(SO(Nom));

        Racine.O['Investigateurs'] := TSuperObject.Create(stArray);
        for Investigateur in ASession.Investigateurs do
          begin
            EntreeInvestigateur := SO;
            EntreeInvestigateur.S['NomInvestigateur'] := Investigateur.NomInvestigateur;
            EntreeInvestigateur.I['IndexJoueurHumain'] := Investigateur.IndexJoueurHumain;
            Racine.A['Investigateurs'].Add(EntreeInvestigateur);
          end;

        with Racine, ASession do
          begin
            I['NiveauTerreur']             := NiveauTerreur;
            I['NombrePortailsOuverts']     := NombrePortailsOuverts;
            I['NombreSignesDesAnciens']    := NombreSignesDesAnciens;
            I['EchelleDestin']             := EchelleDestin;
            I['TailleEchelleDestin']       := TailleEchelleDestin;
            I['TourCourant']               := TourCourant;
            I['IndexInvestigateurCourant'] := IndexInvestigateurCourant;
            S['FichierContenuActif']       := FichierContenuActif;
            I['NombreEtapesTraversees']    := NombreEtapesTraversees;
          end;

        Racine.O['ReponsesEnregistrees'] := TSuperObject.Create(stArray);
        for Valeur in ASession.ReponsesEnregistrees do
          begin
            EntreeReponse := SO;
            EcrireValeurVariant(EntreeReponse, Valeur);
            Racine.A['ReponsesEnregistrees'].Add(EntreeReponse);
          end;

        Racine.SaveTo(ACheminFichier);
      end;

    class function TGestionnaireSession.ChargerDepuisFichier(const ACheminFichier : string) : TSessionPartie;
      var
        Racine : ISuperObject;
        TableauNoms, TableauInvestigateurs, TableauReponses : ISuperArray;
        i : Integer;
        Investigateur : TInvestigateurJoue;
      begin
        if not FileExists(ACheminFichier) then
          raise EFileNotFoundException.CreateFmt('Fichier de session introuvable : "%s".',
                                                 [ACheminFichier]);

        Racine := TSuperObject.ParseFile(ACheminFichier, False);
        if not Assigned(Racine) then
          raise ESessionInvalideException.CreateFmt('JSON invalide dans le fichier "%s".',
                                                    [ACheminFichier]);

        if Racine.S['FichierContenuActif'] = EmptyStr then
          raise ESessionInvalideException.CreateFmt(
            'Le fichier "%s" ne précise pas "FichierContenuActif".', [ACheminFichier]);

        TableauNoms := Racine.A['NomsJoueursHumains'];
        if not Assigned(TableauNoms) or (TableauNoms.Length = 0) then
          raise ESessionInvalideException.CreateFmt(
            'Le fichier "%s" ne contient pas de tableau "NomsJoueursHumains" valide.',
            [ACheminFichier]);

        SetLength(Result.NomsJoueursHumains, TableauNoms.Length);
        for i := 0 to TableauNoms.Length - 1 do
          Result.NomsJoueursHumains[i] := TableauNoms.S[i];

        TableauInvestigateurs := Racine.A['Investigateurs'];
        if not Assigned(TableauInvestigateurs) or (TableauInvestigateurs.Length = 0) then
          raise ESessionInvalideException.CreateFmt(
            'Le fichier "%s" ne contient pas de tableau "Investigateurs" valide.',
            [ACheminFichier]);

        SetLength(Result.Investigateurs, TableauInvestigateurs.Length);
        for i := 0 to TableauInvestigateurs.Length - 1 do
          begin
            Investigateur.NomInvestigateur := TableauInvestigateurs.O[i].S['NomInvestigateur'];
            Investigateur.IndexJoueurHumain := TableauInvestigateurs.O[i].I['IndexJoueurHumain'];
            Result.Investigateurs[i] := Investigateur;
          end;

        with Result, Racine do
          begin
            NiveauTerreur             := I['NiveauTerreur'];
            NombrePortailsOuverts     := I['NombrePortailsOuverts'];
            NombreSignesDesAnciens    := I['NombreSignesDesAnciens'];
            EchelleDestin             := I['EchelleDestin'];
            TailleEchelleDestin       := I['TailleEchelleDestin'];
            TourCourant               := I['TourCourant'];
            IndexInvestigateurCourant := I['IndexInvestigateurCourant'];
            FichierContenuActif       := S['FichierContenuActif'];
            NombreEtapesTraversees    := I['NombreEtapesTraversees'];
          end;

        TableauReponses := Racine.A['ReponsesEnregistrees'];
        if Assigned(TableauReponses) then
          begin
            SetLength(Result.ReponsesEnregistrees, TableauReponses.Length);
            for i := 0 to TableauReponses.Length - 1 do
              Result.ReponsesEnregistrees[i] := LireValeurVariant(TableauReponses.O[i]);
          end
        else
          SetLength(Result.ReponsesEnregistrees, 0);
      end;

    class function TGestionnaireSession.RecreerContexte(const ASession : TSessionPartie) : TContextePartie;
      begin
        Result := TContextePartie.Create(ASession.NomsJoueursHumains, ASession.Investigateurs);
        with Result do
          begin
            NiveauTerreur := ASession.NiveauTerreur;
            NombrePortailsOuverts := ASession.NombrePortailsOuverts;
            NombreSignesDesAnciens := ASession.NombreSignesDesAnciens;
            EchelleDestin := ASession.EchelleDestin;
            TailleEchelleDestin := ASession.TailleEchelleDestin;
            TourCourant := ASession.TourCourant;
            IndexInvestigateurCourant := ASession.IndexInvestigateurCourant;
          end;
      end;

    class procedure TGestionnaireSession.RestaurerPosition(AMoteur : TMoteurSequenceurJournalise;
                                                           const ASession : TSessionPartie);
      var
        i, IndexReponse : Integer;
        Noeud : TNoeudEtape;
      begin
        IndexReponse := 0;
        for i := 1 to ASession.NombreEtapesTraversees do
          begin
            Noeud := AMoteur.Suivant;
            if not Assigned(Noeud) then
              raise ESessionInvalideException.CreateFmt(
                'Le contenu rechargé ne contient plus assez d''étapes pour restaurer la session ' +
                '(arrêt après %d étape(s) sur %d attendues) : les fichiers de contenu ont probablement changé depuis la sauvegarde.',
                [i - 1, ASession.NombreEtapesTraversees]);

            if (i < ASession.NombreEtapesTraversees)
               and (Noeud.TypeNoeud in [ntChoix, ntSaisie])
            then
              begin
                if IndexReponse >= Length(ASession.ReponsesEnregistrees) then
                  raise ESessionInvalideException.Create(
                    'Le contenu rechargé attend plus de réponses que la session n''en contient : ' +
                    'les fichiers de contenu ont probablement changé depuis la sauvegarde.');
                AMoteur.EnregistrerReponse(ASession.ReponsesEnregistrees[IndexReponse]);
                Inc(IndexReponse);
              end;
          end;
      end;

    {$ENDREGION}

end.
