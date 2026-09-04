program ArkhamHorrorGuide;

uses
  FastMM5,
  Vcl.Forms,
  System.SysUtils,
  System.IOUtils,
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
  AH.Core.GrandsAnciens in '..\Core\AH.Core.GrandsAnciens.pas',
  AH.UI.Images in 'AH.UI.Images.pas',
  AH.UI.FrmAide in 'AH.UI.FrmAide.pas' {FrmAide};

{$R *.res}

  var
    GFastMMLogFileName : string;
    GFastMMStateFileName : string;


  /// <summary>
  /// Retourne le répertoire contenant l'exécutable.
  /// Ce répertoire existe avant l'exécution et sert de destination stable pour
  /// les diagnostics FastMM5.
  /// </summary>
  /// <returns>Chemin absolu du répertoire de l'exécutable, sans séparateur final.</returns>
  /// <exception cref="System.SysUtils.EInvalidOp">
  /// Levée si le chemin de l'exécutable ne permet pas de déterminer un répertoire de diagnostic exploitable.
  /// </exception>
  function GetFastMMDiagnosticsDirectory: string;
    begin
      Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

      if Result = EmptyStr then
        raise EInvalidOpException.Create(
          'Impossible de déterminer le répertoire de diagnostic FastMM5.');
    end;

  /// <summary>
  /// Configure temporairement FastMM5 pour produire des rapports de diagnostic
  /// dans le même répertoire que l'exécutable.
  /// Cette configuration est réservée aux investigations et ne doit pas être
  /// activée dans les builds de livraison.
  /// </summary>
  procedure ConfigureFastMMDiagnostics;
    var
      DiagnosticsDirectory : string;
    begin
      DiagnosticsDirectory := GetFastMMDiagnosticsDirectory;

      GFastMMLogFileName := TPath.Combine(
        DiagnosticsDirectory,
        'ArkhamHorrorGuide.FastMM.Events.log');

      GFastMMStateFileName := TPath.Combine(
        DiagnosticsDirectory,
        'ArkhamHorrorGuide.FastMM.State.log');

      // Les chaînes sont globales afin que les pointeurs transmis à FastMM restent
      // valides pendant toute l'exécution du processus.
      FastMM_SetEventLogFilename(PWideChar(GFastMMLogFileName));
      FastMM_DeleteEventLogFile;

      FastMM_LogToFileEvents := FastMM_LogToFileEvents +
        [mmetUnexpectedMemoryLeakDetail, mmetUnexpectedMemoryLeakSummary];

      FastMM_OutputDebugStringEvents := FastMM_OutputDebugStringEvents +
        [mmetUnexpectedMemoryLeakDetail, mmetUnexpectedMemoryLeakSummary];

      FastMM_EnterDebugMode;
      FastMM_SetDebugModeStackTraceEntryCount(32);
    end;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  ConfigureFastMMDiagnostics;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.CreateForm(TFrmNouvellePartie, FrmNouvellePartie);
  Application.CreateForm(TFrmAide, FrmAide);
  FrmPrincipal.Show;
  Application.ProcessMessages; // Laisse Windows finir d'enregistrer la fenêtre avant d'ouvrir une modale.
  FrmPrincipal.DemarrerNouvellePartie;
  Application.Run;
  {$IFDEF DEBUG}
  FastMM_LogStateToFile(PWideChar(GFastMMStateFileName));
  {$ENDIF}
end.