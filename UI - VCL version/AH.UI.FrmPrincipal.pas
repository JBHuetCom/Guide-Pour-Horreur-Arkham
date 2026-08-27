unit AH.UI.FrmPrincipal;

  interface

    uses

      System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
      Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs,
      AH.Core.Types, AH.Core.Noeud, AH.Core.Contexte, AH.Core.Moteur, AH.Core.ChargeurContenu,
      AH.Core.Conseils, AH.Core.Capacites, AH.Core.GrandsAnciens, AH.Core.Parametres,
      AH.UI.FrameEtape, AH.UI.FrmNouvellePartie;

    type
      /// <summary>Fichier de contenu actuellement piloté par FMoteur.</summary>
      TFichierContenu = (fcPreparation, fcTour, fcBatailleFinale, fcFinDePartie);

      /// <summary>
      /// Fenêtre principale : orchestre l'enchaînement des quatre fichiers de contenu, héberge
      /// TFrameEtape, et tient à jour les panneaux annexes (conseils, capacité de l'investigateur
      /// courant, règle spéciale du Grand Ancien). Le moteur (AH.Core.Moteur) ne sait piloter
      /// qu'un seul arbre à la fois : c'est cette unité qui décide quand et vers quel fichier
      /// basculer, notamment via l'Id du dernier nœud affiché (voir GererFinDeFichier).
      /// </summary>
      TFrmPrincipal = class(TForm)
        private
          FContexte : TContextePartie;
          FParametres : TParametresApplication;
          FGestionnaireConseils : TGestionnaireConseils;
          FGestionnaireCapacites : TGestionnaireCapacites;
          FGestionnaireGrandsAnciens : TGestionnaireGrandsAnciens;

          FRacinePreparation : TNoeudEtape;
          FRacineTour : TNoeudEtape;
          FRacineBatailleFinale : TNoeudEtape;
          FRacineFinDePartie : TNoeudEtape;

          FMoteur : TMoteurSequenceur;
          FFichierActif : TFichierContenu;
          /// <summary>
          /// Id du dernier nœud affiché avant le Suivant qui a retourné nil — seul moyen de savoir,
          /// une fois l'arbre épuisé, quelle feuille terminale a été atteinte (voir GererFinDeFichier).
          /// </summary>
          FDernierIdAffiche : string;

          FrameEtape : TFrameEtape;
          PanelEnTete : TPanel;
          LabelEnTete : TLabel;
          PanelBas : TPanel;
          BoutonPrecedent : TButton;
          BoutonReveilManuel : TButton;
          BoutonTerminerPartie : TButton;
          CheckBoxAfficherConseils : TCheckBox;
          PanelConseils : TPanel;
          MemoConseils : TMemo;
          PanelCapacite : TPanel;
          LabelCapacite : TLabel;
          PanelRegleGrandAncien : TPanel;
          LabelRegleGrandAncien : TLabel;
          PanelEtatTerminal : TPanel;
          LabelEtatTerminal : TLabel;
          BoutonNouvellePartie : TButton;

          // POUR DEBUG SEULEMENT
          LabelIdTechnique : TLabel;

          procedure ConstruireControles;

          /// <returns>Chemin absolu d'un fichier sous Data\Content\, à côté de l'exécutable.</returns>
          function CheminContenu(const ANomFichier : string) : string;

          /// <summary>Charge les quatre arbres de contenu et les trois gestionnaires annexes. Fatal en cas d'échec sur un arbre de contenu.</summary>
          procedure ChargerContenuStatique;

          procedure DemarrerNouvellePartie;
          procedure ChargerFichier(AFichier : TFichierContenu);
          procedure AvancerEtAfficher;
          procedure GererFinDeFichier;
          procedure AfficherEtatTerminal;

          procedure RafraichirEnTete;
          procedure RafraichirPanneauxAnnexes;
          procedure RafraichirEtatBoutons;

          procedure GererEtapeValidee(Sender : TObject; const AValeur : Variant);
          procedure GererClicPrecedent(Sender : TObject);
          procedure GererClicReveilManuel(Sender : TObject);
          procedure GererClicTerminerPartie(Sender : TObject);
          procedure GererClicAfficherConseils(Sender : TObject);
          procedure GererClicNouvellePartie(Sender : TObject);
          procedure GererAffichageInitial(Sender : TObject);
        public
          constructor Create(AOwner : TComponent); override;
          destructor Destroy; override;
      end;

    var
      FrmPrincipal : TFrmPrincipal;

  implementation

    uses

      System.UITypes;

    const
      CheminsRelatifsContenu = 'Data\Content\';

      IdsReveilPreparation: array[0..3] of string = (
        'prep14_reveil_destin', 'prep14_reveil_pile_vide',
        'prep14_reveil_trop_portails', 'prep14_reveil_tasse_vide');

      IdsReveilTour: array[0..3] of string = (
        'phase5_reveil_destin', 'phase5_reveil_pile_vide',
        'phase5_reveil_trop_portails', 'phase5_reveil_tasse_vide');

      IdRoundSuivantBatailleFinale = 'bf_round_suivant';

      IdsFinBatailleFinale: array[0..1] of string = ('bf_victoire', 'bf_defaite');

    /// <summary>Recherche simple d'une valeur dans un petit tableau de chaînes (les constantes ci-dessus).</summary>
    function TableauContientId(const ATableau : array of string; const AId : string) : Boolean;
        var
          Element: string;
        begin
          Result := False;
          for Element in ATableau do
            if Element = AId then
              Exit(True);
        end;

    { TFrmPrincipal }

    constructor TFrmPrincipal.Create(AOwner : TComponent);
      begin
        inherited CreateNew(AOwner);

        Caption := 'Horreur à Arkham — Guide de partie';
        Position := poScreenCenter;
        Width := 900;
        Height := 640;

        FParametres := TParametresApplication.Create;
        try
          FParametres.ChargerDepuisFichier(CheminContenu('parametres.json'));
        except
          // Réglages absents ou invalides au premier lancement : valeurs par défaut conservées.
        end;

        FGestionnaireConseils := TGestionnaireConseils.Create;
        FGestionnaireCapacites := TGestionnaireCapacites.Create;
        FGestionnaireGrandsAnciens := TGestionnaireGrandsAnciens.Create;

        ConstruireControles;
        ChargerContenuStatique;

       // DemarrerNouvellePartie utilise FrmNouvellePartie (formulaire auto-créé) : à cet instant du
       // constructeur, le .dpr n'a pas encore exécuté son propre Application.CreateForm, donc
       // FrmNouvellePartie vaut encore nil. On reporte le premier appel à OnShow, qui ne se déclenche
       // qu'une fois tous les Application.CreateForm du .dpr terminés et Application.Run démarré.
       OnShow := GererAffichageInitial;
     end;

    destructor TFrmPrincipal.Destroy;
      begin
        try
          FParametres.SauvegarderDansFichier(CheminContenu('parametres.json'));
        except
          // Un échec de sauvegarde des préférences ne doit jamais empêcher la fermeture de l'application.
        end;

        FMoteur.Free;
        FContexte.Free;
        FRacineFinDePartie.Free;
        FRacineBatailleFinale.Free;
        FRacineTour.Free;
        FRacinePreparation.Free;
        FGestionnaireGrandsAnciens.Free;
        FGestionnaireCapacites.Free;
        FGestionnaireConseils.Free;
        FParametres.Free;

        inherited;
      end;

    function TFrmPrincipal.CheminContenu(const ANomFichier : string) : string;
      begin
        Result := ExtractFilePath(Application.ExeName) + CheminsRelatifsContenu + ANomFichier;
      end;

    procedure TFrmPrincipal.ConstruireControles;
      begin
        PanelEnTete := TPanel.Create(Self);
        PanelEnTete.Parent := Self;
        PanelEnTete.Align := alTop;
        PanelEnTete.Height := 56;
        PanelEnTete.BevelOuter := bvNone;

        LabelEnTete := TLabel.Create(Self);
        LabelEnTete.Parent := PanelEnTete;
        LabelEnTete.SetBounds(12, 10, 860, 20);
        LabelEnTete.Font.Style := [fsBold];

        PanelBas := TPanel.Create(Self);
        PanelBas.Parent := Self;
        PanelBas.Align := alBottom;
        PanelBas.Height := 48;
        PanelBas.BevelOuter := bvNone;

        BoutonPrecedent := TButton.Create(Self);
        BoutonPrecedent.Parent := PanelBas;
        BoutonPrecedent.SetBounds(12, 10, 110, 28);
        BoutonPrecedent.Caption := '< Précédent';
        BoutonPrecedent.OnClick := GererClicPrecedent;

        BoutonReveilManuel := TButton.Create(Self);
        BoutonReveilManuel.Parent := PanelBas;
        BoutonReveilManuel.SetBounds(132, 10, 260, 28);
        BoutonReveilManuel.Caption := 'Le Grand Ancien s''est réveillé';
        BoutonReveilManuel.OnClick := GererClicReveilManuel;

        BoutonTerminerPartie := TButton.Create(Self);
        BoutonTerminerPartie.Parent := PanelBas;
        BoutonTerminerPartie.SetBounds(400, 10, 160, 28);
        BoutonTerminerPartie.Caption := 'Terminer la partie';
        BoutonTerminerPartie.OnClick := GererClicTerminerPartie;

        CheckBoxAfficherConseils := TCheckBox.Create(Self);
        CheckBoxAfficherConseils.Parent := PanelBas;
        CheckBoxAfficherConseils.SetBounds(700, 14, 160, 20);
        CheckBoxAfficherConseils.Caption := 'Afficher les conseils';
        CheckBoxAfficherConseils.OnClick := GererClicAfficherConseils;

        // --- Panneaux annexes, à droite ---
        PanelConseils := TPanel.Create(Self);
        PanelConseils.Parent := Self;
        PanelConseils.Align := alRight;
        PanelConseils.Width := 280;
        PanelConseils.BevelOuter := bvNone;
        PanelConseils.Caption := EmptyStr;

        MemoConseils := TMemo.Create(Self);
        MemoConseils.Parent := PanelConseils;
        MemoConseils.Align := alClient;
        MemoConseils.ReadOnly := True;
        MemoConseils.ScrollBars := ssVertical;
        MemoConseils.Color := clInfoBk;
        MemoConseils.WordWrap := True;

        PanelCapacite := TPanel.Create(Self);
        PanelCapacite.Parent := Self;
        PanelCapacite.Align := alBottom;
        PanelCapacite.Height := 60;
        PanelCapacite.BevelOuter := bvNone;

        LabelCapacite := TLabel.Create(Self);
        LabelCapacite.Parent := PanelCapacite;
        LabelCapacite.Align := alClient;
        LabelCapacite.Layout := tlCenter;
        LabelCapacite.WordWrap := True;
        LabelCapacite.Font.Style := [fsItalic];

        PanelRegleGrandAncien := TPanel.Create(Self);
        PanelRegleGrandAncien.Parent := Self;
        PanelRegleGrandAncien.Align := alBottom;
        PanelRegleGrandAncien.Height := 60;
        PanelRegleGrandAncien.BevelOuter := bvNone;
        PanelRegleGrandAncien.Color := clYellow;

        LabelRegleGrandAncien := TLabel.Create(Self);
        LabelRegleGrandAncien.Parent := PanelRegleGrandAncien;
        LabelRegleGrandAncien.Align := alClient;
        LabelRegleGrandAncien.Layout := tlCenter;
        LabelRegleGrandAncien.WordWrap := True;
        LabelRegleGrandAncien.Font.Style := [fsBold];

        // --- Zone centrale : la frame d'étape, ou l'état terminal ---
        FrameEtape := TFrameEtape.Create(Self);
        FrameEtape.Parent := Self;
        FrameEtape.Align := alClient;
        FrameEtape.OnEtapeValidee := GererEtapeValidee;

        PanelEtatTerminal := TPanel.Create(Self);
        PanelEtatTerminal.Parent := Self;
        PanelEtatTerminal.Align := alClient;
        PanelEtatTerminal.BevelOuter := bvNone;
        PanelEtatTerminal.Visible := False;

        LabelEtatTerminal := TLabel.Create(Self);
        LabelEtatTerminal.Parent := PanelEtatTerminal;
        LabelEtatTerminal.SetBounds(20, 20, 500, 60);
        LabelEtatTerminal.Font.Size := 14;
        LabelEtatTerminal.WordWrap := True;

        BoutonNouvellePartie := TButton.Create(Self);
        BoutonNouvellePartie.Parent := PanelEtatTerminal;
        BoutonNouvellePartie.SetBounds(20, 90, 160, 30);
        BoutonNouvellePartie.Caption := 'Nouvelle partie';
        BoutonNouvellePartie.OnClick := GererClicNouvellePartie;

        // POUR DEBUG SEULEMENT
        LabelIdTechnique := TLabel.Create(Self);
        LabelIdTechnique.Parent := PanelEnTete;
        LabelIdTechnique.SetBounds(12, 22, 860, 16);
        LabelIdTechnique.Font.Name := 'Consolas';
        LabelIdTechnique.Font.Color := clGray;

      end;

    procedure TFrmPrincipal.ChargerContenuStatique;
      begin
        try
          FRacinePreparation := TChargeurContenu.ChargerDepuisFichier(CheminContenu('preparation.json'));
          FRacineTour := TChargeurContenu.ChargerDepuisFichier(CheminContenu('tour.json'));
          FRacineBatailleFinale := TChargeurContenu.ChargerDepuisFichier(CheminContenu('bataille_finale.json'));
          FRacineFinDePartie := TChargeurContenu.ChargerDepuisFichier(CheminContenu('fin_de_partie.json'));
        except
          on E: Exception do
            begin
              MessageDlg(
                'Impossible de charger le contenu du guide : ' + E.Message +
                sLineBreak + 'L''application ne peut pas continuer.',
                mtError, [mbOK], 0);
              Application.Terminate;
              Exit;
            end;
        end;

        // Contenu annexe : un échec de chargement n'empêche pas l'application de fonctionner,
        // les panneaux correspondants resteront simplement vides.
        try
          FGestionnaireConseils.ChargerDepuisFichier(CheminContenu('conseils.json'));
        except
        end;
        try
          FGestionnaireCapacites.ChargerDepuisFichier(CheminContenu('capacites_investigateurs.json'));
        except
        end;
        try
          FGestionnaireGrandsAnciens.ChargerDepuisFichier(CheminContenu('grands_anciens.json'));
        except
        end;
      end;

    procedure TFrmPrincipal.DemarrerNouvellePartie;
      begin
        FMoteur.Free;
        FMoteur := nil;
        FContexte.Free;
        FContexte := nil;

        if FrmNouvellePartie.ShowModal <> mrOk then
          begin
            Application.Terminate;
            Exit;
          end;
        FContexte := FrmNouvellePartie.ContextePartieCreee;

        PanelEtatTerminal.Visible := False;
        FrameEtape.Visible := True;
        ChargerFichier(fcPreparation);
      end;

    procedure TFrmPrincipal.ChargerFichier(AFichier : TFichierContenu);
      var
        Racine : TNoeudEtape;
      begin
        FFichierActif := AFichier;

        case AFichier of
          fcPreparation : Racine := FRacinePreparation;
          fcTour : Racine := FRacineTour;
          fcBatailleFinale : Racine := FRacineBatailleFinale;
          fcFinDePartie : Racine := FRacineFinDePartie;
        else
          raise EArgumentException.Create('Fichier de contenu inconnu.');
        end;

        FMoteur.Free;
        FMoteur := TMoteurSequenceur.Create(Racine, FContexte);
        AvancerEtAfficher;
      end;

    procedure TFrmPrincipal.AvancerEtAfficher;
      var
        Noeud : TNoeudEtape;
      begin
        Noeud := FMoteur.Suivant;
        if Assigned(Noeud) then
          begin
            FDernierIdAffiche := Noeud.Id;
            FrameEtape.AfficherNoeud(Noeud);
            RafraichirEnTete;
            RafraichirPanneauxAnnexes;
            RafraichirEtatBoutons;
          end
        else
          GererFinDeFichier;
      end;

    procedure TFrmPrincipal.GererFinDeFichier;
    begin
      case FFichierActif of
        fcPreparation :
          if TableauContientId(IdsReveilPreparation, FDernierIdAffiche) then
            ChargerFichier(fcBatailleFinale)
          else
            ChargerFichier(fcTour);

        fcTour :
          if TableauContientId(IdsReveilTour, FDernierIdAffiche) then
            ChargerFichier(fcBatailleFinale)
          else
            begin
              FContexte.TourCourant := FContexte.TourCourant + 1;
              ChargerFichier(fcTour); // Nouveau tour : même arbre, nouvelle instance de moteur.
            end;

        fcBatailleFinale :
          if FDernierIdAffiche = IdRoundSuivantBatailleFinale then
            ChargerFichier(fcBatailleFinale) // Nouveau round : contournement de l'absence de ntBoucleTantQue.
          else
            ChargerFichier(fcFinDePartie);

        fcFinDePartie:
          AfficherEtatTerminal;
      end;
    end;

    procedure TFrmPrincipal.AfficherEtatTerminal;
      begin
        if TableauContientId(IdsFinBatailleFinale, FDernierIdAffiche)
           and (FDernierIdAffiche = 'bf_defaite')
        then
          LabelEtatTerminal.Caption := 'La partie est terminée : défaite.'
        else
          LabelEtatTerminal.Caption := 'La partie est terminée.';

        FrameEtape.Visible := False;
        PanelEtatTerminal.Visible := True;
        RafraichirEtatBoutons;
      end;

    procedure TFrmPrincipal.RafraichirEnTete;
      var
        PrefixePhase:  string;
      begin
        case FFichierActif of
          fcPreparation: PrefixePhase := 'Préparation';
          fcTour: PrefixePhase := Format('Tour %d', [FContexte.TourCourant]);
          fcBatailleFinale: PrefixePhase := 'Bataille finale';
          fcFinDePartie: PrefixePhase := 'Fin de partie';
        end;

        if FMoteur.EstDansBouclePorInvestigateur then
          LabelEnTete.Caption := Format('%s — %s (joué par %s)',
            [PrefixePhase, FContexte.NomInvestigateurCourant, FContexte.NomJoueurHumainCourant])
        else
          LabelEnTete.Caption := PrefixePhase;

        LabelIdTechnique.Caption := 'Id : ' + FDernierIdAffiche;
      end;

    procedure TFrmPrincipal.RafraichirPanneauxAnnexes;
      var
        Conseils : TArray<TConseil>;
        Conseil : TConseil;
        TexteConseils : string;
        Capacite : TCapaciteInvestigateur;
        TexteRegle : string;
      begin
        Conseils := FGestionnaireConseils.ConseilsPour(FDernierIdAffiche);
        if FParametres.AfficherConseils
           and (Length(Conseils) > 0)
        then
          begin
            TexteConseils := EmptyStr;
            for Conseil in Conseils do
              TexteConseils := TexteConseils + '• ' + Conseil.Texte + sLineBreak + sLineBreak;
            MemoConseils.Lines.Text := Trim(TexteConseils);
            PanelConseils.Visible := True;
          end
        else
          PanelConseils.Visible := False;

        if FGestionnaireCapacites.TryObtenirCapacite(FContexte.NomInvestigateurCourant, Capacite) then
          begin
            LabelCapacite.Caption := Format('%s : %s', [Capacite.NomInvestigateur, Capacite.Description]);
            PanelCapacite.Visible := True;
          end
        else
          PanelCapacite.Visible := False;

        if (FContexte.NomGrandAncien <> EmptyStr) and
           FGestionnaireGrandsAnciens.TryObtenirRegleEtape(FContexte.NomGrandAncien, FDernierIdAffiche, TexteRegle)
        then
          begin
            LabelRegleGrandAncien.Caption := TexteRegle;
            PanelRegleGrandAncien.Visible := True;
          end
        else
          PanelRegleGrandAncien.Visible := False;
      end;

    procedure TFrmPrincipal.RafraichirEtatBoutons;
      var
        EnPartie : Boolean;
      begin
        EnPartie := FFichierActif <> fcFinDePartie;
        BoutonPrecedent.Enabled := EnPartie;
        BoutonReveilManuel.Enabled := EnPartie and (FFichierActif <> fcBatailleFinale);
        BoutonTerminerPartie.Enabled := EnPartie and (FFichierActif = fcTour);
        CheckBoxAfficherConseils.Checked := FParametres.AfficherConseils;
      end;

    procedure TFrmPrincipal.GererEtapeValidee(Sender : TObject; const AValeur : Variant);
      begin
        if FrameEtape.NoeudCourant.TypeNoeud <> ntInstruction then
          try
            FMoteur.EnregistrerReponse(AValeur);
          except
            on E: Exception do
            begin
              FrameEtape.AfficherErreurSaisie(E.Message);

              Exit;
            end;
          end;

        AvancerEtAfficher;
      end;

    procedure TFrmPrincipal.GererClicPrecedent(Sender : TObject);
      var
        Noeud : TNoeudEtape;
      begin
        Noeud := FMoteur.Precedent;
        if Assigned(Noeud) then
          begin
            FDernierIdAffiche := Noeud.Id;
            FrameEtape.AfficherNoeud(Noeud);
            RafraichirEnTete;
            RafraichirPanneauxAnnexes;
            RafraichirEtatBoutons;
          end;
        // Si nil : déjà au tout début du fichier courant, rien à faire — le bouton reste actif
        // faute d'un moyen simple de savoir à l'avance qu'on est sur la toute première étape.
      end;

    procedure TFrmPrincipal.GererClicReveilManuel(Sender : TObject);
      begin
        if MessageDlg(
             'Confirmer le réveil du Grand Ancien et passer à la Bataille Finale ?',
             mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          ChargerFichier(fcBatailleFinale);
      end;

    procedure TFrmPrincipal.GererClicTerminerPartie(Sender : TObject);
      begin
        if MessageDlg(
             'Confirmer la fin de la partie (fermeture totale des portails, ou scellement) ?',
             mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          ChargerFichier(fcFinDePartie);
      end;

    procedure TFrmPrincipal.GererClicAfficherConseils(Sender : TObject);
      begin
        FParametres.AfficherConseils := CheckBoxAfficherConseils.Checked;
        RafraichirPanneauxAnnexes;
      end;

    procedure TFrmPrincipal.GererClicNouvellePartie(Sender : TObject);
      begin
        DemarrerNouvellePartie;
      end;

    procedure TFrmPrincipal.GererAffichageInitial(Sender: TObject);
      begin
        OnShow := nil;
        TThread.ForceQueue(nil,
          procedure
          begin
            DemarrerNouvellePartie;
          end);
      end;

end.
