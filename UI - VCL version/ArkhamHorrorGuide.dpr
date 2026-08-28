program ArkhamHorrorGuide;

uses
  FastMM5,
  Vcl.Forms,
  AH.UI.FrmPrincipal in 'AH.UI.FrmPrincipal.pas' {FrmPrincipal},
  AH.UI.FrmNouvellePartie in 'AH.UI.FrmNouvellePartie.pas' {FrmNouvellePartie},
  AH.UI.FrameEtape in 'AH.UI.FrameEtape.pas' {FrameEtape: TFrame},
  AH.Core.Types in '..\Core\AH.Core.Types.pas',
  AH.Core.Contexte in '..\Core\AH.Core.Contexte.pas',
  AH.Core.Noeud in '..\Core\AH.Core.Noeud.pas',
  AH.Core.Moteur in '..\Core\AH.Core.Moteur.pas',
  AH.Core.EvaluateurCondition in '..\Core\AH.Core.EvaluateurCondition.pas',
  AH.Core.ChargeurContenu in '..\Core\AH.Core.ChargeurContenu.pas',
  AH.Core.Session in '..\Core\AH.Core.Session.pas',
  AH.Core.Conseils in '..\Core\AH.Core.Conseils.pas',
  AH.Core.Capacites in '..\Core\AH.Core.Capacites.pas',
  AH.Core.Parametres in '..\Core\AH.Core.Parametres.pas',
  AH.Core.ConstructeurPartie in '..\Core\AH.Core.ConstructeurPartie.pas',
  AH.Core.GrandsAnciens in '..\Core\AH.Core.GrandsAnciens.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.CreateForm(TFrmNouvellePartie, FrmNouvellePartie);
  FrmPrincipal.Show;
  Application.ProcessMessages; // Laisse Windows finir d'enregistrer la fenêtre avant d'ouvrir une modale.
  FrmPrincipal.DemarrerNouvellePartie;
  Application.Run;
end.