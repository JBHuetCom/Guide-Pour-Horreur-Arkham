unit AH.UI.FrmNouvellePartie;

  interface

    uses
      System.SysUtils, System.Classes, System.Generics.Collections,
      Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs,
      AH.Core.Contexte, AH.Core.Capacites, AH.Core.ConstructeurPartie;

    type

      /// <summary>Étape courante de l'assistant de configuration d'une nouvelle partie.</summary>
      TEtapeAssistant = (eaJoueursHumains, eaInvestigateurs);

      /// <summary>
      /// Assistant de configuration d'une nouvelle partie : saisie des joueurs humains (1 à
      /// NombreMaxJoueursHumains) puis des investigateurs qu'ils contrôlent (1 à
      /// NombreMaxInvestigateurs, un joueur humain pouvant en contrôler plusieurs). Produit un
      /// TContextePartie prêt à l'emploi, accessible via ContextePartieCreee après un ShowModal
      /// ayant retourné mrOk.
      /// </summary>
      TFrmNouvellePartie = class(TForm)
        private
          FEtapeCourante : TEtapeAssistant;

          FNomsJoueursHumains : TList<string>;
          /// <summary>Investigateurs ajoutés, dans l'ordre de saisie (réordonnés par TConstructeurPartie au moment de valider).</summary>
          FInvestigateurs : TList<TInvestigateurJoue>;

          FPanelJoueurs : TPanel;
          FPanelInvestigateurs : TPanel;
          FLabelTitre : TLabel;
          FLabelErreur : TLabel;
          FBoutonPrecedent : TButton;
          FBoutonSuivant : TButton;
          FEditNomJoueur : TEdit;
          FBoutonAjouterJoueur : TButton;
          FBoutonSupprimerJoueur : TButton;
          FListeJoueurs : TListBox;
          FComboNomInvestigateur : TComboBox;
          FComboJoueurControleur : TComboBox;
          FBoutonAjouterInvestigateur : TButton;
          FBoutonSupprimerInvestigateur : TButton;
          FListeInvestigateurs : TListBox;

          FGestionnaireCapacites : TGestionnaireCapacites;
          FContextePartieCreee : TContextePartie;

          procedure ConstruireControles;
          procedure AfficherEtape(AEtape: TEtapeAssistant);
          procedure RafraichirListeJoueurs;
          procedure RafraichirListeInvestigateurs;
          procedure RafraichirComboJoueurControleur;
          procedure RafraichirEtatBoutons;
          procedure AfficherErreur(const AMessage : string);

          procedure GererClicAjouterJoueur(ASender : TObject);
          procedure GererClicSupprimerJoueur(ASender : TObject);
          procedure GererClicAjouterInvestigateur(ASender : TObject);
          procedure GererClicSupprimerInvestigateur(ASender : TObject);
          procedure GererClicPrecedent(ASender : TObject);
          procedure GererClicSuivant(ASender : TObject);
          procedure GererSelectionListe(ASender : TObject);

          /// <summary>Valide les deux étapes puis construit le TContextePartie dans l'ordre de jeu correct.</summary>
          /// <param name="OContexte">Contexte créé si la fonction retourne True. Non affecté sinon.</param>
          /// <param name="OMessageErreur">Message à afficher à l'utilisateur si la fonction retourne False.</param>
          function TenterCreerContextePartie(out OContexte : TContextePartie; out OMessageErreur : string) : Boolean;
        public
          /// <param name="AOwner">Propriétaire standard VCL du formulaire.</param>
          /// <param name="ACheminCapacitesInvestigateurs">
          /// Chemin du fichier capacites_investigateurs.json, utilisé pour préremplir la liste des
          /// noms d'investigateurs proposés. Facultatif (EmptyStr pour ne pas préremplir) : un nom
          /// hors liste reste saisissable librement, mais choisir un nom de cette liste garantit la
          /// correspondance avec le panneau de capacité affiché en jeu.
          /// </param>
          constructor Create(AOwner : TComponent; const ACheminCapacitesInvestigateurs : string); reintroduce;
          destructor Destroy; override;

          /// <summary>
          /// Partie configurée, disponible uniquement après un ShowModal ayant retourné mrOk.
          /// L'appelant en devient propriétaire : ce formulaire ne la libère jamais.
          /// </summary>
          property ContextePartieCreee : TContextePartie read FContextePartieCreee;
      end;

  implementation

    uses

      System.UITypes;

    { TFrmNouvellePartie }

    constructor TFrmNouvellePartie.Create(AOwner : TComponent; const ACheminCapacitesInvestigateurs : string);
      begin
        inherited Create(AOwner);

        FNomsJoueursHumains := TList<string>.Create;
        FInvestigateurs := TList<TInvestigateurJoue>.Create;
        FGestionnaireCapacites := TGestionnaireCapacites.Create;

        if ACheminCapacitesInvestigateurs <> EmptyStr then
          try
            FGestionnaireCapacites.ChargerDepuisFichier(ACheminCapacitesInvestigateurs);
          except
            // Le préremplissage des noms est un confort, pas une nécessité : un fichier absent ou
            // invalide ne doit pas empêcher l'assistant de démarrer, la saisie libre reste possible.
          end;

        ConstruireControles;
        AfficherEtape(eaJoueursHumains);
      end;

    destructor TFrmNouvellePartie.Destroy;
      begin
        FGestionnaireCapacites.Free;
        FInvestigateurs.Free;
        FNomsJoueursHumains.Free;

        inherited;
      end;

    procedure TFrmNouvellePartie.ConstruireControles;
      var
        Nom: string;
      begin
        Caption := 'Nouvelle partie';
        Position := poScreenCenter;
        BorderStyle := bsDialog;
        ClientWidth := 532;
        ClientHeight := 412;

        FLabelTitre := TLabel.Create(Self);
        FLabelTitre.Parent := Self;
        FLabelTitre.SetBounds(12, 12, 496, 24);
        FLabelTitre.Font.Style := [fsBold];
        FLabelTitre.Font.Size := 14;

        FPanelJoueurs := TPanel.Create(Self);
        FPanelJoueurs.Parent := Self;
        FPanelJoueurs.SetBounds(12, 48, 496, 280);
        FPanelJoueurs.BevelOuter := bvNone;

        FPanelInvestigateurs := TPanel.Create(Self);
        FPanelInvestigateurs.Parent := Self;
        FPanelInvestigateurs.SetBounds(12, 48, 496, 280);
        FPanelInvestigateurs.BevelOuter := bvNone;

        // --- Étape "Joueurs humains" ---
        with TLabel.Create(Self) do
          begin
            Parent := FPanelJoueurs;
            SetBounds(0, 0, 496, 20);
            Caption := 'Ajoutez chaque joueur humain autour de la table.';
          end;

        FEditNomJoueur := TEdit.Create(Self);
        FEditNomJoueur.Parent := FPanelJoueurs;
        FEditNomJoueur.SetBounds(0, 28, 300, 24);

        FBoutonAjouterJoueur := TButton.Create(Self);
        FBoutonAjouterJoueur.Parent := FPanelJoueurs;
        FBoutonAjouterJoueur.SetBounds(308, 27, 100, 26);
        FBoutonAjouterJoueur.Caption := 'Ajouter';
        FBoutonAjouterJoueur.OnClick := GererClicAjouterJoueur;

        FListeJoueurs := TListBox.Create(Self);
        FListeJoueurs.Parent := FPanelJoueurs;
        FListeJoueurs.SetBounds(0, 64, 300, 200);
        FListeJoueurs.OnClick := GererSelectionListe;

        FBoutonSupprimerJoueur := TButton.Create(Self);
        FBoutonSupprimerJoueur.Parent := FPanelJoueurs;
        FBoutonSupprimerJoueur.SetBounds(308, 64, 100, 26);
        FBoutonSupprimerJoueur.Caption := 'Supprimer';
        FBoutonSupprimerJoueur.OnClick := GererClicSupprimerJoueur;

        // --- Étape "Investigateurs" ---
        with TLabel.Create(Self) do
        begin
          Parent := FPanelInvestigateurs;
          SetBounds(0, 0, 496, 20);
          Caption := 'Ajoutez chaque investigateur en jeu et indiquez qui le contrôle.';
        end;

        FComboNomInvestigateur := TComboBox.Create(Self);
        FComboNomInvestigateur.Parent := FPanelInvestigateurs;
        FComboNomInvestigateur.SetBounds(0, 28, 220, 24);
        FComboNomInvestigateur.Style := csDropDown;
        for Nom in FGestionnaireCapacites.NomsConnus do
          FComboNomInvestigateur.Items.Add(Nom);

        FComboJoueurControleur := TComboBox.Create(Self);
        FComboJoueurControleur.Parent := FPanelInvestigateurs;
        FComboJoueurControleur.SetBounds(228, 28, 150, 24);
        FComboJoueurControleur.Style := csDropDownList;

        FBoutonAjouterInvestigateur := TButton.Create(Self);
        FBoutonAjouterInvestigateur.Parent := FPanelInvestigateurs;
        FBoutonAjouterInvestigateur.SetBounds(388, 27, 100, 26);
        FBoutonAjouterInvestigateur.Caption := 'Ajouter';
        FBoutonAjouterInvestigateur.OnClick := GererClicAjouterInvestigateur;

        FListeInvestigateurs := TListBox.Create(Self);
        FListeInvestigateurs.Parent := FPanelInvestigateurs;
        FListeInvestigateurs.SetBounds(0, 64, 380, 200);
        FListeInvestigateurs.OnClick := GererSelectionListe;

        FBoutonSupprimerInvestigateur := TButton.Create(Self);
        FBoutonSupprimerInvestigateur.Parent := FPanelInvestigateurs;
        FBoutonSupprimerInvestigateur.SetBounds(388, 64, 100, 26);
        FBoutonSupprimerInvestigateur.Caption := 'Supprimer';
        FBoutonSupprimerInvestigateur.OnClick := GererClicSupprimerInvestigateur;

        // --- Pied de formulaire (commun aux deux étapes) ---
        FLabelErreur := TLabel.Create(Self);
        FLabelErreur.Parent := Self;
        FLabelErreur.SetBounds(12, 336, 496, 20);
        FLabelErreur.Font.Color := clRed;

        FBoutonPrecedent := TButton.Create(Self);
        FBoutonPrecedent.Parent := Self;
        FBoutonPrecedent.SetBounds(12, 372, 110, 28);
        FBoutonPrecedent.Caption := '< Précédent';
        FBoutonPrecedent.OnClick := GererClicPrecedent;

        FBoutonSuivant := TButton.Create(Self);
        FBoutonSuivant.Parent := Self;
        FBoutonSuivant.SetBounds(398, 372, 110, 28);
        FBoutonSuivant.OnClick := GererClicSuivant;
        FBoutonSuivant.Default := True;
      end;

    procedure TFrmNouvellePartie.AfficherEtape(AEtape : TEtapeAssistant);
      begin
        FEtapeCourante := AEtape;

        FPanelJoueurs.Visible := AEtape = eaJoueursHumains;
        FPanelInvestigateurs.Visible := AEtape = eaInvestigateurs;

        case AEtape of
          eaJoueursHumains : FLabelTitre.Caption := 'Étape 1 / 2 — Joueurs humains';
          eaInvestigateurs :
            begin
              FLabelTitre.Caption := 'Étape 2 / 2 — Investigateurs';
              RafraichirComboJoueurControleur;
            end;
        end;

        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.RafraichirListeJoueurs;
      var
        Nom : string;
      begin
        FListeJoueurs.Items.BeginUpdate;
        try
          FListeJoueurs.Items.Clear;
          for Nom in FNomsJoueursHumains do
            FListeJoueurs.Items.Add(Nom);
        finally
          FListeJoueurs.Items.EndUpdate;
        end;
      end;

    procedure TFrmNouvellePartie.RafraichirListeInvestigateurs;
      var
        Investigateur : TInvestigateurJoue;
      begin
        FListeInvestigateurs.Items.BeginUpdate;
        try
          FListeInvestigateurs.Items.Clear;
          for Investigateur in FInvestigateurs do
            FListeInvestigateurs.Items.Add(Format('%s — joué par %s',
              [Investigateur.NomInvestigateur, FNomsJoueursHumains[Investigateur.IndexJoueurHumain]]));
        finally
          FListeInvestigateurs.Items.EndUpdate;
        end;
      end;

    procedure TFrmNouvellePartie.RafraichirComboJoueurControleur;
      var
        Nom : string;
        IndexPrecedent : Integer;
      begin
        IndexPrecedent := FComboJoueurControleur.ItemIndex;
        FComboJoueurControleur.Items.BeginUpdate;
        try
          FComboJoueurControleur.Items.Clear;
          for Nom in FNomsJoueursHumains do
            FComboJoueurControleur.Items.Add(Nom);
        finally
          FComboJoueurControleur.Items.EndUpdate;
        end;
        if IndexPrecedent < FComboJoueurControleur.Items.Count then
          FComboJoueurControleur.ItemIndex := IndexPrecedent
        else if FComboJoueurControleur.Items.Count > 0 then
          FComboJoueurControleur.ItemIndex := 0;
      end;

    procedure TFrmNouvellePartie.RafraichirEtatBoutons;
      begin
        FBoutonPrecedent.Enabled := FEtapeCourante = eaInvestigateurs;

        case FEtapeCourante of
          eaJoueursHumains:
            begin
              FBoutonSuivant.Caption := 'Suivant >';
              FBoutonSuivant.Enabled := FNomsJoueursHumains.Count > 0;
              FBoutonAjouterJoueur.Enabled := FNomsJoueursHumains.Count < NombreMaxJoueursHumains;
            end;
          eaInvestigateurs:
            begin
              FBoutonSuivant.Caption := 'Créer la partie';
              FBoutonSuivant.Enabled := FInvestigateurs.Count > 0;
              FBoutonAjouterInvestigateur.Enabled := FInvestigateurs.Count < NombreMaxInvestigateurs;
            end;
        end;

        FBoutonSupprimerJoueur.Enabled := FListeJoueurs.ItemIndex >= 0;
        FBoutonSupprimerInvestigateur.Enabled := FListeInvestigateurs.ItemIndex >= 0;
      end;

    procedure TFrmNouvellePartie.AfficherErreur(const AMessage : string);
      begin
        FLabelErreur.Caption := AMessage;
      end;

    procedure TFrmNouvellePartie.GererSelectionListe(ASender : TObject);
      begin
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicAjouterJoueur(ASender : TObject);
      var
        Nom, NomExistant: string;
      begin
        Nom := Trim(FEditNomJoueur.Text);
        if Nom = EmptyStr then
          begin
            AfficherErreur('Saisissez un prénom avant de l''ajouter.');
            Exit;
          end;

        if FNomsJoueursHumains.Count >= NombreMaxJoueursHumains then
          begin
            AfficherErreur(Format('Maximum de %d joueurs humains atteint.', [NombreMaxJoueursHumains]));
            Exit;
          end;

        for NomExistant in FNomsJoueursHumains do
          if SameText(NomExistant, Nom) then
            begin
              AfficherErreur('Ce prénom est déjà utilisé par un autre joueur.');
              Exit;
            end;

        FNomsJoueursHumains.Add(Nom);
        FEditNomJoueur.Clear;
        FEditNomJoueur.SetFocus;
        RafraichirListeJoueurs;
        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicSupprimerJoueur(ASender : TObject);
      var
        IndexJoueurSupprime, NombreInvestigateursTouches : Integer;
        Investigateur : TInvestigateurJoue;
      begin
        IndexJoueurSupprime := FListeJoueurs.ItemIndex;
        if IndexJoueurSupprime < 0 then
          Exit;

        NombreInvestigateursTouches := 0;
        for Investigateur in FInvestigateurs do
          if Investigateur.IndexJoueurHumain = IndexJoueurSupprime then
            Inc(NombreInvestigateursTouches);

        if NombreInvestigateursTouches > 0 then
          if MessageDlg(
               Format('Ce joueur contrôle %d investigateur(s). Les retirer également ?', [NombreInvestigateursTouches]),
               mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
            Exit;

        TConstructeurPartie.SupprimerJoueurEtRepercuter(FInvestigateurs, IndexJoueurSupprime);
        FNomsJoueursHumains.Delete(IndexJoueurSupprime);

        RafraichirListeJoueurs;
        RafraichirListeInvestigateurs;
        RafraichirComboJoueurControleur;
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicAjouterInvestigateur(ASender : TObject);
      var
        Nom : string;
        NouvelInvestigateur : TInvestigateurJoue;
      begin
        Nom := Trim(FComboNomInvestigateur.Text);
        if Nom = EmptyStr then
          begin
            AfficherErreur('Saisissez ou choisissez un nom d''investigateur avant de l''ajouter.');
            Exit;
          end;

        if FComboJoueurControleur.ItemIndex < 0 then
          begin
            AfficherErreur('Choisissez le joueur humain qui contrôle cet investigateur.');
            Exit;
          end;

        if FInvestigateurs.Count >= NombreMaxInvestigateurs then
          begin
            AfficherErreur(Format('Maximum de %d investigateurs atteint.', [NombreMaxInvestigateurs]));
            Exit;
          end;

        if TConstructeurPartie.NomDejaUtilise(FInvestigateurs.ToArray, Nom) then
          begin
            AfficherErreur('Cet investigateur est déjà en jeu : un seul joueur peut le contrôler à la fois.');
            Exit;
          end;

        NouvelInvestigateur.NomInvestigateur := Nom;
        NouvelInvestigateur.IndexJoueurHumain := FComboJoueurControleur.ItemIndex;
        FInvestigateurs.Add(NouvelInvestigateur);

        FComboNomInvestigateur.Text := EmptyStr;
        RafraichirListeInvestigateurs;
        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicSupprimerInvestigateur(ASender : TObject);
      begin
        if FListeInvestigateurs.ItemIndex < 0 then
          Exit;

        FInvestigateurs.Delete(FListeInvestigateurs.ItemIndex);
        RafraichirListeInvestigateurs;
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicPrecedent(ASender : TObject);
      begin
        AfficherEtape(eaJoueursHumains);
      end;

    procedure TFrmNouvellePartie.GererClicSuivant(ASender : TObject);
      var
        Contexte : TContextePartie;
        MessageErreur : string;
      begin
        case FEtapeCourante of
          eaJoueursHumains :
            AfficherEtape(eaInvestigateurs);
          eaInvestigateurs :
            begin
              if not TenterCreerContextePartie(Contexte, MessageErreur) then
                begin
                  AfficherErreur(MessageErreur);
                  Exit;
                end;
              FContextePartieCreee := Contexte;
              ModalResult := mrOk;
            end;
        end;
      end;

    function TFrmNouvellePartie.TenterCreerContextePartie(out OContexte : TContextePartie;
                                                          out OMessageErreur : string) : Boolean;
      var
        InvestigateursOrdonnes: TArray<TInvestigateurJoue>;
      begin
        OContexte := nil;
        OMessageErreur := EmptyStr;

        if FNomsJoueursHumains.Count = 0 then
          begin
            OMessageErreur := 'Ajoutez au moins un joueur humain.';
            Exit(False);
          end;

        if FInvestigateurs.Count = 0 then
          begin
            OMessageErreur := 'Ajoutez au moins un investigateur.';
            Exit(False);
          end;

        InvestigateursOrdonnes := TConstructeurPartie.OrdonnerParJoueur(
          FNomsJoueursHumains.ToArray, FInvestigateurs.ToArray);
        OContexte := TContextePartie.Create(FNomsJoueursHumains.ToArray, InvestigateursOrdonnes);
        Result := True;
      end;

end.
