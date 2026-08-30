unit AH.UI.FrameEtape;

  interface

    uses
      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Variants,
      System.Generics.Collections,
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

          procedure ViderBoutonsChoix;
          procedure ConstruireBoutonsChoix(ANoeud : TNoeudEtape);
        public
          /// <param name="AOwner">Propriétaire standard VCL de la frame.</param>
          constructor Create(AOwner : TComponent); override;
          destructor Destroy; override;

          /// <param name="ANoeud">
          /// Nœud à afficher. Doit être de type ntInstruction, ntChoix ou ntSaisie — c'est-à-dire
          /// exactement ce que retourne TMoteurSequenceur.Suivant/Precedent quand il n'est pas nil.
          /// </param>
          /// <exception cref="EArgumentException">
          /// Levée si ANoeud est d'un type structurel (ntSequence, ntBouclePorInvestigateur,
          /// ntCondition), qui ne devrait jamais atteindre l'UI.
          /// </exception>
          procedure AfficherNoeud(ANoeud : TNoeudEtape);

          /// <summary>
          /// Affiche un message d'erreur sous le champ de saisie, sans changer de nœud affiché.
          /// </summary>
          /// <param name="AMessage">Message à afficher. Une chaîne vide efface le message précédent.</param>
          /// <exception cref="EInvalidOpException">
          /// Levée si le nœud actuellement affiché n'est pas de type ntSaisie.
          /// </exception>
          procedure AfficherErreurSaisie(const AMessage : string);

          /// <summary>Nœud actuellement affiché, ou nil si AfficherNoeud n'a pas encore été appelée.</summary>
          property NoeudCourant : TNoeudEtape read FNoeudCourant;

        published
          LabelTitre : TLabel;
          LabelTexte : TLabel;
          PanelInstruction : TPanel;
          BoutonContinuer : TButton;
          PanelChoix : TPanel;
          PanelSaisie : TPanel;
          EditSaisie : TEdit;
          BoutonValiderSaisie : TButton;
          LabelErreurSaisie : TLabel;
          ComboSaisie : TComboBox;

          procedure GererClicBoutonChoix(ASender : TObject);
          procedure GererClicContinuer(Sender : TObject);
          procedure GererClicValiderSaisie(Sender : TObject);
          /// <summary>
          /// Bascule le champ de saisie affiché entre texte libre (par défaut) et liste déroulante.
          /// </summary>
          /// <param name="AOptions">Options à proposer. Tableau vide pour revenir à la saisie libre.</param>
          procedure DefinirOptionsSaisie(const AOptions: TArray<string>);

          /// <summary>Déclenché quand l'utilisateur valide l'étape affichée (voir TAhEtapeValideeEvent).</summary>
          property OnEtapeValidee : TAhEtapeValideeEvent read FOnEtapeValidee write FOnEtapeValidee;
      end;

  implementation

    {$R *.dfm}

    { TFrameEtape }

    constructor TFrameEtape.Create(AOwner : TComponent);
      begin
        inherited Create(AOwner);

        FValeursBranches := TList<Variant>.Create;
      end;

    destructor TFrameEtape.Destroy;
      begin
        FValeursBranches.Free;

        inherited;
      end;

    procedure TFrameEtape.ViderBoutonsChoix;
      begin
        while PanelChoix.ControlCount > 0 do
          PanelChoix.Controls[0].Free;
        FValeursBranches.Clear;
      end;

    procedure TFrameEtape.ConstruireBoutonsChoix(ANoeud : TNoeudEtape);
      var
        Branche : TBrancheEtape;
        Bouton : TButton;
        Decalage : Integer;
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
      var
        DecalageVertical : Integer;
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
        LabelTitre.Visible := (ANoeud.Titre <> EmptyStr);
        LabelTexte.Caption := ANoeud.Texte;

        if LabelTitre.Visible then
          LabelTexte.Top := LabelTitre.Top + LabelTitre.Height + 8
        else
          LabelTexte.Top := 0;

        DecalageVertical := LabelTexte.Top + LabelTexte.Height + 12;
        PanelInstruction.Top := DecalageVertical;
        PanelChoix.Top := DecalageVertical;
        PanelSaisie.Top := DecalageVertical;

        PanelInstruction.Visible := (ANoeud.TypeNoeud = ntInstruction);
        PanelChoix.Visible := (ANoeud.TypeNoeud = ntChoix);
        PanelSaisie.Visible := (ANoeud.TypeNoeud = ntSaisie);

        case ANoeud.TypeNoeud of
          ntChoix :
            ConstruireBoutonsChoix(ANoeud);
          ntSaisie :
            begin
              EditSaisie.Text := EmptyStr;
              ComboSaisie.ItemIndex := -1;
              LabelErreurSaisie.Caption := EmptyStr;
              if EditSaisie.Visible then
                EditSaisie.SetFocus;
            end;
        end;
      end;

    procedure TFrameEtape.AfficherErreurSaisie(const AMessage : string);
      begin
        if not Assigned(FNoeudCourant) or (FNoeudCourant.TypeNoeud <> ntSaisie) then
          raise EInvalidOpException.Create(
            'AfficherErreurSaisie ne peut être appelée que lorsqu''un nœud ntSaisie est affiché.');

        LabelErreurSaisie.Caption := AMessage;
      end;

    procedure TFrameEtape.GererClicContinuer(Sender : TObject);
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

    procedure TFrameEtape.GererClicValiderSaisie(Sender : TObject);
      var
        Texte : string;
      begin
        if ComboSaisie.Visible then
          Texte := ComboSaisie.Text
        else
          Texte := Trim(EditSaisie.Text);

        if Texte = EmptyStr then
          begin
            LabelErreurSaisie.Caption := 'Choisissez ou saisissez une valeur avant de valider.';
            Exit;
          end;

        LabelErreurSaisie.Caption := EmptyStr;
        if Assigned(FOnEtapeValidee) then
          FOnEtapeValidee(Self, Texte);
      end;

    procedure TFrameEtape.DefinirOptionsSaisie(const AOptions : TArray<string>);
      var
        Option : string;
      begin
        ComboSaisie.Items.Clear;
        for Option in AOptions do
          ComboSaisie.Items.Add(Option);

        ComboSaisie.Visible := Length(AOptions) > 0;
        EditSaisie.Visible := Length(AOptions) = 0;

        if ComboSaisie.Visible
           and (ComboSaisie.Items.Count > 0)
        then
          ComboSaisie.ItemIndex := 0;
      end;

end.
