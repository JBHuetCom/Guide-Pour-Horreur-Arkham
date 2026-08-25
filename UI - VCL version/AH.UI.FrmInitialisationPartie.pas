unit AH.UI.FrmInitialisationPartie;

  interface

    uses
      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Generics.Collections,
      Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs, Vcl.ImgList,
      AH.Core.Contexte, AH.Core.GrandsAnciens;

    type
      /// <summary>
      /// Formulaire d'initialisation des paramètres de la partie après la sélection des joueurs et investigateurs.
      /// Permet de :
      /// - Sélectionner le Grand Ancien et afficher son illustration.
      /// - Renseigner la taille de son échelle du destin (préremplie depuis le JSON).
      /// - Choisir l'investigateur de départ.
      /// - Initialiser les compteurs (NiveauTerreur, PortailsOuverts, etc.).
      /// </summary>
      TFrmInitialisationPartie = class(TForm)
        private
          FContextePartie : TContextePartie;
          FGestionnaireGrandsAnciens : TGestionnaireGrandsAnciens;
          FImageListGrandsAnciens : TImageList;

          /// <summary>
          /// Charge les images des Grands Anciens dans l'ImageList.
          /// Les images doivent être dans Data\Content\Images\ (ou un sous-dossier dédié).
          /// </summary>
          procedure ChargerImagesGrandsAnciens;
          /// <summary>
          /// Remplit ComboInvestigateurDepart avec les noms des investigateurs du contexte.
          /// </summary>
          procedure RafraichirListeInvestigateurs;
          /// <summary>
          /// Met à jour l'aperçu du Grand Ancien sélectionné (image + taille de l'échelle du destin + règles).
          /// </summary>
          procedure RafraichirApercuGrandAncien;
          /// <summary>Valide les saisies et complète le contexte de partie.</summary>
          procedure ValiderEtFermer;
        public
          /// <summary>
          /// Contexte de partie complété, disponible uniquement après un ShowModal ayant retourné mrOk.
          /// </summary>
          property ContextePartie : TContextePartie read FContextePartie write FContextePartie;
        published
          LabelTitre : TLabel;
          PanelGrandAncien : TPanel;
          LabelGrandAncien : TLabel;
          ComboGrandAncien : TComboBox;
          ImageGrandAncien : TImage;
          LabelTailleEchelleDestin : TLabel;
          EditTailleEchelleDestin : TEdit;
          LabelInvestigateurDepart : TLabel;
          ComboInvestigateurDepart : TComboBox;
          PanelReglesSpeciales : TPanel;
          LabelReglesEnSommeil : TLabel;
          LabelReglesSpecial : TLabel;
          LabelReglesAdorateurs : TLabel;
          LabelReglesBataille : TLabel;
          BoutonOK : TButton;
          BoutonAnnuler : TButton;

          procedure FormCreate(Sender : TObject);
          procedure FormDestroy(Sender : TObject);
          procedure FormShow(Sender : TObject);
          procedure ComboGrandAncienChange(Sender : TObject);
          procedure BoutonOKClick(Sender : TObject);
      end;

    var
      FrmInitialisationPartie : TFrmInitialisationPartie;

  implementation

    uses

      System.UITypes, System.ImageList;

    {$R *.dfm}

    { TFrmNouvellePartie }

    procedure TFrmInitialisationPartie.FormDestroy(Sender : TObject);
      begin
        FGestionnaireGrandsAnciens.Free;
        FImageListGrandsAnciens.Free;
      end;

    procedure TFrmInitialisationPartie.ChargerImagesGrandsAnciens;
      var
        GrandAncien : TGrandAncien;
        CheminImage : string;
      begin
        for GrandAncien in FGestionnaireGrandsAnciens.Noms do
          begin
            if GrandAncien.Image <> EmptyStr then
              begin
                CheminImage := ExtractFilePath(Application.ExeName) + 'Data\Content\Images\' + GrandAncien.Image;
                if FileExists(CheminImage) then
                  FImageListGrandsAnciens.Add(CheminImage, nil);
              end;
          end;
      end;

    procedure TFrmInitialisationPartie.FormCreate(Sender : TObject);
      begin
        FGestionnaireGrandsAnciens := TGestionnaireGrandsAnciens.Create;
        FImageListGrandsAnciens := TImageList.Create(Self);
        try
          FImageListGrandsAnciens.Width := 128;
          FImageListGrandsAnciens.Height := 128;
          FImageListGrandsAnciens.ColorDepth := cd32Bit;
          FGestionnaireGrandsAnciens.ChargerDepuisFichier(
            ExtractFilePath(Application.ExeName) + 'Data\Content\grands_anciens.json');
          ChargerImagesGrandsAnciens;
        except
          on E: Exception do
            ShowMessage('Erreur chargement Grands Anciens: ' + E.ClassName + ' - ' + E.Message);
        end;

        // Remplir la combo des Grands Anciens
        ComboGrandAncien.Items.AddRange(FGestionnaireGrandsAnciens.Noms);
        if ComboGrandAncien.Items.Count > 0 then
          ComboGrandAncien.ItemIndex := 0;

        // Associer l'ImageList à l'Image
        ImageGrandAncien.Picture.Reference := FImageListGrandsAnciens;

        // Rafraîchir l'aperçu
        RafraichirApercuGrandAncien;
      end;

    procedure TFrmInitialisationPartie.ComboGrandAncienChange(Sender : TObject);
      begin
        RafraichirApercuGrandAncien;
      end;

    procedure TFrmInitialisationPartie.RafraichirApercuGrandAncien;
      var
        GrandAncien : TGrandAncien;
        CheminImage : string;
      begin
        if ComboGrandAncien.ItemIndex < 0 then
          Exit;

        // Obtenir le Grand Ancien sélectionné
        if FGestionnaireGrandsAnciens.TryObtenirGrandAncien(ComboGrandAncien.Text, GrandAncien) then
          begin
            // Afficher l'image si disponible
            if GrandAncien.Image <> EmptyStr then
              begin
                CheminImage := ExtractFilePath(Application.ExeName) + 'Data\Content\Images\' + GrandAncien.Image;
                if FileExists(CheminImage) then
                  ImageGrandAncien.Picture.LoadFromFile(CheminImage)
                else
                  ImageGrandAncien.Picture.Assign(nil);
              end
            else
              ImageGrandAncien.Picture.Assign(nil);

            // Préremplir la taille de l'échelle du destin
            EditTailleEchelleDestin.Text := IntToStr(GrandAncien.TailleEchelleDestin);

            // Afficher les règles spéciales
            if GrandAncien.Regles.EnSommeil <> EmptyStr then
              LabelReglesEnSommeil.Caption := 'En sommeil: ' + GrandAncien.Regles.EnSommeil
            else
              LabelReglesEnSommeil.Caption := 'En sommeil: Aucune';

            if GrandAncien.Regles.Special <> EmptyStr then
              LabelReglesSpecial.Caption := 'Spéciale: ' + GrandAncien.Regles.Special
            else
              LabelReglesSpecial.Caption := 'Spéciale: Aucune';

            if GrandAncien.Regles.Adorateurs <> EmptyStr then
              LabelReglesAdorateurs.Caption := 'Adorateurs: ' + GrandAncien.Regles.Adorateurs
            else
              LabelReglesAdorateurs.Caption := 'Adorateurs: Aucune';

            if (GrandAncien.Regles.Bataille.Combat <> 0) or (GrandAncien.Regles.Bataille.Defense <> EmptyStr) then
              LabelReglesBataille.Caption := Format('Bataille - Combat: %d, Défense: %s',
                [GrandAncien.Regles.Bataille.Combat, GrandAncien.Regles.Bataille.Defense])
            else
              LabelReglesBataille.Caption := 'Bataille: Aucune';
          end;
      end;

    procedure TFrmInitialisationPartie.FormShow(Sender: TObject);
      begin
        // Rafraîchir la liste des investigateurs pour le choix de départ
        RafraichirListeInvestigateurs;
      end;

    procedure TFrmInitialisationPartie.RafraichirListeInvestigateurs;
      var
        Investigateur : TInvestigateurJoue;
      begin
        ComboInvestigateurDepart.Items.BeginUpdate;
        try
          ComboInvestigateurDepart.Items.Clear;
          for Investigateur in FContextePartie.Investigateurs do
            ComboInvestigateurDepart.Items.Add(Investigateur.NomInvestigateur);
        finally
          ComboInvestigateurDepart.Items.EndUpdate;
        end;

        if ComboInvestigateurDepart.Items.Count > 0 then
          ComboInvestigateurDepart.ItemIndex := 0;
      end;

    procedure TFrmInitialisationPartie.BoutonOKClick(Sender : TObject);
      begin
        ValiderEtFermer;
      end;

    procedure TFrmInitialisationPartie.ValiderEtFermer;
      var
        TailleEchelle : Integer;
        GrandAncien : TGrandAncien;
      begin
        // Valider la taille de l'échelle du destin
        if not TryStrToInt(EditTailleEchelleDestin.Text, TailleEchelle)
           or (TailleEchelle <= 0)
        then
          begin
            ShowMessage('La taille de l''échelle du destin doit être un nombre entier positif.');
            Exit;
          end;

        // Valider la sélection du Grand Ancien
        if ComboGrandAncien.ItemIndex < 0 then
          begin
            ShowMessage('Sélectionnez un Grand Ancien.');
            Exit;
          end;

        // Valider la sélection de l'investigateur de départ
        if ComboInvestigateurDepart.ItemIndex < 0 then
          begin
            ShowMessage('Sélectionnez un investigateur de départ.');
            Exit;
          end;

        // Récupérer le Grand Ancien sélectionné
        if not FGestionnaireGrandsAnciens.TryObtenirGrandAncien(ComboGrandAncien.Text, GrandAncien) then
          begin
            ShowMessage('Erreur: Grand Ancien introuvable.');
            Exit;
          end;

        // Compléter le contexte de partie
        with FContextePartie do
          begin
            TailleEchelleDestin := TailleEchelle;
            NiveauTerreur := 0;
            NombrePortailsOuverts := 0;
            NombreSignesDesAnciens := 0;
            EchelleDestin := 0;
            TourCourant := 1;
            IndexPremierInvestigateur := ComboInvestigateurDepart.ItemIndex;
            IndexInvestigateurCourant := ComboInvestigateurDepart.ItemIndex;
          end;

        // Stocker le Grand Ancien sélectionné (à utiliser par le moteur de règles)
        // Note: Il faudra peut-être ajouter un champ dans TContextePartie pour stocker le nom du Grand Ancien.
        // Pour l'instant, on suppose que le moteur de règles gère ça ailleurs.

        ModalResult := mrOk;
      end;

end.