unit AH.UI.FrameEtape;

  interface

  uses

    System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
    Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Graphics,
    AH.Core.Noeud, AH.Core.Types;

  type
    /// <summary>
    /// Événement déclenché quand l'utilisateur termine son interaction avec l'étape affichée.
    /// AValeur vaut Unassigned pour un ntInstruction (aucune réponse à transmettre), la
    /// ValeurDeclenchante de la branche choisie pour un ntChoix, ou le texte saisi (converti
    /// plus tard par TContextePartie.AffecterChamp, jamais ici) pour un ntSaisie.
    /// </summary>
    TAhEtapeValideeEvent = procedure(Sender : TObject; const AValeur : Variant) of object;

    /// <summary>
    /// Affiche un nœud interactif (ntInstruction, ntChoix ou ntSaisie) et capture la réaction de
    /// l'utilisateur. Ne connaît ni TMoteurSequenceur ni TContextePartie : c'est à l'appelant
    /// (AH.UI.FrmPrincipal) de piloter la navigation à partir de l'événement OnEtapeValidee.
    /// </summary>
    TFrameEtape = class(TFrame)
      private
        FOnEtapeValidee : TAhEtapeValideeEvent;
        FValeursBranches : TList<Variant>;
        FNoeudCourant : TNoeudEtape;

        LabelTitre : TLabel;
        LabelTexte : TLabel;
        PanelInstruction : TPanel;
        BoutonContinuer : TButton;
        PanelChoix : TPanel;
        PanelSaisie : TPanel;
        EditSaisie : TEdit;
        BoutonValiderSaisie : TButton;
        LabelErreurSaisie : TLabel;

        procedure ConstruireControles;
        procedure ViderBoutonsChoix;
        procedure ConstruireBoutonsChoix(ANoeud : TNoeudEtape);

        procedure GererClicContinuer(ASender : TObject);
        procedure GererClicBoutonChoix(ASender : TObject);
        procedure GererClicValiderSaisie(ASender : TObject);
      public
        /// <param name="AOwner">Propriétaire standard VCL de la frame.</param>
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;

        /// <param name="ANoeud">
        /// Nœud à afficher. Doit être de type ntInstruction, ntChoix ou ntSaisie — c'est-à-dire
        /// exactement ce que retourne TMoteurSequenceur.Suivant/Precedent quand il n'est pas nil.
        /// </param>
        /// <exception cref="EArgumentException">
        /// Levée si ANoeud est d'un type structurel (ntSequence, ntBouclePorInvestigateur, ntCondition), qui ne devrait jamais atteindre l'UI.
        /// </exception>
        procedure AfficherNoeud(ANoeud : TNoeudEtape);

        /// <summary>
        /// Affiche un message d'erreur sous le champ de saisie, sans changer de nœud affiché.
        /// Destiné à signaler un échec de conversion survenu après coup dans
        /// TContextePartie.AffecterChamp (ex. texte non numérique pour un champ entier) : cette
        /// frame elle-même ne connaît pas le type attendu par le champ de contexte ciblé.
        /// </summary>
        /// <param name="AMessage">Message à afficher. Une chaîne vide efface le message précédent.</param>
        /// <exception cref="EInvalidOpException">Levée si le nœud actuellement affiché n'est pas de type ntSaisie.</exception>
        procedure AfficherErreurSaisie(const AMessage : string);

        /// <summary>Nœud actuellement affiché, ou nil si AfficherNoeud n'a pas encore été appelée.</summary>
        property NoeudCourant : TNoeudEtape read FNoeudCourant;

        /// <summary>Déclenché quand l'utilisateur valide l'étape affichée (voir TAhEtapeValideeEvent).</summary>
        property OnEtapeValidee : TAhEtapeValideeEvent read FOnEtapeValidee write FOnEtapeValidee;
    end;

  implementation

    { TFrameEtape }

    constructor TFrameEtape.Create(AOwner : TComponent);
      begin
        inherited Create(AOwner);

        FValeursBranches := TList<Variant>.Create;
        ConstruireControles;
      end;

    destructor TFrameEtape.Destroy;
      begin
        FValeursBranches.Free;

        inherited;
      end;

    procedure TFrameEtape.ConstruireControles;
      begin
        Width := 500;
        Height := 300;

        LabelTitre := TLabel.Create(Self);
        LabelTitre.Parent := Self;
        LabelTitre.SetBounds(0, 0, 480, 24);
        LabelTitre.Font.Style := [fsBold];
        LabelTitre.Font.Size := 12;
        LabelTitre.WordWrap := True;

        LabelTexte := TLabel.Create(Self);
        LabelTexte.Parent := Self;
        LabelTexte.SetBounds(0, 32, 480, 100);
        LabelTexte.WordWrap := True;
        LabelTexte.AutoSize := False;

        // --- ntInstruction ---
        PanelInstruction := TPanel.Create(Self);
        PanelInstruction.Parent := Self;
        PanelInstruction.SetBounds(0, 140, 480, 40);
        PanelInstruction.BevelOuter := bvNone;

        BoutonContinuer := TButton.Create(Self);
        BoutonContinuer.Parent := PanelInstruction;
        BoutonContinuer.SetBounds(0, 0, 160, 30);
        BoutonContinuer.Caption := 'Étape suivante';
        BoutonContinuer.Default := True;
        BoutonContinuer.OnClick := GererClicContinuer;

        // --- ntChoix (peuplé dynamiquement dans ConstruireBoutonsChoix) ---
        PanelChoix := TPanel.Create(Self);
        PanelChoix.Parent := Self;
        PanelChoix.SetBounds(0, 140, 480, 140);
        PanelChoix.BevelOuter := bvNone;

        // --- ntSaisie ---
        PanelSaisie := TPanel.Create(Self);
        PanelSaisie.Parent := Self;
        PanelSaisie.SetBounds(0, 140, 480, 80);
        PanelSaisie.BevelOuter := bvNone;

        EditSaisie := TEdit.Create(Self);
        EditSaisie.Parent := PanelSaisie;
        EditSaisie.SetBounds(0, 0, 200, 24);

        BoutonValiderSaisie := TButton.Create(Self);
        BoutonValiderSaisie.Parent := PanelSaisie;
        BoutonValiderSaisie.SetBounds(208, 0, 100, 26);
        BoutonValiderSaisie.Caption := 'Valider';
        BoutonValiderSaisie.Default := True;
        BoutonValiderSaisie.OnClick := GererClicValiderSaisie;

        LabelErreurSaisie := TLabel.Create(Self);
        LabelErreurSaisie.Parent := PanelSaisie;
        LabelErreurSaisie.SetBounds(0, 34, 480, 20);
        LabelErreurSaisie.Font.Color := clRed;
        LabelErreurSaisie.WordWrap := True;

        PanelInstruction.Visible := False;
        PanelChoix.Visible := False;
        PanelSaisie.Visible := False;
      end;

    procedure TFrameEtape.ViderBoutonsChoix;
      begin
        while PanelChoix.ControlCount > 0 do
          PanelChoix.Controls[0].Free;
        FValeursBranches.Clear;
      end;

    procedure TFrameEtape.ConstruireBoutonsChoix(ANoeud : TNoeudEtape);
      var
        Branche: TBrancheEtape;
        Bouton: TButton;
        Decalage: Integer;
      begin
        ViderBoutonsChoix;

        Decalage := 0;
        for Branche in ANoeud.Branches do
          begin
            Bouton := TButton.Create(Self);
            Bouton.Parent := PanelChoix;
            Bouton.SetBounds(0, Decalage, 300, 30);
            if Branche.Libelle <> EmptyStr then
              Bouton.Caption := Branche.Libelle
            else
              Bouton.Caption := VarToStr(Branche.ValeurDeclenchante);
            Bouton.Tag := FValeursBranches.Add(Branche.ValeurDeclenchante);
            Bouton.OnClick := GererClicBoutonChoix;

            Inc(Decalage, 36);
          end;
      end;

    procedure TFrameEtape.AfficherNoeud(ANoeud : TNoeudEtape);
      begin
        if not Assigned(ANoeud) then
          raise EArgumentNilException.Create('AfficherNoeud ne peut pas recevoir nil.');

        if not (ANoeud.TypeNoeud in [ntInstruction, ntChoix, ntSaisie]) then
          raise EArgumentException.CreateFmt(
            'AfficherNoeud attend un nœud interactif (ntInstruction, ntChoix ou ntSaisie) ; ' +
            'le nœud "%s" est d''un type structurel qui ne devrait jamais atteindre l''UI.',
            [ANoeud.Id]);

        FNoeudCourant := ANoeud;

        LabelTitre.Caption := ANoeud.Titre;
        LabelTitre.Visible := ANoeud.Titre <> EmptyStr;
        LabelTexte.Caption := ANoeud.Texte;

        PanelInstruction.Visible := ANoeud.TypeNoeud = ntInstruction;
        PanelChoix.Visible := ANoeud.TypeNoeud = ntChoix;
        PanelSaisie.Visible := ANoeud.TypeNoeud = ntSaisie;

        case ANoeud.TypeNoeud of
          ntChoix:
            ConstruireBoutonsChoix(ANoeud);
          ntSaisie:
            begin
              EditSaisie.Text := EmptyStr;
              LabelErreurSaisie.Caption := EmptyStr;
              EditSaisie.SetFocus;
            end;
        end;
      end;

    procedure TFrameEtape.AfficherErreurSaisie(const AMessage : string);
      begin
        if not Assigned(FNoeudCourant)
           or (FNoeudCourant.TypeNoeud <> ntSaisie)
        then
          raise EInvalidOpException.Create(
            'AfficherErreurSaisie ne peut être appelée que lorsqu''un nœud ntSaisie est affiché.');

        LabelErreurSaisie.Caption := AMessage;
      end;

    procedure TFrameEtape.GererClicContinuer(ASender : TObject);
      begin
        if Assigned(FOnEtapeValidee) then
          FOnEtapeValidee(Self, Unassigned);
      end;

    procedure TFrameEtape.GererClicBoutonChoix(ASender : TObject);
      var
        ValeurChoisie : Variant;
      begin
        ValeurChoisie := FValeursBranches[(ASender as TButton).Tag];
        if Assigned(FOnEtapeValidee) then
          FOnEtapeValidee(Self, ValeurChoisie);
      end;

    procedure TFrameEtape.GererClicValiderSaisie(ASender : TObject);
      var
        Texte : string;
      begin
        Texte := Trim(EditSaisie.Text);
        if Texte = EmptyStr then
          begin
            LabelErreurSaisie.Caption := 'Saisissez une valeur avant de valider.';
            Exit;
          end;

        LabelErreurSaisie.Caption := EmptyStr;
        if Assigned(FOnEtapeValidee) then
          FOnEtapeValidee(Self, Texte);
      end;

end.
