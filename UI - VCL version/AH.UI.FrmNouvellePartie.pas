unit AH.UI.FrmNouvellePartie;

  interface

    uses

      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Generics.Collections,
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
          procedure FormDestroy(Sender: TObject);
          procedure FormCreate(Sender: TObject);
        private
          FEtapeCourante : TEtapeAssistant;

          FNomsJoueursHumains : TList<string>;
          /// <summary>Investigateurs ajoutés, dans l'ordre de saisie (réordonnés par TConstructeurPartie au moment de valider).</summary>
          FInvestigateurs : TList<TInvestigateurJoue>;

          FGestionnaireCapacites : TGestionnaireCapacites;
          FContextePartieCreee : TContextePartie;

          /// <summary>Liste des noms d'investigateurs disponibles (non encore attribués à un joueur).</summary>
          FInvestigateursDisponibles : TList<string>;

          procedure AfficherEtape(AEtape : TEtapeAssistant);
          procedure RafraichirListeJoueurs;
          procedure RafraichirListeInvestigateurs;
          procedure RafraichirComboJoueurControleur;
          procedure RafraichirEtatBoutons;
          procedure AfficherErreur(const AMessage : string);

          /// <summary>Valide les deux étapes puis construit le TContextePartie dans l'ordre de jeu correct.</summary>
          /// <param name="OContexte">Contexte créé si la fonction retourne True. Non affecté sinon.</param>
          /// <param name="OMessageErreur">Message à afficher à l'utilisateur si la fonction retourne False.</param>
          function TenterCreerContextePartie(out OContexte : TContextePartie; out OMessageErreur : string) : Boolean;

          /// <summary>
          /// Met à jour ComboNomInvestigateur avec uniquement les investigateurs disponibles
          /// (non encore attribués à un joueur).
          /// </summary>
          procedure RafraichirInvestigateursDisponibles;
        public
          /// <summary>
          /// Partie configurée, disponible uniquement après un ShowModal ayant retourné mrOk.
          /// L'appelant en devient propriétaire : ce formulaire ne la libère jamais.
          /// </summary>
          property ContextePartieCreee : TContextePartie read FContextePartieCreee;
        published
          LabelTitre : TLabel;
          PanelJoueurs : TPanel;
          PanelInvestigateurs : TPanel;
          LabelErreur : TLabel;
          BoutonPrecedent : TButton;
          BoutonSuivant : TButton;
          EditNomJoueur : TEdit;
          BoutonAjouterJoueur : TButton;
          BoutonSupprimerJoueur : TButton;
          ListeJoueurs : TListBox;
          ComboNomInvestigateur : TComboBox;
          ComboJoueurControleur : TComboBox;
          BoutonAjouterInvestigateur : TButton;
          BoutonSupprimerInvestigateur : TButton;
          ListeInvestigateurs : TListBox;
          Label1 : TLabel;
          Label2 : TLabel;

          procedure FormShow(Sender : TObject);

          procedure GererClicAjouterJoueur(ASender : TObject);
          procedure GererClicSupprimerJoueur(ASender : TObject);
          procedure GererClicAjouterInvestigateur(ASender : TObject);
          procedure GererClicSupprimerInvestigateur(ASender : TObject);
          procedure GererClicPrecedent(ASender : TObject);
          procedure GererClicSuivant(ASender : TObject);
          procedure GererSelectionListe(ASender : TObject);
      end;

    var

      FrmNouvellePartie : TFrmNouvellePartie;

  implementation

    uses
      System.UITypes,
      AH.UI.FrmInitialisationPartie;

    {$R *.dfm}

    { TFrmNouvellePartie }

    procedure TFrmNouvellePartie.FormCreate(Sender : TObject);
      begin
        FNomsJoueursHumains := TList<string>.Create;
        FInvestigateurs := TList<TInvestigateurJoue>.Create;
        FGestionnaireCapacites := TGestionnaireCapacites.Create;
        FInvestigateursDisponibles := TList<string>.Create;

          // Charger le JSON une seule fois
        var CheminJSON : string := ExtractFilePath(Application.ExeName) + 'Data\Content\capacites_investigateurs.json';
        try
          FGestionnaireCapacites.ChargerDepuisFichier(CheminJSON);
          FInvestigateursDisponibles.AddRange(FGestionnaireCapacites.NomsConnus);
        except
          // Le préremplissage des noms est un confort, pas une nécessité : un fichier absent ou
          // invalide ne doit pas empêcher l'assistant de démarrer, la saisie libre reste possible.
        end;

        // Initialiser l'UI
        AfficherEtape(eaJoueursHumains);
      end;

    procedure TFrmNouvellePartie.FormDestroy(Sender: TObject);
      begin
        FGestionnaireCapacites.Free;
        FInvestigateurs.Free;
        FNomsJoueursHumains.Free;
        FInvestigateursDisponibles.Free;
      end;

    procedure TFrmNouvellePartie.FormShow(Sender : TObject);
      var
        CheminDefaut : string;
      begin
        // Vérifier que les composants critiques existent
        if not Assigned(ComboNomInvestigateur) then
          begin
            ShowMessage('Erreur: ComboNomInvestigateur non créé.');
            ModalResult := mrCancel;
            Exit;
          end;

        // Rafraîchir la combo
        RafraichirInvestigateursDisponibles;
      end;

    procedure TFrmNouvellePartie.AfficherEtape(AEtape : TEtapeAssistant);
      begin
        FEtapeCourante := AEtape;

        PanelJoueurs.Visible := (AEtape = eaJoueursHumains);
        PanelInvestigateurs.Visible := (AEtape = eaInvestigateurs);

        case AEtape of
          eaJoueursHumains : LabelTitre.Caption := 'Étape 1 / 2 — Joueurs humains';
          eaInvestigateurs :
            begin
              LabelTitre.Caption := 'Étape 2 / 2 — Investigateurs';
              RafraichirComboJoueurControleur;
              RafraichirInvestigateursDisponibles;
            end;
        end;

        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.RafraichirListeJoueurs;
      var
        Nom : string;
      begin
        ListeJoueurs.Items.BeginUpdate;
        try
          ListeJoueurs.Items.Clear;
          for Nom in FNomsJoueursHumains do
            ListeJoueurs.Items.Add(Nom);
        finally
          ListeJoueurs.Items.EndUpdate;
        end;
      end;

    procedure TFrmNouvellePartie.RafraichirListeInvestigateurs;
      var
        Investigateur : TInvestigateurJoue;
      begin
        ListeInvestigateurs.Items.BeginUpdate;
        try
          ListeInvestigateurs.Items.Clear;
          for Investigateur in FInvestigateurs do
            ListeInvestigateurs.Items.Add(Format('%s — joué par %s',
              [Investigateur.NomInvestigateur, FNomsJoueursHumains[Investigateur.IndexJoueurHumain]]));
        finally
          ListeInvestigateurs.Items.EndUpdate;
        end;
      end;

    procedure TFrmNouvellePartie.RafraichirComboJoueurControleur;
      var
        Nom : string;
        IndexPrecedent : Integer;
      begin
        IndexPrecedent := ComboJoueurControleur.ItemIndex;
        ComboJoueurControleur.Items.BeginUpdate;
        try
          ComboJoueurControleur.Items.Clear;
          for Nom in FNomsJoueursHumains do
            ComboJoueurControleur.Items.Add(Nom);
        finally
          ComboJoueurControleur.Items.EndUpdate;
        end;
        if IndexPrecedent < ComboJoueurControleur.Items.Count then
          ComboJoueurControleur.ItemIndex := IndexPrecedent
        else if ComboJoueurControleur.Items.Count > 0 then
          ComboJoueurControleur.ItemIndex := 0;
      end;

    procedure TFrmNouvellePartie.RafraichirEtatBoutons;
      begin
        BoutonPrecedent.Enabled := FEtapeCourante = eaInvestigateurs;

        case FEtapeCourante of
          eaJoueursHumains :
            begin
              BoutonSuivant.Caption := 'Suivant >';
              BoutonSuivant.Enabled := FNomsJoueursHumains.Count > 0;
              BoutonAjouterJoueur.Enabled := FNomsJoueursHumains.Count < NombreMaxJoueursHumains;
            end;
          eaInvestigateurs :
            begin
              BoutonSuivant.Caption := 'Créer la partie';
              BoutonSuivant.Enabled := FInvestigateurs.Count > 0;
              BoutonAjouterInvestigateur.Enabled := FInvestigateurs.Count < NombreMaxInvestigateurs;
            end;
        end;

        BoutonSupprimerJoueur.Enabled := ListeJoueurs.ItemIndex >= 0;
        BoutonSupprimerInvestigateur.Enabled := ListeInvestigateurs.ItemIndex >= 0;
      end;

    procedure TFrmNouvellePartie.AfficherErreur(const AMessage : string);
      begin
        LabelErreur.Caption := AMessage;
      end;

    procedure TFrmNouvellePartie.GererSelectionListe(ASender : TObject);
      begin
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicAjouterJoueur(ASender : TObject);
      var
        Nom, NomExistant : string;
      begin
        Nom := Trim(EditNomJoueur.Text);
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
        EditNomJoueur.Clear;
        EditNomJoueur.SetFocus;
        RafraichirListeJoueurs;
        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicSupprimerJoueur(ASender : TObject);
      var
        IndexJoueurSupprime, NombreInvestigateursTouches : Integer;
        Investigateur : TInvestigateurJoue;
      begin
        IndexJoueurSupprime := ListeJoueurs.ItemIndex;
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
        RafraichirInvestigateursDisponibles;
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicAjouterInvestigateur(ASender : TObject);
      var
        Nom : string;
        NouvelInvestigateur : TInvestigateurJoue;
      begin
        Nom := Trim(ComboNomInvestigateur.Text);
        if Nom = EmptyStr then
          begin
            AfficherErreur('Saisissez ou choisissez un nom d''investigateur avant de l''ajouter.');
            Exit;
          end;

        if ComboJoueurControleur.ItemIndex < 0 then
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
        NouvelInvestigateur.IndexJoueurHumain := ComboJoueurControleur.ItemIndex;
        FInvestigateurs.Add(NouvelInvestigateur);

        ComboNomInvestigateur.Text := EmptyStr;
        RafraichirListeInvestigateurs;
        RafraichirInvestigateursDisponibles;
        AfficherErreur(EmptyStr);
        RafraichirEtatBoutons;
      end;

    procedure TFrmNouvellePartie.GererClicSupprimerInvestigateur(ASender : TObject);
      begin
        if ListeInvestigateurs.ItemIndex < 0 then
          Exit;

        FInvestigateurs.Delete(ListeInvestigateurs.ItemIndex);
        RafraichirListeInvestigateurs;
        RafraichirInvestigateursDisponibles;
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
          eaJoueursHumains:
            AfficherEtape(eaInvestigateurs);
          eaInvestigateurs:
            begin
              if not TenterCreerContextePartie(Contexte, MessageErreur) then
                begin
                  AfficherErreur(MessageErreur);
                  Exit;
                end;

              FrmInitialisationPartie.ContextePartie := Contexte;
              Self.Hide;
              FrmInitialisationPartie.Show;
            end;
        end;
      end;

    function TFrmNouvellePartie.TenterCreerContextePartie(out OContexte : TContextePartie;
                                                          out OMessageErreur : string) : Boolean;
      var
        InvestigateursOrdonnes : TArray<TInvestigateurJoue>;
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

    procedure TFrmNouvellePartie.RafraichirInvestigateursDisponibles;
      var
        Investigateur: TInvestigateurJoue;
      begin
        ComboNomInvestigateur.Items.BeginUpdate;
        try
          ComboNomInvestigateur.Items.Clear;

          // Ajouter tous les investigateurs connus non encore attribués
          for var Nom in FInvestigateursDisponibles do
            if not TConstructeurPartie.NomDejaUtilise(FInvestigateurs.ToArray, Nom) then
              ComboNomInvestigateur.Items.Add(Nom);
        finally
          ComboNomInvestigateur.Items.EndUpdate;
        end;
      end;

end.