program ArkhamHorrorGuideTests;

  {$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
  {$ENDIF}

  {$STRONGLINKTYPES ON}
  uses
  FastMM5,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  {$IFDEF DEBUG}
  DUnitX.MemoryLeakMonitor.FastMM5,
  {$ENDIF }
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.IOUtils,
  superobject,
  AH.Core.Types,
  AH.Core.Noeud,
  AH.Core.Moteur,
  AH.Core.Capacites,
  AH.Core.Conseils,
  AH.Core.Contexte,
  AH.Core.GrandsAnciens,
  AH.Tests.Moteur in 'AH.Tests.Moteur.pas',
  AH.Tests.EvaluateurCondition in 'AH.Tests.EvaluateurCondition.pas',
  AH.Tests.ChargeurContenu in 'AH.Tests.ChargeurContenu.pas',
  AH.Tests.Contexte in 'AH.Tests.Contexte.pas',
  AH.Tests.Conseils in 'AH.Tests.Conseils.pas',
  AH.Tests.Capacites in 'AH.Tests.Capacites.pas',
  AH.Tests.Parametres in 'AH.Tests.Parametres.pas',
  AH.Tests.Session in 'AH.Tests.Session.pas',
  AH.Tests.ConstructeurPartie in 'AH.Tests.ConstructeurPartie.pas',
  AH.Tests.GrandsAnciens in 'AH.Tests.GrandsAnciens.pas',
  AH.Tests.Noeud in 'AH.Tests.Noeud.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
  {$IFNDEF TESTINSIGHT}
  var
    runner : ITestRunner;
    results : IRunResults;
    logger : ITestLogger;
    nunitLogger : ITestLogger;
    GFastMMLogFileName : string;
    GFastMMStateFileName : string;
  {$ENDIF}

procedure AmorcerLesSpecialisationsGeneriques;
{ Certaines spécialisations génériques (TDictionary<...>, TObjectList<...>, TList<...>, etc.)
  allouent, à leur toute première utilisation dans le process, un comparateur par défaut mis
  en cache pour la durée de vie de l'application (System.Generics.Defaults). Allocation
  normale et volontaire côté RTL, jamais libérée avant la fin du process — FastMM5/DUnitX la
  signale néanmoins comme fuite et l'attribue au premier test qui la déclenche. On amorce donc
  ici, avant l'exécution des tests, chaque spécialisation utilisée dans le projet — y compris
  via les classes gestionnaires (instanciées puis libérées pour amorcer leurs dictionnaires
  internes), et explicitement pour les types qu'un simple Create/Free de ces classes ne
  suffit pas à déclencher (les dictionnaires internes créés seulement lors du chargement
  effectif d'un fichier). À mettre à jour si une nouvelle unité introduit une nouvelle
  spécialisation générique. Ne compense JAMAIS une vraie fuite par appel (voir
  AH.Core.GrandsAnciens.TSuperAvlIterator, corrigé séparément par un ObjectFindClose manquant
  — un objet réellement recréé à chaque appel ne doit jamais être "amorti" ici). }
  var
    NoeudSequence, NoeudCondition : TNoeudEtape;
    Pile : TList<TFrameParcours>;
    Historique : TStack<TInstantane>;
    ListeInvestigateurs : TList<TInvestigateurJoue>;
    MappingEntiers : TDictionary<Integer, Integer>;
    Capacites : TGestionnaireCapacites;
    Conseils : TGestionnaireConseils;
    ListeConseils : TList<TConseil>;
    GrandsAnciens : TGestionnaireGrandsAnciens;
    ReglesEtapes : TDictionary<string, string>;
    RttiContext : TSuperRttiContext;
  begin
    NoeudSequence := TNoeudEtape.Create('amorce_sequence', ntSequence);
    NoeudSequence.Free;
    NoeudCondition := TNoeudEtape.Create('amorce_condition', ntCondition);
    NoeudCondition.Free;

    Pile := TList<TFrameParcours>.Create;
    Pile.Free;

    Historique := TStack<TInstantane>.Create;
    Historique.Free;

    ListeInvestigateurs := TList<TInvestigateurJoue>.Create;
    ListeInvestigateurs.Free;

    MappingEntiers := TDictionary<Integer, Integer>.Create;
    MappingEntiers.Free;

    Capacites := TGestionnaireCapacites.Create;
    Capacites.Free;

    Conseils := TGestionnaireConseils.Create;
    Conseils.Free;

    ListeConseils := TList<TConseil>.Create;
    ListeConseils.Free;

    GrandsAnciens := TGestionnaireGrandsAnciens.Create;
    GrandsAnciens.Free;

    ReglesEtapes := TDictionary<string, string>.Create;
    ReglesEtapes.Free;

    RttiContext := TSuperRttiContext.Create;
    RttiContext.Free;
  end;
  
	/// <summary>
	/// Retourne le répertoire contenant l'exécutable de tests.
	/// Ce répertoire existe avant l'exécution et sert de destination stable pour
	/// les diagnostics FastMM5.
	/// </summary>
	/// <returns>Chemin absolu du répertoire de l'exécutable de tests, sans séparateur final.</returns>
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
	/// dans le même répertoire que l'exécutable de tests.
	/// Cette configuration est réservée aux investigations et ne doit pas être
	/// activée dans les builds de livraison.
	/// </summary>
	procedure ConfigureFastMMDiagnostics;
		var
		  DiagnosticsDirectory: string;
		begin
		  DiagnosticsDirectory := GetFastMMDiagnosticsDirectory;

		  GFastMMLogFileName := TPath.Combine(
			DiagnosticsDirectory,
			'ArkhamHorrorGuideTests.FastMM.Events.log');

		  GFastMMStateFileName := TPath.Combine(
			DiagnosticsDirectory,
			'ArkhamHorrorGuideTests.FastMM.State.log');

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

		  System.Writeln('FastMM working directory: ' + GetCurrentDir);
		  System.Writeln('FastMM event log: ' + GFastMMLogFileName);
		  System.Writeln('FastMM state log: ' + GFastMMStateFileName);
		end;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  {$IFDEF TESTINSIGHT}
  {$IFDEF DEBUG}
  ConfigureFastMMDiagnostics;
  {$ENDIF}
  TestInsight.DUnitX.RunRegisteredTests;
 {$ELSE}
  try
    {$IFDEF DEBUG}
    ConfigureFastMMDiagnostics;
    AmorcerLesSpecialisationsGeneriques;
    {$ENDIF}

    //Pause par défaut en sortie ; CheckCommandLine peut écraser cette valeur si un
    //argument de ligne de commande explicite est fourni (utile en CI).
    TDUnitX.Options.ExitBehavior := TDUnitXExitBehavior.Pause;
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
      begin
        logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
        runner.AddLogger(logger);
      end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;

    if not FastMM_LogStateToFile(PWideChar(GFastMMStateFileName)) then
      System.Writeln('FastMM n''a pas pu écrire le rapport d''état : ' + GFastMMStateFileName)
    else
      if not TFile.Exists(GFastMMStateFileName) then
        System.Writeln('FastMM a retourné True, mais le fichier est introuvable : ' + GFastMMStateFileName)
      else
        System.Writeln('Rapport d''état FastMM créé : ' + GFastMMStateFileName);

    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
      begin
        System.Write('Done.. press <Enter> key to quit.');
        System.Readln;
      end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ' : ', E.Message);
  end;
 {$ENDIF}

end.
