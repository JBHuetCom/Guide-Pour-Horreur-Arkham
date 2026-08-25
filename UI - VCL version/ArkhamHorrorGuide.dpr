program ArkhamHorrorGuide;

  uses
  FastMM5,
  Vcl.Forms,
  AH.UI.FrmPrincipal in 'AH.UI.FrmPrincipal.pas' {Form1},
  AH.UI.FrmNouvellePartie in 'AH.UI.FrmNouvellePartie.pas' {Form2},
  AH.UI.FrameEtape in 'AH.UI.FrameEtape.pas' {Frame1: TFrame},
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
  AH.Core.ConstructeurPartie in '..\Core\AH.Core.ConstructeurPartie.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
//  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
