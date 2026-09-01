unit AH.UI.FrmPrincipal;

  interface

    uses

      Winapi.Windows, Winapi.Messages,
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

          /// <returns>Chemin absolu d'un fichier sous Data\Content\, à côté de l'exécutable.</returns>
          function CheminContenu(const ANomFichier : string) : string;

          /// <summary>Charge les quatre arbres de contenu et les trois gestionnaires annexes. Fatal en cas d'échec sur un arbre de contenu.</summary>
          procedure ChargerContenuStatique;
          procedure ChargerFichier(AFichier : TFichierContenu);
          procedure AvancerEtAfficher;
          procedure GererFinDeFichier;
          procedure AfficherEtatTerminal;
          procedure RafraichirEnTete;
          procedure RafraichirPanneauxAnnexes;
          procedure RafraichirEtatBoutons;
        public
          procedure DemarrerNouvellePartie;
        published
          PanelEnTete : TPanel;
          LabelEnTete : TLabel;

          // POUR DEBUG SEULEMENT
          LabelIdTechnique : TLabel;

          PanelBas : TPanel;
          BoutonPrecedent : TButton;
          BoutonReveilManuel : TButton;
          BoutonTerminerPartie : TButton;
          CheckBoxAfficherConseils : TCheckBox;
          PanelConseils : TPanel;
          MemoConseils : TMemo;
          PanelRegleGrandAncien : TPanel;
          LabelRegleGrandAncien : TLabel;
          PanelCapacite : TPanel;
          LabelCapacite : TLabel;
          LabelFilAriane : TLabel;
          FrameEtape : TFrameEtape;
          PanelEtatTerminal : TPanel;
          LabelEtatTerminal : TLabel;
          BoutonNouvellePartie : TButton;
          procedure FormCreate(Sender: TObject);
          procedure FormDestroy(Sender: TObject);
          procedure GererEtapeValidee(Sender : TObject; const AValeur : Variant);
          procedure GererClicPrecedent(Sender : TObject);
          procedure GererClicReveilManuel(Sender : TObject);
          procedure GererClicTerminerPartie(Sender : TObject);
          procedure GererClicAfficherConseils(Sender : TObject);
          procedure GererClicNouvellePartie(Sender : TObject);
      end;

    var

      FrmPrincipal : TFrmPrincipal;

  implementation

    uses

      System.UITypes;

    {$R *.dfm}

    const

      CheminsRelatifsContenu = 'Data\Content\';

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

    function TFrmPrincipal.CheminContenu(const ANomFichier : string) : string;
      begin
        Result := ExtractFilePath(Application.ExeName) + CheminsRelatifsContenu + ANomFichier;
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
        FrameEtape.OnEtapeValidee := GererEtapeValidee;
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
            if SameText(Noeud.ChampContexte, 'NomGrandAncien') then
              FrameEtape.DefinirOptionsSaisie(FGestionnaireGrandsAnciens.Noms)
            else
              FrameEtape.DefinirOptionsSaisie([]);
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
          ChargerFichier(fcTour); // Le réveil du Grand Ancien ne peut plus survenir pendant la préparation (voir prep14 simplifié).

        fcTour:
          if TableauContientId(IdsReveilTour, FDernierIdAffiche) then
            ChargerFichier(fcBatailleFinale)
          else
            begin
              FContexte.TourCourant := FContexte.TourCourant + 1;
              FContexte.PasserMarqueurPremierJoueur;
              ChargerFichier(fcTour);
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
        PrefixePhase : string;
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
          if FFichierActif = fcTour then
            LabelEnTete.Caption := Format('%s — Limite de monstres à Arkham : %d · Limite en Périphérie : %d',
              [PrefixePhase, FContexte.LimiteMonstres, FContexte.LimitePeripherie])
          else
            LabelEnTete.Caption := PrefixePhase;

        LabelFilAriane.Caption := string.Join(' › ', FMoteur.TitresPhaseActifs);
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

        if (FFichierActif = fcTour)
           and FMoteur.EstDansBouclePorInvestigateur
           and FGestionnaireCapacites.TryObtenirCapacite(FContexte.NomInvestigateurCourant, Capacite)
        then
          begin
            LabelCapacite.Caption := Format('%s : %s', [Capacite.NomInvestigateur, Capacite.Description]);
            PanelCapacite.Visible := True;
          end
        else
          PanelCapacite.Visible := False;

        if (FContexte.NomGrandAncien <> EmptyStr)
          and FGestionnaireGrandsAnciens.TryObtenirRegleEtape(FContexte.NomGrandAncien,
                                                              FDernierIdAffiche,
                                                              TexteRegle)
        then
          begin
            LabelRegleGrandAncien.Caption := TexteRegle;
            PanelRegleGrandAncien.Visible := True;
          end
        else
          PanelRegleGrandAncien.Visible := False;
      end;

    procedure TFrmPrincipal.RafraichirEtatBoutons;
      begin
        BoutonPrecedent.Enabled := FMoteur.PeutReculer;
        BoutonReveilManuel.Enabled := FFichierActif = fcTour;
        BoutonTerminerPartie.Enabled := FFichierActif = fcTour;
        CheckBoxAfficherConseils.Checked := FParametres.AfficherConseils;
      end;

    procedure TFrmPrincipal.GererEtapeValidee(Sender : TObject; const AValeur : Variant);
      var
        ChampVise : string;
        GrandAncien : TGrandAncien;
      begin
        if FrameEtape.NoeudCourant.TypeNoeud <> ntInstruction then
          begin
            ChampVise := FrameEtape.NoeudCourant.ChampContexte;
            try
              FMoteur.EnregistrerReponse(AValeur);
            except
              on E : Exception do
                begin
                  FrameEtape.AfficherErreurSaisie(E.Message);
                  Exit;
                end;
            end;

            if SameText(ChampVise, 'NomGrandAncien')
               and FGestionnaireGrandsAnciens.TryObtenirGrandAncien(FContexte.NomGrandAncien, GrandAncien)
            then
              FContexte.TailleEchelleDestin := GrandAncien.TailleEchelleDestin;
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
            if SameText(Noeud.ChampContexte, 'NomGrandAncien') then
              FrameEtape.DefinirOptionsSaisie(FGestionnaireGrandsAnciens.Noms)
            else
              FrameEtape.DefinirOptionsSaisie([]);
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

    procedure TFrmPrincipal.FormCreate(Sender : TObject);
      begin
        WindowState := wsMaximized;
        Font.Size := 14;
        FrameEtape.DefinirDossierImages(ExtractFilePath(Application.ExeName) + 'Data\Images\');

        FParametres := TParametresApplication.Create;
        try
          FParametres.ChargerDepuisFichier(CheminContenu('parametres.json'));
        except
        end;

        FGestionnaireConseils := TGestionnaireConseils.Create;
        FGestionnaireCapacites := TGestionnaireCapacites.Create;
        FGestionnaireGrandsAnciens := TGestionnaireGrandsAnciens.Create;

        ChargerContenuStatique;
      end;

    procedure TFrmPrincipal.FormDestroy(Sender: TObject);
      begin
        try
          FParametres.SauvegarderDansFichier(CheminContenu('parametres.json'));
        except
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
      end;

end.
